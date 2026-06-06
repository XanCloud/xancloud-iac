# Procedimiento de despliegue

Guía paso a paso para bootstrap y deploy de la landing zone.

## Prerequisitos

- OpenTofu >= 1.11.0 instalado (`tofu --version`)
- AWS CLI configurado con credenciales válidas (`aws sts get-caller-identity`)
- Permisos mínimos del caller IAM:
  - `s3:*` (para state bucket)
  - `kms:*` (para KMS keys)
  - `ec2:*` (VPC, subnets, NAT, endpoints, flow logs, metadata defaults)
  - `cloudtrail:*`
  - `iam:*` (password policy, Access Analyzer, account alias, roles)
  - `logs:*` (CloudWatch Log Groups)
  - `sts:GetCallerIdentity`

> En producción, reemplazar wildcards por permisos granulares. Para MVP, un usuario/role con `AdministratorAccess` funciona.

> **Nota sobre el lock file:** `.terraform.lock.hcl` está trackeado en git para garantizar builds reproducibles. No modificarlo manualmente.

---

## Paso 1: Bootstrap del State Backend

El state-backend se aplica primero con state local. Después se migra a S3.

```bash
cd modules/state-backend

# Crear terraform.tfvars (NO commitear este archivo)
cat > terraform.tfvars <<'EOF'
project     = "xancloud"
environment = "dev"
bucket_name = "xancloud-dev-tfstate"
# allowed_roles = ["arn:aws:iam::123456789012:role/ci-deploy"]
EOF

# Init con state local (no hay backend remoto aún)
tofu init

# Revisar el plan
tofu plan

# Aplicar
tofu apply

# Guardar los outputs — los necesitas para el siguiente paso
tofu output -json > /tmp/state-backend-outputs.json
```

**¿Por qué no hay un tfvars de ejemplo en `environments/` para state-backend?** Porque el state-backend se despliega con state local y luego se migra a remoto. Es un paso de bootstrap manual. Las variables son pocas y se pasan inline o en un `terraform.tfvars` temporal (ignorado por git).

**Outputs clave:**
- `bucket_id` → nombre del bucket S3
- `kms_key_arn` → ARN de la key KMS
- `backend_config` → mapa listo para `-backend-config`

### Migrar state local a S3

```bash
# Crear backend config con los valores reales del output
cat > backend.hcl <<EOF
bucket       = "$(tofu output -raw bucket_id)"
region       = "us-east-1"
encrypt      = true
kms_key_id   = "$(tofu output -raw kms_key_arn)"
key          = "state-backend/terraform.tfstate"
use_lockfile = true
EOF

# Agregar backend block al versions.tf (temporalmente)
# O usar -backend-config en init
tofu init -backend-config=backend.hcl -migrate-state
```

Confirmar con `yes` cuando pregunte si deseas migrar el state.

> **Punto de no retorno:** después de la migración, el state local se puede eliminar. El state vive en S3.

---

## Paso 2: Deploy de la Landing Zone (dev)

```bash
cd blueprints/landing-zone-basic

# Crear backend config para dev
cat > backend-dev.hcl <<'EOF'
bucket       = "xancloud-dev-tfstate"
region       = "us-east-1"
encrypt      = true
kms_key_id   = "arn:aws:kms:us-east-1:123456789012:key/xxxx-xxxx"
key          = "landing-zone-basic/dev/terraform.tfstate"
use_lockfile = true
EOF

# Init con backend remoto (usa el lock file del repo para providers)
tofu init -backend-config=backend-dev.hcl

# Plan con tfvars de dev (usa el example de environments/)
tofu plan -var-file=../../environments/dev/terraform.tfvars.example

# Aplicar (copiar el example a terraform.tfvars y editarlo primero)
cp ../../environments/dev/terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores
tofu apply
```
> Si prefieres mantener los tfvars por entorno organizados en `environments/`, puedes crear `environments/dev/terraform.tfvars` (ignorado por git) basado en el `.example` y referenciarlo con `-var-file`.

