# Fase 1 — Especificación de Módulos

## state-backend

Bootstrap manual (se aplica primero, antes de que exista remote state).

**Recursos:**
- S3 bucket: versionamiento habilitado, SSE-KMS con clave dedicada
- KMS key: para encriptación del state
- Bucket policy: restrictiva (solo CI/CD roles + admins)
- Replicación cross-region: configurable, deshabilitada por defecto en dev
- OpenTofu encryption block (double encryption)

**Variables clave:**
- `bucket_name` (string, required)
- `kms_key_alias` (string, default: "alias/{project}-{env}-state")
- `enable_replication` (bool, default: false)
- `replication_region` (string, default: null)
- `allowed_account_ids` (list(string))
- `allowed_roles` (list(string)) — ARNs de roles que pueden acceder al state

**Notas:**
- State locking nativo S3 con `use_lockfile = true`. NO DynamoDB.
- Este módulo se aplica con local state primero, luego se migra.
- No usar `prevent_destroy` lifecycle — dificulta cleanup en dev.

---

## networking/vpc

Instanciable N veces con `for_each` sobre un map de VPCs.

**Parámetros del map por VPC:**

| Parámetro | Type | Descripción |
|---|---|---|
| cidr | string | Bloque CIDR (ej: 10.0.0.0/16) |
| azs | number | Número de AZs (2 dev/staging, 3 prod) |
| single_nat | bool | true = 1 NAT GW. false = 1 por AZ |
| vpc_endpoints | list(string) | Endpoints (ej: ["s3", "ssm", "ecr.api"]) |
| flow_logs_destination | string | "cloudwatch" | "s3" | "both" |

**Subnets por AZ:**
- Public (para NAT GW, ALB)
- Private (workloads)
- Isolated/DB (sin internet, para RDS/ElastiCache)

**Ejemplo tfvars:**
```hcl
vpcs = {
  main = {
    cidr            = "10.2.0.0/16"
    azs             = 3
    single_nat      = false
    vpc_endpoints   = ["s3", "ssm", "ecr.api", "logs"]
    flow_logs_destination = "cloudwatch"
  }
}
```

**Decision tree — ¿Más de 1 VPC por entorno?**
- ✅ Compliance/regulatorio (PCI-DSS, HIPAA scope separation)
- ✅ Blast radius (líneas de negocio con tolerancia a fallo distinta)
- ✅ Ownership distinto (evaluar si multi-account no es mejor)
- ❌ "Este proyecto es diferente" → subnets + security groups
- ❌ "Separar frontend de backend" → subnets + NACLs
- ❌ "Una VPC por microservicio" → problema de app, no de networking

---

## identity/sso

IAM Identity Center configuration.

**Permission sets:**
- AdministratorAccess
- PowerUserAccess
- ReadOnlyAccess
- BillingAccess

**Grupos:**
- platform-admins
- developers
- readonly
- billing

**Password policy:**
- 14 chars mínimo
- Rotación cada 90 días
- No reutilización últimas 24 passwords

---

## identity/iam-baseline

Account-level security settings.

**Recursos:**
- IMDSv2 enforced en todas las instancias (account-level default)
- S3 Block Public Access a nivel de cuenta
- EBS default encryption habilitado

---

## security/cloudtrail

**Excepción: enabled = true por defecto** (bajo costo, esencial para auditoría).

- Multi-region trail
- Management events + data events (S3, Lambda)
- Log file validation habilitado
- S3 bucket dedicado con lifecycle policy
- KMS encryption
- CloudWatch Logs integration opcional

---

## security/config-rules

`enabled = false` por defecto.

Managed rules cuando enabled:
- encrypted-volumes
- s3-bucket-public-read-prohibited
- iam-root-access-key-check
- vpc-flow-logs-enabled

---

## security/guardduty

`enabled = false` por defecto.

Cuando enabled:
- S3 protection
- EKS protection (si aplica, configurable)

---

## security/securityhub

`enabled = false` por defecto.

Cuando enabled:
- AWS Foundational Security Best Practices
- CIS AWS Foundations Benchmark

---

## operations/monitoring

CloudWatch dashboards + alertas base por entorno.

---

## operations/cost-mgmt

AWS Budgets + Cost Anomaly Detection.
