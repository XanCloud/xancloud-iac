# Troubleshooting

Problemas conocidos, errores comunes y soluciones.

---

## State y locking

### `Error acquiring the state lock`

**Causa:** Otro `tofu apply` corriendo, o un proceso anterior falló sin liberar el lock.

**Solución:**
1. Verificar que no hay otro proceso corriendo
2. Si es un lock huérfano: `tofu force-unlock <LOCK_ID>`
3. El lock ID aparece en el mensaje de error

### `Failed to load backend: S3 bucket does not exist`

**Causa:** El state-backend no fue bootstrappeado, o el nombre del bucket en `backend-{env}.hcl` es incorrecto.

**Solución:**
1. Verificar que `modules/state-backend` fue aplicado
2. Verificar el bucket name: `aws s3 ls | grep tfstate`
3. Comparar con el valor en `backend-{env}.hcl`

### State corrupto

**Causa:** Apply interrumpido, edición manual del state, o conflicto de versiones.

**Solución:**
1. S3 versioning está habilitado — recuperar versión anterior:
   ```bash
   aws s3api list-object-versions --bucket xancloud-dev-tfstate \
     --prefix landing-zone-basic/dev/terraform.tfstate
   ```
2. Restaurar: descargar la versión correcta y hacer `tofu state push`
3. Último recurso: `tofu import` de recursos existentes

---

## CloudTrail

### `AccessDeniedException` al crear el trail

**Causa:** La bucket policy no permite a `cloudtrail.amazonaws.com` escribir.

**Solución:** El módulo crea la policy automáticamente. Si usas BYOB (bring your own bucket), verificar que la policy incluye:
```json
{
  "Effect": "Allow",
  "Principal": { "Service": "cloudtrail.amazonaws.com" },
  "Action": "s3:PutObject",
  "Resource": "arn:aws:s3:::BUCKET_NAME/AWSLogs/ACCOUNT_ID/*",
  "Condition": {
    "StringEquals": { "s3:x-amz-acl": "bucket-owner-full-control" }
  }
}
```

### `InsufficientEncryptionPolicyException`

**Causa:** La KMS key policy no permite a CloudTrail encriptar.

**Solución:** Verificar que la key policy permite:
- `kms:GenerateDataKey*` para el principal `cloudtrail.amazonaws.com`
- `kms:DescribeKey` para el principal `cloudtrail.amazonaws.com`

El módulo crea esto automáticamente si no usas BYOK.

### `Cannot delete S3 bucket: bucket is not empty`

**Causa:** `force_destroy = false` (intencional, protección contra borrado accidental). El bucket tiene objetos actuales, versiones antiguas, o delete markers.

**Solución para CloudTrail bucket (sin Object Lock):**
```bash
aws s3 rm s3://xancloud-dev-cloudtrail-{account_id} --recursive
```

**Solución para CloudTrail bucket (con Object Lock):**
El módulo CloudTrail habilita Object Lock en modo GOVERNANCE con 364 días de retención. `aws s3 rm` solo elimina la versión actual. Las versiones retenidas por Object Lock requieren `--bypass-governance-retention`:

```bash
BUCKET="xancloud-dev-cloudtrail-$(aws sts get-caller-identity --query Account --output text)"

# 1. Eliminar objetos actuales
aws s3 rm "s3://${BUCKET}" --recursive

# 2. Eliminar versiones (con bypass por Object Lock)
python3 -c "
import json, subprocess
bucket = '$BUCKET'
cmd = ['aws', 's3api', 'list-object-versions', '--bucket', bucket]
data = json.loads(subprocess.run(cmd, capture_output=True, text=True).stdout)
objects = []
for v in data.get('Versions', []):
    objects.append({'Key': v['Key'], 'VersionId': v['VersionId']})
for v in data.get('DeleteMarkers', []):
    objects.append({'Key': v['Key'], 'VersionId': v['VersionId']})

if objects:
    for i in range(0, len(objects), 1000):
        batch = objects[i:i+1000]
        subprocess.run([
            'aws', 's3api', 'delete-objects', '--bucket', bucket,
            '--delete', json.dumps({'Objects': batch, 'Quiet': True}),
            '--bypass-governance-retention'
        ], check=True)
    print(f'{len(objects)} objects deleted (with governance bypass)')
"

# 3. Reintentar destroy
tofu destroy
```

**Solución para state bucket (con versioning):**
El bucket state tiene versioning habilitado pero NO Object Lock. Los state files migrados dejan versiones que bloquean el destroy:

```bash
BUCKET="xancloud-dev-tfstate-${account_id}"

# Listar y eliminar todas las versiones
python3 -c "
import json, subprocess
bucket = '$BUCKET'
data = json.loads(subprocess.run(
    ['aws', 's3api', 'list-object-versions', '--bucket', bucket],
    capture_output=True, text=True).stdout)
objects = []
for v in data.get('Versions', []):
    objects.append({'Key': v['Key'], 'VersionId': v['VersionId']})
for v in data.get('DeleteMarkers', []):
    objects.append({'Key': v['Key'], 'VersionId': v['VersionId']})
if objects:
    for i in range(0, len(objects), 1000):
        batch = objects[i:i+1000]
        subprocess.run(['aws', 's3api', 'delete-objects', '--bucket', bucket,
            '--delete', json.dumps({'Objects': batch, 'Quiet': True})], check=True)
    print(f'{len(objects)} versioned objects deleted')
else:
    print('No versioned objects')
"

# Reintentar destroy
tofu destroy
```

