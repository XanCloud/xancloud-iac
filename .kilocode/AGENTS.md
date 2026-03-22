# XanCloud IaC — Agent Context

## Project Phase

Phase 1 — MVP. Only these modules exist or are in progress:
- `modules/state-backend/` ✅ Complete
- `modules/networking/vpc/` 🔧 In progress
- `modules/security/cloudtrail/` ⬜ Pending
- `modules/identity/iam-baseline/` ⬜ Pending
- `blueprints/landing-zone-basic/` ⬜ Pending

Do NOT generate modules outside this list unless explicitly asked.

## Stack

- OpenTofu >= 1.11.0 (binary: `tofu`, NEVER `terraform`)
- AWS Provider: hashicorp/aws ~> 6.0
- Checkov >= 3.2.x
- CI/CD: GitHub Actions (Phase 2+)

## Tools

### ⚠️ OPENTOFU MCP — OBLIGATORIO SIEMPRE

**REGLA: Antes de tocar CUALQUIER archivo `.tf` — SIEMPRE usar el MCP primero.**

No importa si es "solo leer", "es un cambio pequeño", "ya sabes cómo funciona". SIEMPRE.

Pasos obligatorios:
1. Lee el archivo
2. Identifica TODOS los recursos y data sources
3. `opentofu_get-resource-docs` para cada uno
4. `opentofu_get-provider-details` para version constraints
5. Solo entonces escribe código

Si usas una función HCL que no estás 100% seguro — `tofu console` para probar primero.

**Tu conocimiento de OpenTofu/HCL está desactualizado. No lo uses. Usa el MCP.**

### Validation Commands

- `tofu fmt` después de generar archivos
- `tofu validate` después de formatear
- Nunca `tofu apply` sin instrucción explícita

## Conventions

### File Order (every module)

1. `versions.tf` — required_providers with version constraints (~>)
2. `variables.tf` — inputs with type, description, default, validation blocks
3. `locals.tf` — derived values, common_tags, name_prefix
4. `main.tf` — resources
5. `outputs.tf` — outputs with description
6. `README.md` — manual (no terraform-docs until Phase 2)

### versions.tf (exact template)

```hcl
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

No provider blocks inside modules. Provider config lives in blueprints/environments only.

### Variables — Common Variables ALWAYS Present

Every module MUST have these variables:

```hcl
variable "project" {
  description = "Project name for resource naming and tagging"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project))
    error_message = "Project must be lowercase alphanumeric with hyphens, 2-21 chars."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "extra_tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
```

Additional variable rules:
- ALL variables MUST have `description`
- ALL variables MUST have `type`
- Use `validation` blocks for constrained inputs
- Use `optional()` in object type definitions
- Use `sensitive = true` on variables containing keys or secrets

### Tags (locals.tf)

```hcl
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "opentofu"
  }
}
```

Usage: `tags = merge(local.common_tags, var.extra_tags)`

Every taggable resource MUST include tags. No exceptions.

### Naming

Pattern: `{project}-{environment}-{service}-{resource}`
Use: `local.name_prefix = "${var.project}-${var.environment}"`

### Security

- Use `aws_iam_policy_document` data source for IAM policies (NOT `jsonencode()` inline)
- No wildcard (`*`) IAM resources without a comment explaining why
- All S3 buckets: `aws_s3_bucket_public_access_block` with all four blocks = true
- All encryption at-rest: KMS (CMK) preferred, SSE-S3 acceptable for non-sensitive
- IMDSv2 enforced on all EC2 instances (http_tokens = "required")
- No DynamoDB for state locking — use native S3 locking (`use_lockfile = true`)

### HCL Rules

- `alltrue()` NOT `all()` — OpenTofu/Terraform does not have `all()`
- No provider blocks inside modules
- `for_each` over maps, not `count` for collections with identity
- `sensitive = true` on outputs containing keys, secrets, or ARNs of security resources
- Lifecycle rules: use `prevent_destroy` on state buckets and KMS keys
- No hardcoded values — use variables and locals
- No hardcoded AWS account IDs or region names

### Module Rules

- No backend block in modules (backend config lives in environments/)
- Outputs: always include `description`
- Outputs: expose only what consumers need (not internal details)
- README.md: manual until Phase 2 (then terraform-docs auto-generated)
- No `examples/` directory until Phase 2
- No `tests/` directory until Phase 2

## Known LLM Pitfalls

- S3 notifications to SQS require `aws_sqs_queue_policy` — create it or document the prerequisite
- Object Lock requires `object_lock_enabled = true` in `aws_s3_bucket` at creation time — cannot be added later
- Versioning MUST be enabled when Object Lock or Replication is enabled — add validation or force it
- IAM replication policies for KMS-encrypted objects need `kms:Decrypt` on source key AND `kms:Encrypt` on destination key (separate keys)
- `aws_s3_bucket_versioning` is a separate resource from `aws_s3_bucket` in provider >= 4.x — do NOT use the deprecated `versioning {}` block inside `aws_s3_bucket`
- CloudTrail S3 bucket policy must allow `s3:PutObject` from `cloudtrail.amazonaws.com` with `s3:x-amz-acl = bucket-owner-full-control`
- VPC Flow Logs to CloudWatch require an IAM role with `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`
- NAT Gateway requires an Elastic IP — do NOT forget the `aws_eip` resource
- `aws_s3_bucket_server_side_encryption_configuration` is a separate resource in provider >= 4.x

## Prohibitions

- NEVER usar `terraform` binary o referenciar Terraform Cloud
- NEVER usar DynamoDB para state locking
- NEVER habilitar IMDSv1 (http_tokens debe ser "required")
- NEVER crear recursos en `us-east-1` a menos que sea explícitamente requerido
- NEVER generar modules fuera de Phase 1 scope sin request explícita
- NEVER asumir que sabes cómo funciona un recurso — siempre usar el MCP primero
- NEVER hacer commit sin haber corrido `tofu fmt` y `tofu validate`

## Commit Checklist

Antes de cada commit, verificar:

1. **Documentación**: ¿Se actualizó `CHANGELOG.md`? ¿El módulo tiene `README.md`?
2. **Pre-commit**: `pre-commit run --all-files` (si está configurado)
3. **Validate**: `tofu fmt && tofu validate` pasan sin warnings
4. **Archivos relevantes**: ¿Se tocaron todos los archivos necesarios? (ej: no saltarse templates, configs, etc.)
5. **Conventional Commits**: mensaje descriptivo con tipo (`feat`, `fix`, `docs`, `refactor`)