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

> **Nota sobre la región:** La región del deploy depende del perfil AWS configurado, no de la variable `region` en tfvars. Por ejemplo, si tu perfil apunta a `us-west-2`, todos los recursos se crearán en `us-west-2`. La variable `region` en los tfvars se usa internamente en el bloque `provider "aws"` y DEBE coincidir con la región del perfil. Si no coincide, tofu fallará o creará recursos en una región diferente a la esperada.

---

## Paso 1: Bootstrap del State Backend

El state-backend se aplica primero con state local. Después se migra a S3.

```bash
cd modules/state-backend

# Determinar el ARN del caller actual (OBLIGATORIO para allowed_roles)
CALLER_ARN=$(aws sts get-caller-identity --query Arn --output text)
echo "Caller ARN: ${CALLER_ARN}"

# Crear terraform.tfvars (NO commitear este archivo)
# ⚠️  CRÍTICO: allowed_roles debe incluir el ARN del caller.
#    Sin esto, la bucket policy bloqueará al IAM user/role inmediatamente
#    después del apply y solo el root de la cuenta podrá recuperarlo.
cat > terraform.tfvars <<EOF
project       = "xancloud"
environment   = "dev"
bucket_name   = "xancloud-dev-tfstate"
allowed_roles = ["${CALLER_ARN}"]
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

> ⚠️ **Requerido:** El módulo `state-backend` no tiene un bloque `backend "s3" {}`. Para migrar el state a S3, debes agregarlo temporalmente, migrar, y luego removerlo. El bloque `backend "s3" {}` sin argumentos delega la configuración al archivo `-backend-config`.

```bash
# Crear backend config con los valores reales del output
cat > backend.hcl <<EOF
bucket       = "$(tofu output -raw bucket_id)"
region       = "$(tofu output -raw backend_config | jq -r '.region')"
encrypt      = true
kms_key_id   = "$(tofu output -raw kms_key_arn)"
key          = "state-backend/terraform.tfstate"
use_lockfile = true
EOF

# 1. Agregar bloque backend a versions.tf temporalmente
#    (se removerá después de la migración)
cat >> versions.tf <<'TEOF'

backend "s3" {}
TEOF

# 2. Migrar state de local a S3
tofu init -backend-config=backend.hcl -migrate-state

# 3. Remover el bloque backend temporal
#    El state ahora vive en S3 y tofu lo recuerda
head -n -3 versions.tf > versions.tf.tmp && mv versions.tf.tmp versions.tf

# 4. Cleanup
rm -f backend.hcl
```

Confirmar con `yes` cuando pregunte si deseas migrar el estado.

> **Nota:** tofu recuerda la configuración del backend S3 en `.terraform/`. Mientras exista ese directorio, los comandos `plan/apply/destroy` apuntan a S3. Si eliminas `.terraform/`, tendrás que volver a hacer `tofu init` con `-backend-config=backend.hcl`.

> **Punto de no retorno:** después de la migración, el state local se puede eliminar. El state vive en S3.

---

## Paso 2: Deploy de la Landing Zone (dev)

```bash
cd blueprints/landing-zone-basic

# Crear backend config para dev usando los outputs del state-backend
# (usa los valores reales guardados en /tmp/)
cat > backend-dev.hcl <<EOF
bucket       = "$(cat /tmp/state-backend-outputs.json | jq -r '.bucket_id.value')"
region       = "$(cat /tmp/state-backend-outputs.json | jq -r '.backend_config.value.region')"
encrypt      = true
kms_key_id   = "$(cat /tmp/state-backend-outputs.json | jq -r '.kms_key_arn.value')"
key          = "landing-zone-basic/dev/terraform.tfstate"
use_lockfile = true
EOF

# Init con backend remoto
tofu init -backend-config=backend-dev.hcl
# Si ya existe un .terraform/ con otro backend, usa -reconfigure
# tofu init -backend-config=backend-dev.hcl -reconfigure

# Crear terraform.tfvars para dev basado en el ejemplo
# La región debe coincidir con la del state backend
cp ../../environments/dev/terraform.tfvars.example terraform.tfvars
# Editar la región en terraform.tfvars si es necesario
# Luego:
tofu plan
tofu apply
```

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

### 1. Destroy landing zone

```bash
cd blueprints/landing-zone-basic