### Deploy de prod (mismo bucket, diferente key)

```bash
# Crear backend config para prod (diferente state key)
cat > backend-prod.hcl <<EOF
bucket       = "xancloud-dev-tfstate"
region       = "us-east-1"
encrypt      = true
kms_key_id   = "arn:aws:kms:us-east-1:123456789012:key/xxxx-xxxx"
key          = "landing-zone-basic/prod/terraform.tfstate"
use_lockfile = true
EOF

# Init con backend de prod (si ya tienes dev, necesitas reinit)
tofu init -backend-config=backend-prod.hcl -reconfigure

# Plan y apply
tofu plan -var-file=examples/prod.tfvars
tofu apply -var-file=examples/prod.tfvars
```

---

## Paso 3: Verificación post-deploy

```bash
# Verificar VPC creada
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=xancloud" \
  --query 'Vpcs[].{ID:VpcId,CIDR:CidrBlock,Name:Tags[?Key==`Name`].Value|[0]}'

# Verificar CloudTrail activo
aws cloudtrail describe-trails --query 'trailList[].{Name:Name,IsMultiRegion:IsMultiRegionTrail,Logging:HasCustomEventSelectors}'
aws cloudtrail get-trail-status --name xancloud-dev-cloudtrail

# Verificar IAM baseline (solo si is_account_owner=true)
aws iam get-account-password-policy
aws s3control get-public-access-block --account-id $(aws sts get-caller-identity --query Account --output text)
aws accessanalyzer list-analyzers --query 'analyzers[].{Name:name,Type:type,Status:status}'

# Verificar IMDSv2 default
aws ec2 get-instance-metadata-defaults --query 'accountLevel'
```

---

## Destroy (orden inverso)

> Destruir en orden inverso al deploy. Blueprint primero, state-backend al final.

```bash
# 1. Destroy landing zone (prod primero si existe)
cd blueprints/landing-zone-basic
tofu init -backend-config=backend-prod.hcl -reconfigure
tofu destroy -var-file=examples/prod.tfvars

# 2. Destroy landing zone (dev)
tofu init -backend-config=backend-dev.hcl -reconfigure
tofu destroy -var-file=examples/dev.tfvars

# 3. Destroy state backend (migrar state de vuelta a local primero)
cd modules/state-backend
# Quitar backend config y reinit con local
tofu init -migrate-state   # elegir local cuando pregunte
tofu destroy
```

> **CloudTrail S3 bucket:** si tiene objetos (logs), `tofu destroy` fallará porque `force_destroy = false`. Vaciar el bucket manualmente primero:
> ```bash
> aws s3 rm s3://xancloud-dev-cloudtrail-{account-id} --recursive
> ```

---

## Recuperación de errores comunes

| Error | Causa | Solución |
|-------|-------|----------|
| `Error acquiring state lock` | Otro `tofu apply` corriendo, o proceso anterior crasheó | Verificar que no hay otro proceso. Si el lock file quedó huérfano: `tofu force-unlock <lock-id>` |
| `AccessDenied` en S3 | Bucket policy restringe acceso | Verificar que el caller está en `allowed_roles` o es account root |
| `KMS key not found` | Key eliminada o ARN incorrecto en backend config | Verificar ARN con `aws kms describe-key --key-id <arn>` |
| `CloudTrail bucket policy deny` | Bucket policy no permite `cloudtrail.amazonaws.com` | El módulo lo crea automáticamente. Si usas BYOB, agregar el statement manualmente |
| `NAT Gateway: insufficient EIPs` | Límite de EIPs alcanzado | Solicitar aumento de límite en Service Quotas: `vpc/elastic-ips-per-region` |
| `VPC endpoint not available` | El servicio no está disponible en la región | Verificar con `aws ec2 describe-vpc-endpoint-services --region <region>` |
