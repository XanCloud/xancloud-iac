# Fase 1 — MVP Landing Zone (Capa 0)

> **Duración estimada:** 4-6 semanas | **Dependencia:** Ninguna | **Estado:** No iniciada

## Objetivo

Entregar una landing zone AWS funcional con networking, identity, security baseline, state backend y CI/CD. Todo desplegable desde cero con `tofu apply`.

## Entregables

### 1. Módulo `state-backend`
Bootstrap manual (se aplica primero, antes de que exista remote state).

- S3 bucket con versionamiento y SSE-KMS (clave dedicada)
- State locking nativo S3 (`use_lockfile = true`, sin DynamoDB)
- Bucket policy restrictiva (solo CI/CD roles + admins)
- Replicación cross-region: configurable, deshabilitada por defecto en dev
- Encryption block nativo de OpenTofu (double encryption)

### 2. Módulo `networking/vpc`
Instanciable N veces con `for_each` sobre un map de VPCs.

**Parámetros del map:**

| Parámetro | Descripción |
|---|---|
| cidr | Bloque CIDR (ej: 10.0.0.0/16) |
| azs | Número de AZs (2 para dev/staging, 3 para prod) |
| single_nat | true = 1 NAT GW (~$32/mes ahorro). false = 1 por AZ |
| vpc_endpoints | Lista de endpoints (ej: ["s3", "ssm", "ecr.api"]) |
| flow_logs_destination | "cloudwatch" \| "s3" \| "both" |

**Ejemplo tfvars:**

```hcl
vpcs = {
  main = {
    cidr            = "10.2.0.0/16"
    azs             = 3
    single_nat      = false
    vpc_endpoints   = ["s3", "ssm", "ecr.api", "logs"]
  }
  # Solo si se justifica (compliance, blast radius, ownership):
  # isolated = {
  #   cidr          = "10.12.0.0/16"
  #   azs           = 3
  #   single_nat    = false
  #   vpc_endpoints = ["s3"]
  # }
}
```

**Decision tree — ¿Más de 1 VPC por entorno?**

- ✅ Compliance/regulatorio (PCI-DSS, HIPAA scope separation)
- ✅ Blast radius (líneas de negocio con tolerancia a fallo distinta)
- ✅ Ownership distinto (equipos independientes, evaluar si multi-account no es mejor)
- ❌ "Este proyecto es diferente" → subnets + security groups
- ❌ "Separar frontend de backend" → subnets + NACLs
- ❌ "Una VPC por microservicio" → problema de app, no de networking

### 3. Módulo `identity/sso`
- Permission sets: AdministratorAccess, PowerUserAccess, ReadOnlyAccess, BillingAccess
- Grupos: platform-admins, developers, readonly, billing
- Password policy: 14 chars min, rotación 90 días, no reutilización últimas 24

### 4. Módulo `identity/iam-baseline`
- IMDSv2 enforced en todas las instancias
- S3 Block Public Access a nivel de cuenta
- Account-level settings

### 5. Módulos de seguridad (todos con `enabled = false` por defecto)

| Módulo | Configuración cuando enabled = true |
|---|---|
| `security/cloudtrail` | Multi-region, management + data events. **Excepción: enabled = true por defecto** (bajo costo, esencial para auditoría) |
| `security/config-rules` | encrypted-volumes, s3-bucket-public-read-prohibited, iam-root-access-key-check, vpc-flow-logs-enabled |
| `security/guardduty` | S3 protection, EKS protection (si aplica) |
| `security/securityhub` | AWS Foundational Security Best Practices + CIS Benchmarks |

### 6. Blueprint `landing-zone-basic`
Composición que conecta todos los módulos anteriores con defaults opinados por entorno.

### 7. Pipeline CI/CD

| Workflow | Trigger | Acción |
|---|---|---|
| module-test.yml | PR a main (modules/**) | tofu fmt, validate, Checkov, tofu test |
| blueprint-validate.yml | PR a main (blueprints/**) | tofu init, plan (mock vars), policy check |
| deploy.yml | Push a main + env label | plan → approval manual → apply |
| drift-detect.yml | Cron (diario) | plan en cada entorno, notifica si hay drift |
| docs-gen.yml | PR a main | terraform-docs auto-commit |

**Seguridad del pipeline:**
- AWS credentials via OIDC (GitHub → IAM Role). Nunca secrets estáticos.
- Apply requiere aprobación manual en producción (GitHub Environments)
- Checkov como quality gate bloqueante

## Orden de implementación

1. Crear repo `xancloud/xancloud-iac` + scaffold + .gitignore + pre-commit hooks
2. `modules/state-backend` (bootstrap manual)
3. `modules/networking/vpc` + tests
4. Pipeline CI básico (fmt + validate + checkov en PR)
5. `modules/security/*` + `modules/identity/*`
6. `blueprints/landing-zone-basic`
7. `environments/` tfvars + deploy pipeline

## Criterio de completitud

La fase 1 está completa cuando:

- [ ] `tofu apply` desde cero despliega la landing zone completa en un entorno limpio
- [ ] Todos los módulos tienen tests que pasan en CI
- [ ] 0 findings críticos en Checkov
- [ ] README de cada módulo auto-generado y actualizado
- [ ] Pipeline de deploy funcional con approval en prod