# (Si hay prod, destruirlo primero)
# tofu init -backend-config=backend-prod.hcl -reconfigure
# tofu destroy

# Destroy dev
tofu init -backend-config=backend-dev.hcl -reconfigure
tofu destroy
```

### 2. Limpiar bucket de CloudTrail

El bucket de CloudTrail tiene **Object Lock** habilitado y `force_destroy = false`. Si el destroy falla con `BucketNotEmpty`, hay que vaciarlo manualmente:

```bash
# Obtener el nombre del bucket desde los outputs del estado
# o desde la consola AWS
BUCKET="xancloud-dev-cloudtrail-$(aws sts get-caller-identity --query Account --output text)"

# 2a. Eliminar objetos actuales
aws s3 rm "s3://${BUCKET}" --recursive

# 2b. Eliminar versiones antiguas y delete markers
#     (el versioning + Object Lock retiene versiones previas)
aws s3api list-object-versions --bucket "${BUCKET}" --query 'Versions[].{Key:Key,VersionId:VersionId}' --output json > /tmp/versions.json
aws s3api list-object-versions --bucket "${BUCKET}" --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output json > /tmp/delete-markers.json

python3 -c "
import json, subprocess
for f in ['/tmp/versions.json', '/tmp/delete-markers.json']:
    with open(f) as fh:
        objects = json.load(fh)
    if not objects:
        continue
    print(f'Deleting {len(objects)} objects from {f}...')
    for i in range(0, len(objects), 1000):
        batch = objects[i:i+1000]
        subprocess.run([
            'aws', 's3api', 'delete-objects',
            '--bucket', '$BUCKET',
            '--delete', json.dumps({'Objects': batch, 'Quiet': True}),
            '--bypass-governance-retention'    # necesario por Object Lock
        ], check=True)
print('Done')
"

# 2c. Reintentar destroy
tofu init -backend-config=backend-dev.hcl -reconfigure
tofu destroy
```

> **Por qué `--bypass-governance-retention`:** El módulo CloudTrail crea el bucket con Object Lock en modo GOVERNANCE y 364 días de retención. El IAM user con permisos de administración puede bypassearlo explícitamente con este flag.

### 3. Destroy state backend

El bucket state contiene los archivos de state versionados (de la migración). Hay que limpiarlos antes de destruir:

```bash
cd modules/state-backend

# 3a. Remover el bloque backend "s3" {} si existe en versions.tf
#     (solo si lo agregaste durante el bootstrap)

# 3b. Migrar state de vuelta a local
tofu init -migrate-state
# Responder "yes" cuando pregunte si copiar el state a local

# 3c. Listar objetos versionados en el bucket state
BUCKET="$(tofu output -raw bucket_id 2>/dev/null || echo 'xancloud-dev-tfstate-{account}')"
aws s3api list-object-versions --bucket "${BUCKET}" --query 'Versions[].{Key:Key,VersionId:VersionId}' --output json > /tmp/state-versions.json

# 3d. Eliminar versiones del bucket (los state files migrados)
python3 -c "
import json, subprocess
with open('/tmp/state-versions.json') as f:
    objects = json.load(f)
if objects:
    print(f'Deleting {len(objects)} versioned state objects...')
    subprocess.run([
        'aws', 's3api', 'delete-objects',
        '--bucket', '$BUCKET',
        '--delete', json.dumps({'Objects': objects, 'Quiet': True})
    ], check=True)
    print('Done')
else:
    print('No versioned objects')
"

# 3e. Destruir state-backend
tofu destroy

# 3f. Limpiar archivos temporales
rm -f /tmp/state-backend-outputs.json /tmp/state-versions.json
```

### Resumen del orden de destroy

```
1. tofu destroy blueprint (dev → prod)
2. Vaciar bucket CloudTrail (objetos + versiones con --bypass-governance-retention)
3. tofu destroy blueprint (reintentar)
4. tofu init -migrate-state (state-backend → local)
5. Vaciar bucket state (versiones de state files)
6. tofu destroy state-backend
```

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
