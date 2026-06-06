# xancloud-iac — AI Agent Instructions

LLM-agnostic rules for any AI assistant working on this repository.
Tool-specific configs (`.claude/`, `.cursor/`, etc.) extend these rules but MUST NOT contradict them.

## Active Phase: 1 — MVP Landing Zone

4 modules + 1 blueprint. All complete. Do NOT create modules outside this scope without explicit request.

| Component | Path | Status |
|-----------|------|--------|
| state-backend | `modules/state-backend/` | Complete |
| networking/vpc | `modules/networking/vpc/` | Complete |
| security/cloudtrail | `modules/security/cloudtrail/` | Complete |
| identity/iam-baseline | `modules/identity/iam-baseline/` | Complete |
| landing-zone-basic | `blueprints/landing-zone-basic/` | Complete |

## Stack

- **IaC:** OpenTofu >= 1.11.0. Binary: `tofu`. NEVER `terraform`.
- **Provider:** `hashicorp/aws ~> 6.0`
- **State:** S3 + KMS + native S3 locking (`use_lockfile = true`). No DynamoDB.
- **CI/CD:** None yet (Phase 2: GitHub Actions + OIDC)
- **Policy scanning:** None yet (Phase 2: Checkov >= 3.2.x)
- **Testing:** None yet (Phase 2: `tofu test` + Terratest)

## Languages

- Code, README, commits, changelogs, AGENTS.md: **English**
- Documentation (`docs/`): **Spanish**
- Conversations with the user: **Spanish** (unless user switches to English)

## Module File Structure

Every module follows this exact order:

```
modules/{category}/{name}/
├── versions.tf      # required_version + required_providers (no backend, no provider block)
├── variables.tf     # inputs: type, description, validation, defaults
├── locals.tf        # common_tags, name_prefix, derived values
├── main.tf          # resources and data sources
├── outputs.tf       # outputs with description
└── README.md        # manual (no terraform-docs until Phase 2)
```

No `examples/`, no `tests/` per module until Phase 2.

## versions.tf Template

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

No provider blocks inside modules. Provider config lives in blueprints only.

## Common Variables (mandatory in every module)

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

variable "owner" {
  description = "Team or individual responsible for resources"
  type        = string
  default     = "platform-team"
}

variable "cost_center" {
  description = "Cost center for billing attribution"
  type        = string
  default     = "CC-001"
}

variable "extra_tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
```

## locals.tf Pattern

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    ManagedBy   = "opentofu"
    CostCenter  = var.cost_center
  }
  name_prefix = "${var.project}-${var.environment}"
}
```

## Naming Convention

Pattern: `{project}-{environment}-{service}-{resource}`
Built from: `"${local.name_prefix}-{service}-{resource}"`

Examples:
- `xancloud-dev-vpc`, `xancloud-prod-cloudtrail`
- KMS aliases: `alias/xancloud-dev-state`

## Tagging (mandatory on every taggable resource)

```hcl
tags = merge(local.common_tags, var.extra_tags)
```

For resources with a Name tag:
```hcl
tags = merge(local.common_tags, var.extra_tags, {
  Name = "${local.name_prefix}-{service}-{resource}"
})
```

## Security Rules

- Encryption at-rest: **mandatory**. KMS (CMK) preferred.
- S3 buckets: always `aws_s3_bucket_public_access_block` with all 4 flags = true.
- IAM policies: use `aws_iam_policy_document` data source, NOT `jsonencode()` inline.
- IAM: least privilege. No wildcard `*` without a comment explaining why.
- IMDSv2: always enforced (`http_tokens = "required"`). Never allow IMDSv1.
- Security services default `enabled = false` except CloudTrail (`true`).
- Pattern for optional services: `count = var.enabled ? 1 : 0`

## HCL Rules

- `for_each` over maps for collections with identity. `count` only for simple enable/disable.
- `alltrue()` not `all()` — `all()` does not exist in OpenTofu/Terraform.
- No hardcoded AWS account IDs, region names, or ARNs.
- No provider blocks inside modules.
- Variables: always `type` + `description`. Validation blocks where input merits it.
- Outputs: always `description`. Export IDs and ARNs needed for composition.

## Git Conventions