---

## VPC y Networking

### `The maximum number of VPCs has been reached`

**Causa:** Límite default de 5 VPCs por región.

**Solución:** Solicitar aumento en Service Quotas → VPC → `VPCs per Region`

### `The maximum number of Elastic IPs has been reached`

**Causa:** Límite de 5 EIPs por región. Con 3 AZs y `single_nat = false`, cada VPC usa 3 EIPs.

**Solución:** Solicitar aumento en Service Quotas → EC2 → `EC2-VPC Elastic IPs`

### VPC endpoint no disponible en la región

**Causa:** No todos los servicios tienen VPC endpoints en todas las regiones.

**Solución:**
```bash
aws ec2 describe-vpc-endpoint-services --region <region> \
  --query 'ServiceNames' | grep <service>
```
Quitar el servicio del array `vpc_endpoints` si no está disponible.

### `InvalidParameterValue: CIDR block X conflicts with existing subnet`

**Causa:** CIDRs solapados entre VPCs o subnets.

**Solución:** Verificar que los CIDRs no se solapan:
- dev: `10.10.0.0/16`
- prod: `10.20.0.0/16`
- staging: `10.30.0.0/16`

Usar rangos RFC 1918 distintos por entorno.

---

## IAM Baseline

### Drift en password policy / S3 BPA / IMDSv2

**Causa:** Dos entornos con `is_account_owner = true` en la misma cuenta.

**Solución:** Solo UN entorno debe tener `is_account_owner = true`. Verificar:
```bash
grep -r "is_account_owner" environments/ blueprints/*/examples/
```
Convención: dev es el owner, prod tiene `is_account_owner = false`.

### `EntityAlreadyExists` en account alias

**Causa:** Otro entorno ya creó el alias, o el alias ya existe en otra cuenta AWS.

**Solución:** Los account alias son globalmente únicos en AWS. Elegir uno diferente o set `account_alias = null`.

### Access Analyzer solo ve recursos de una región

**Causa:** Access Analyzer es regional. El módulo lo crea solo en la región del provider.

**Solución:** Esto es una limitación conocida de Phase 1. Phase 2+ agregará fan-out multi-región.

---

## KMS

### `ScheduledForDeletion` — key no accesible

**Causa:** La key fue scheduled for deletion (default: 30 días de gracia).

**Solución:**
```bash
# Cancelar deletion si aún está en periodo de gracia
aws kms cancel-key-deletion --key-id <key-id>
aws kms enable-key --key-id <key-id>
```

### `AccessDeniedException` al usar la KMS key

**Causa:** El caller no está en la key policy.

**Solución:** Verificar que el rol/usuario está en `allowed_roles` del módulo state-backend, o que es el root de la cuenta.

---

## Bootstrap (state-backend)

### Lockout tras aplicar state-backend con IAM user

**Causa:** La bucket policy del state-backend contiene `DenyUnauthorizedAccess` que solo permite acceso al root de la cuenta y a los ARNs listados en `allowed_roles`. Si `allowed_roles` está vacío (default), cualquier IAM user/role queda bloqueado inmediatamente después de aplicar la policy. Las operaciones posteriores (SSE config, lifecycle config, etc.) fallan con `AccessDenied`.

**Solución preventiva (si aún no aplicaste):**
Siempre incluir el ARN del IAM user/role que ejecuta el deploy en `allowed_roles` del `terraform.tfvars` **antes del primer apply**:

```hcl
project       = "xancloud"
environment   = "dev"
bucket_name   = "xancloud-dev-tfstate-123456789012"
allowed_roles = ["arn:aws:iam::123456789012:user/IaC-Labs"]   # ← REQUERIDO
```

**Recuperación (si ya estás bloqueado):**
Solo el root de la cuenta puede desbloquear. Usar credenciales root (o un rol no bloqueado):

```bash
aws s3api delete-bucket-policy --bucket xancloud-dev-tfstate-291066412211 --profile root-profile
```

Luego agregar el ARN del caller a `allowed_roles` y re-aplicar.

**Lección:** `allowed_roles` no es opcional cuando se deploya desde un IAM user/role. Siempen incluirlo. Considerar hacerlo un `required` en futura revisión.

---

## OpenTofu general

### `Provider version constraint not satisfied`

**Causa:** Lockfile pinea una versión específica, pero el constraint cambió.

**Solución:**
```bash
tofu init -upgrade
```

### `Module source has changed`

**Causa:** El path relativo del source cambió (ej: se movió un módulo).

**Solución:**
```bash
tofu init -reconfigure
```

### Formateo inconsistente

```bash
# Verificar
tofu fmt -check -recursive

# Corregir automáticamente
tofu fmt -recursive
```
