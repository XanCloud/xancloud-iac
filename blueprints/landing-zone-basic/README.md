# Landing Zone — Basic

Phase 1 MVP blueprint. Composes three modules into an opinionated single-account landing zone:

- `networking/vpc` — one or more VPCs with public/private subnets, NAT, flow logs, VPC endpoints.
- `security/cloudtrail` — multi-region account trail with dedicated S3 bucket and KMS key.
- `identity/iam-baseline` — account-wide hardening (S3 BPA, password policy, Access Analyzer, IMDSv2 defaults, optional alias). Only applied from the environment that sets `is_account_owner = true`.

State backend is **not** part of this blueprint. Bootstrap [`modules/state-backend`](../../modules/state-backend) first; this blueprint consumes that backend via `-backend-config`.

## Architecture

```
┌──────────────────────────────────── AWS account ────────────────────────────────────┐
│                                                                                     │
│  ┌─ per environment root (dev, prod, …) ────────────────────────────────────────┐  │
│  │                                                                              │  │
│  │   module "vpc"          — one or more VPCs (public/private subnets, NAT)     │  │
│  │   module "cloudtrail"   — dedicated bucket + KMS per environment             │  │
│  │   module "iam_baseline" — ONLY when is_account_owner = true                  │  │
│  │                                                                              │  │
│  └──────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                     │
│   Account-level singletons (password policy, S3 BPA, IMDSv2, alias)                 │
│   are managed by the owner environment only.                                        │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- OpenTofu >= 1.11.0
- AWS credentials with permission to manage VPC, CloudTrail, IAM, S3, KMS, and EC2 defaults.
- `modules/state-backend` already applied in the target account. You need its bucket name and KMS key ARN for `-backend-config`.

## Singleton constraint

Set `is_account_owner = true` in **exactly one** environment per AWS account. Phase 1 convention: **dev owns the account**.

Two environments with `is_account_owner = true` in the same account will fight over `aws_iam_account_password_policy`, `aws_s3_account_public_access_block`, `aws_ec2_instance_metadata_defaults`, and `aws_iam_account_alias`. Every other apply will show drift.

## Quick start

```bash
cd blueprints/landing-zone-basic

# 1. Copy and edit the backend config with your state-backend values
cp examples/backend-dev.hcl backend-dev.hcl
# Edit backend-dev.hcl: replace <account-id> and <kms-key-id> with real values

# 2. Copy and edit the tfvars for your environment
cp examples/dev.tfvars dev.tfvars
# Edit dev.tfvars: set region to match your AWS profile

# 3. Init, plan, apply
tofu init  -backend-config=backend-dev.hcl
tofu plan  -var-file=dev.tfvars
tofu apply -var-file=dev.tfvars
```

For prod, repeat with `examples/backend-prod.hcl` and `examples/prod.tfvars`. The prod state lives at a different `key` under the same S3 bucket.

> See [`docs/DEPLOYMENT.md`](../../docs/DEPLOYMENT.md) for the full step-by-step including state backend bootstrap, state migration to S3, post-deploy verification, and clean destroy.

## Usage examples

### Dev — account owner, cost-optimized

```hcl
region      = "us-east-1"
environment = "dev"
project     = "xancloud"

is_account_owner = true
account_alias    = "xancloud-dev"

vpcs = {
  main = {
    cidr                  = "10.10.0.0/16"
    azs                   = 2
    single_nat            = true
    vpc_endpoints         = ["s3", "ssm", "ssmmessages", "ecr.api", "ecr.dkr", "logs"]
    flow_logs_destination = "cloudwatch"
  }
}
```

### Prod — HA, CW Logs delivery, 2-year retention

```hcl
region      = "us-east-1"
environment = "prod"
project     = "xancloud"

is_account_owner = false

vpcs = {
  main = {
    cidr                  = "10.20.0.0/16"
    azs                   = 3
    single_nat            = false
    vpc_endpoints         = ["s3", "ssm", "ssmmessages", "ecr.api", "ecr.dkr", "logs", "secretsmanager"]
    flow_logs_destination = "s3"
  }
}

cloudtrail_cloudwatch_logs_enabled = true
cloudtrail_log_retention_days      = 731
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `region` | `string` | — | AWS region (e.g. `us-east-1`) |
| `environment` | `string` | — | `dev`, `staging`, or `prod` |
| `project` | `string` | `"xancloud"` | Project name for naming and tags |
| `owner` | `string` | `"platform-team"` | Responsible team |
| `cost_center` | `string` | `"CC-001"` | Cost center |
| `extra_tags` | `map(string)` | `{}` | Additional tags |
| `vpcs` | `map(object)` | — | VPCs to create. See VPC module docs. |
| `is_account_owner` | `bool` | `false` | Must be `true` in EXACTLY ONE env per account |
| `account_alias` | `string` | `null` | Account alias (owner only) |
| `iam_baseline_enable_s3_block` | `bool` | `true` | Toggle account-level S3 BPA |
| `iam_baseline_enable_password_policy` | `bool` | `true` | Toggle password policy |
| `iam_baseline_enable_access_analyzer` | `bool` | `true` | Toggle Access Analyzer |
| `iam_baseline_enable_imdsv2_default` | `bool` | `true` | Toggle IMDSv2 defaults |
| `cloudtrail_enabled` | `bool` | `true` | Master switch for CloudTrail |
| `cloudtrail_multi_region` | `bool` | `true` | Multi-region trail |
| `cloudtrail_cloudwatch_logs_enabled` | `bool` | `false` | CW Logs delivery |
| `cloudtrail_log_retention_days` | `number` | `365` | CW Logs retention |
| `cloudtrail_log_expiration_days` | `number` | `365` | S3 log expiration (CIS baseline ≥ 365) |

## Outputs

| Name | Description |
|------|-------------|
| `account_id` | AWS account ID where the landing zone was deployed |
| `vpcs` | Map of VPC info (id, cidr_block) keyed by VPC name |
| `vpc_ids` | Map of VPC IDs keyed by VPC name |
| `public_subnet_ids_by_vpc` | Public subnet IDs grouped by VPC name |
| `private_subnet_ids_by_vpc` | Private subnet IDs grouped by VPC name |
| `nat_gateway_ids` | NAT Gateway IDs keyed by VPC name |
| `cloudtrail_arn` | CloudTrail ARN (null when disabled) |
| `cloudtrail_s3_bucket_id` | Trail bucket name (null when disabled) |
| `cloudtrail_kms_key_arn` | Trail KMS key ARN (null when disabled) |
| `iam_access_analyzer_arn` | Access Analyzer ARN (null when not owner) |
| `account_alias` | Account alias (null when not owner or unset) |

## Out of scope (Phase 1)

- State backend composition (separate bootstrap — see `modules/state-backend`).
- AWS Organizations, multi-account, SSO.
- GuardDuty, SecurityHub, AWS Config.
- Transit Gateway, VPC peering, IPv6.
- Cross-region resource fan-out (Access Analyzer, IMDSv2 defaults stay in provider region).

These capabilities are available as private extensions for consulting clients. See [docs/PHASE-2.md](../../docs/PHASE-2.md).