- **Commits:** Conventional Commits, English, imperative, 72 chars max.
  Format: `<type>(<scope>): <subject>`
  Types: `feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `style`
- **Branches:** GitHub Flow. Prefixes: `feature/`, `fix/`, `docs/`, `chore/`, `refactor/`, `test/`. Kebab-case.
- **Merge:** Squash merge to `main`. Short-lived branches (< 1 week).
- **Tags:** SemVer per module: `modules/vpc/v1.0.0`
- **Prohibited:** "WIP", "misc", "updates" in commit messages. Spanish in commit subjects.

## Validation Before Commit

```bash
tofu fmt -recursive
tofu validate          # run from each module or blueprint directory
```

Both must pass with zero warnings before any commit.

## Pre-push Hook (required)

A pre-push hook blocks direct pushes to `main`. Install it when cloning fresh:

```bash
git config core.hooksPath .githooks
```

> The hook lives in `.githooks/pre-push` (tracked in repo). This approach (`core.hooksPath`) ensures everyone gets the same hook. No manual copying needed.

## Key Architectural Decisions

1. **OpenTofu over Terraform** — MPL 2.0, no vendor lock-in (ADR-001)
2. **AWS only in MVP** — multi-cloud is Phase 2+ (ADR-002)
3. **modules/ + blueprints/ + environments/ structure** (ADR-003)
4. **S3 + KMS + native lockfile, no DynamoDB** (ADR-004)
5. **Single AWS account** — tags for env separation, no Organizations yet
6. **NAT Gateway:** single in dev (cost), per-AZ in prod (HA)
7. **Singleton constraint:** `is_account_owner = true` in exactly ONE environment per account

## What NOT to Do

- Never use `terraform` binary — always `tofu`
- Never add DynamoDB for state locking
- Never use Terraform Cloud, Sentinel, or HashiCorp-proprietary features
- Never use Launch Configurations — Launch Templates only
- Never allow IMDSv1
- Never add modules beyond Phase 1 scope without explicit request
- Never hardcode account IDs, regions, or ARNs
- Never commit `.tfvars` with real credentials or account-specific values
- Never push directly to `main` (blocked by pre-push hook + GitHub branch protection)

## Known LLM Pitfalls

These are common mistakes AI assistants make with this codebase:

- S3 `versioning {}` block inside `aws_s3_bucket` is deprecated (provider >= 4.x). Use `aws_s3_bucket_versioning` as separate resource.
- Same for `server_side_encryption_configuration` — separate resource since provider 4.x.
- CloudTrail S3 bucket policy must allow `s3:PutObject` from `cloudtrail.amazonaws.com`.
- VPC Flow Logs to CloudWatch require an IAM role with `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`.
- NAT Gateway requires an `aws_eip` resource — don't forget it.
- Object Lock requires `object_lock_enabled = true` at bucket creation — cannot be added later.
- IAM replication policies for KMS-encrypted objects need `kms:Decrypt` on source AND `kms:Encrypt` on destination key.
- `alltrue()` exists, `all()` does not.
- **State-backend bootstrap lockout:** The S3 bucket policy in `state-backend` has a `DenyUnauthorizedAccess` statement that only allows `:root` and `allowed_roles`. If `allowed_roles` is empty (default), the deploying IAM user gets locked out the moment the bucket policy is applied. **Always include the caller ARN in `allowed_roles` before the first `tofu apply`.** This is not optional for non-root deployers. See `docs/TROUBLESHOOTING.md` for recovery steps.

## Dependency Map

```
state-backend (bootstrap first, standalone, local state → migrate to S3)
    ↓ provides: bucket_id, kms_key_arn → backend-config for blueprint
landing-zone-basic (blueprint, uses S3 backend via -backend-config)
    ├── networking/vpc       (independent, creates VPCs/subnets/NAT/endpoints/flow logs)
    ├── security/cloudtrail  (independent, creates trail/S3/KMS/optional CW Logs)
    └── identity/iam-baseline (conditional: enabled = var.is_account_owner)
```

## Phase Progression

| Phase | Trigger | Adds |
|-------|---------|------|
| 1 (current) | — | 4 modules + 1 blueprint, manual quality gate |
| 2 | First paying client | CI/CD, Checkov, tofu test, terraform-docs, examples/ |
| 3 | Real usage data | Scale or pivot decision |

## Context Docs — Keep in Sync

When modifying `.tf` files, modules, or blueprints, check if these files need updating **in the same commit**:

| File | Update when |
|------|------------|
| `AGENTS.md` (this file) | Modules added/removed, conventions change, dependency map changes |
| `docs/STATUS.md` | Module status changes, new blockers, items completed |
| `docs/ARCHITECTURE.md` | Module relationships change, new subnet layouts, new blueprints |
| `docs/TROUBLESHOOTING.md` | New gotchas discovered during implementation |

**Rule:** If a commit changes module scope, interfaces (variables/outputs), or project structure, context docs MUST be updated in the same commit. A pre-commit hook warns if `.tf` files changed without context doc updates.

## Reference Documentation

- `docs/PROJECT.md` — Project context and scope (Spanish)
- `docs/PHASE-{0,1,2,3}.md` — Phase details (Spanish)
- `docs/DECISIONS.md` — Architecture Decision Records (Spanish)
- `docs/RISKS.md` — Risk register (Spanish)
- `docs/DEPLOYMENT.md` — Step-by-step deploy procedure (Spanish)
- `docs/ARCHITECTURE.md` — Module dependency map and data flow (Spanish)
- `docs/TROUBLESHOOTING.md` — Known issues and solutions (Spanish)
- `docs/STATUS.md` — Current project state (Spanish)
