---
name: xancloud-iac-modules
description: >
  Genera y revisa módulos HCL para el proyecto xancloud-iac usando OpenTofu (NO Terraform).
  Trigger cuando se trabaje en cualquier archivo dentro de modules/, se mencione crear, editar,
  revisar o refactorizar módulos de OpenTofu/Terraform, o se usen palabras como "módulo",
  "variable", "output", "resource", "locals", "versions.tf", o nombres de servicios AWS
  (VPC, GuardDuty, SecurityHub, CloudTrail, S3, IAM, SSO, Config, KMS, NAT Gateway, etc.).
  También trigger cuando se pida generar un nuevo módulo desde cero, agregar variables,
  outputs, validation blocks, examples, o cualquier archivo HCL dentro de la estructura
  de módulos del proyecto. Trigger incluso si el usuario dice "terraform" — el proyecto usa
  OpenTofu y este skill aplica las convenciones correctas automáticamente.
---

# XanCloud IaC — Module Generator

## Contexto del proyecto

xancloud-iac es un acelerador de consultoría IaC basado en OpenTofu para AWS. Los módulos son el producto core.

**Stack fijo:**
- OpenTofu >= 1.11.0 (stable: 1.11.5). El binario es `tofu`, no `terraform`.
- AWS Provider >= 5.x (`hashicorp/aws`, constraint `~>`).
- State backend: S3 con `use_lockfile = true`. Sin DynamoDB.
- Checkov >= 3.2.x para security scanning.

**Lo que NO se usa (nunca proponer):**
- Terraform Cloud, Sentinel, remote runs, o cualquier feature exclusiva de HashiCorp Terraform.
- DynamoDB para state locking.
- Launch Configurations (usar Launch Templates).
- IMDSv1 (enforced IMDSv2).

## Estructura obligatoria de módulos

Todo módulo vive bajo `modules/{category}/{name}/` y contiene exactamente estos archivos:

```
modules/{category}/{name}/
├── main.tf          # Recursos principales
├── variables.tf     # Inputs con type, description, default, validation
├── outputs.tf       # Outputs con description
├── versions.tf      # required_providers con ~> constraint
├── locals.tf        # Valores derivados, lógica de tags, naming
├── README.md        # Auto-generado con terraform-docs (no editar manual)
├── examples/        # Al menos un ejemplo funcional
│   └── simple/
│       ├── main.tf
│       ├── variables.tf (si aplica)
│       └── outputs.tf (si aplica)
└── tests/           # tofu test files
    └── basic.tftest.hcl
```

No inventar archivos adicionales como `data.tf`, `iam.tf`, etc. Si el módulo crece, documentar en un comentario en `main.tf` por qué se justificaría split, pero no hacerlo sin aprobación.

## Convenciones de código

### versions.tf

```hcl
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

No incluir `backend` block en módulos. El backend se configura en blueprints/environments.

### variables.tf

Toda variable lleva `type`, `description`, y `validation` donde aplique. Usar `default` solo cuando hay un valor opinado razonable.

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project" {
  type        = string
  description = "Project name for resource naming and tagging"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project))
    error_message = "Project must be lowercase alphanumeric with hyphens, 2-21 chars."
  }
}
```

Variables comunes que TODO módulo debe aceptar: `environment`, `project`, `owner`, `cost_center`. Estos alimentan los tags obligatorios.

### Tags obligatorios

Todo recurso que soporte tags DEBE incluirlos. Implementar en `locals.tf`:

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    ManagedBy   = "opentofu"
    CostCenter  = var.cost_center
  }
}
```

Luego en recursos: `tags = merge(local.common_tags, var.extra_tags)`.

La variable `extra_tags` es `map(string)` con default `{}`.

### Naming convention

```
{project}-{env}-{service}-{resource}
```

Implementar en `locals.tf`:

```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
}
```

Uso: `name = "${local.name_prefix}-vpc-main"`.

### outputs.tf

Todo output con `description`. Exportar IDs, ARNs y atributos que otros módulos necesiten consumir.

```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}
```

### Encriptación

Obligatoria at-rest en todo recurso que la soporte. Usar KMS keys dedicadas, no `aws/service` keys cuando sea posible. Si el módulo crea un recurso encriptable sin encriptación, es un 🔴 Critical.

### IAM

Least privilege. Nunca `"*"` en actions o resources sin justificación en comentario HCL. Preferir `aws_iam_policy_document` data source sobre JSON inline.

### Security services

GuardDuty, SecurityHub, Config Rules: `enabled = false` por defecto. CloudTrail: `enabled = true` por defecto. Patrón:

```hcl
variable "enabled" {
  type        = bool
  description = "Whether to create the resources in this module"
  default     = false  # o true para CloudTrail
}
```

Usar `count = var.enabled ? 1 : 0` en el recurso principal.

## Proceso de generación

Cuando el usuario pida crear un módulo:

1. Confirmar categoría y nombre (`modules/{category}/{name}/`).
2. Generar TODOS los archivos de la estructura obligatoria en orden: versions.tf → variables.tf → locals.tf → main.tf → outputs.tf → examples/simple/ → tests/basic.tftest.hcl.
3. No generar README.md — se auto-genera con terraform-docs en CI.
4. Verificar contra el checklist antes de entregar.

## Checklist de calidad (verificar antes de entregar)

- [ ] `versions.tf` con `required_version >= 1.11.0` y providers con `~>`
- [ ] Todas las variables con `type` + `description`
- [ ] Variables de entorno (`environment`, `project`, `owner`, `cost_center`) presentes
- [ ] Validation blocks en variables que lo ameriten
- [ ] Tags obligatorios en todos los recursos (via `local.common_tags`)
- [ ] Naming con `local.name_prefix`
- [ ] Encriptación at-rest en recursos que la soporten
- [ ] IAM con least privilege (sin `*` injustificados)
- [ ] Outputs con `description`
- [ ] Ejemplo funcional en `examples/simple/`
- [ ] Test básico en `tests/basic.tftest.hcl`
- [ ] Sin backend block en el módulo
- [ ] Sin referencias a Terraform Cloud, Sentinel, DynamoDB locking

## Módulos de Fase 1 (referencia)

Para el detalle de cada módulo de Fase 1, consultar `references/phase1-modules.md`. Los módulos son:

- `state-backend` — S3 + KMS, bootstrap manual
- `networking/vpc` — VPC iterable con for_each
- `identity/sso` — IAM Identity Center
- `identity/iam-baseline` — Account-level settings
- `security/cloudtrail` — Multi-region (enabled=true)
- `security/guardduty` — S3/EKS protection (enabled=false)
- `security/securityhub` — FSBP + CIS (enabled=false)
- `security/config-rules` — Managed rules (enabled=false)
- `operations/monitoring` — CloudWatch base
- `operations/cost-mgmt` — Budgets + anomaly detection
