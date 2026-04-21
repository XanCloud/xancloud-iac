# IAM Baseline

Account-level security hardening for a single AWS account. No IAM users or roles — that belongs to blueprint composition or Phase 2.

Five controls, all on by default:

- Account-wide S3 Block Public Access
- IAM account password policy (CIS 3.x aligned)
- IAM Access Analyzer (account scope, regional)
- EC2 instance metadata defaults (IMDSv2 enforcement, regional)
- Optional account alias

## Usage

### Minimal

```hcl
module "iam_baseline" {
  source = "../../modules/identity/iam-baseline"

  environment = "dev"
  project     = "xancloud"
  owner       = "platform-team"
  cost_center = "CC-001"
}
```

This creates:

- S3 Block Public Access (all four flags on) at the account level.
- Password policy: length 14, all complexity requirements, max age 90, reuse prevention 24.
- IAM Access Analyzer `xancloud-dev-account-analyzer` in the provider's region.
- EC2 instance metadata defaults with `http_tokens = required` and hop limit 2.

### With account alias

```hcl
module "iam_baseline" {
  source = "../../modules/identity/iam-baseline"

  environment   = "dev"
  project       = "xancloud"
  owner         = "platform-team"
  cost_center   = "CC-001"
  account_alias = "xancloud-dev"
}
```

### Disable a specific control

Useful when an SCP or another mechanism already enforces the control upstream:

```hcl
module "iam_baseline" {
  source = "../../modules/identity/iam-baseline"

  environment           = "prod"
  enable_imdsv2_default = false
}
```

### Disable everything

```hcl
module "iam_baseline" {
  source = "../../modules/identity/iam-baseline"

  environment = "dev"
  enabled     = false
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `environment` | `string` | — | Deployment environment (`dev`, `staging`, `prod`) |
| `project` | `string` | `"xancloud"` | Project name for naming and tags |
| `owner` | `string` | `"platform-team"` | Responsible team or individual |
| `cost_center` | `string` | `"CC-001"` | Cost center for billing attribution |
| `extra_tags` | `map(string)` | `{}` | Additional tags merged with common tags |
| `enabled` | `bool` | `true` | Master switch for the module |
| `enable_s3_account_public_access_block` | `bool` | `true` | Manage account-level S3 Block Public Access |
| `enable_password_policy` | `bool` | `true` | Manage the IAM account password policy |
| `enable_access_analyzer` | `bool` | `true` | Create an IAM Access Analyzer |
| `enable_imdsv2_default` | `bool` | `true` | Manage regional EC2 instance metadata defaults |
| `s3_block_public_acls` | `bool` | `true` | Block new public ACLs |
| `s3_block_public_policy` | `bool` | `true` | Block new public bucket policies |
| `s3_ignore_public_acls` | `bool` | `true` | Ignore public ACLs |
| `s3_restrict_public_buckets` | `bool` | `true` | Restrict access to buckets with public policies |
| `password_minimum_length` | `number` | `14` | Minimum password length (8–128) |
| `password_require_lowercase` | `bool` | `true` | Require at least one lowercase character |
| `password_require_uppercase` | `bool` | `true` | Require at least one uppercase character |
| `password_require_numbers` | `bool` | `true` | Require at least one number |
| `password_require_symbols` | `bool` | `true` | Require at least one symbol |
| `password_allow_users_to_change` | `bool` | `true` | Allow users to rotate their own password |
| `password_max_age` | `number` | `90` | Max password age in days (1–1095) |
| `password_reuse_prevention` | `number` | `24` | Previous passwords blocked from reuse (1–24) |
| `password_hard_expiry` | `bool` | `false` | Block self-service reset after expiry |
| `analyzer_name` | `string` | `null` | Override for analyzer name |
| `analyzer_type` | `string` | `"ACCOUNT"` | `ACCOUNT`, `ACCOUNT_UNUSED_ACCESS`, or `ACCOUNT_INTERNAL_ACCESS` |
| `imdsv2_http_tokens` | `string` | `"required"` | `required`, `optional`, or `no-preference` |
| `imdsv2_http_put_response_hop_limit` | `number` | `2` | IMDS response hop limit (1–64) |
| `imdsv2_http_endpoint` | `string` | `"enabled"` | `enabled`, `disabled`, or `no-preference` |
| `imdsv2_instance_metadata_tags` | `string` | `"enabled"` | `enabled`, `disabled`, or `no-preference` |
| `account_alias` | `string` | `null` | Account alias. Null leaves any existing alias alone. |

## Outputs

| Name | Description |
|------|-------------|
| `account_id` | AWS account ID this module applied to |
| `account_alias` | Account alias managed by this module (null when not set) |
| `access_analyzer_arn` | ARN of the IAM Access Analyzer (null when disabled) |
| `access_analyzer_id` | ID of the IAM Access Analyzer (null when disabled) |
| `access_analyzer_name` | Name of the IAM Access Analyzer (null when disabled) |
| `password_policy_applied` | True when the password policy was managed by this module |
| `s3_public_access_block_applied` | True when S3 BPA was managed by this module |
| `imdsv2_default_applied` | True when IMDSv2 defaults were managed by this module |

## Design notes

**Account-level singletons.** S3 Block Public Access, the password policy, the account alias, and the EC2 instance metadata defaults are one-per-account (the last is one-per-region). Instantiate this module **exactly once per account** from whichever environment owns it — typically directly from `environments/<env>/`, not from a sub-module that can be invoked multiple times.

**IAM Access Analyzer is regional.** One analyzer per region per scope. This module creates one in the provider's configured region. Multi-region coverage via provider aliases is out of scope for Phase 1.

**IMDSv2 defaults are regional.** Same caveat. Multi-region fan-out via provider aliases lands in Phase 2.

**Access Analyzer with external findings is free.** Default-on is cheap signal — it flags resources shared outside the account without touching compute cost.

**Hop limit 2 for IMDSv2.** Container workloads on ECS/EKS need at least 2 hops to reach the metadata service through the container runtime. `1` (the AWS default for non-containerized) would break those workloads. `2` is the right baseline.

**No tags on four of the five resources.** `aws_s3_account_public_access_block`, `aws_iam_account_password_policy`, `aws_iam_account_alias`, and `aws_ec2_instance_metadata_defaults` don't accept tags at the API level. Only the Access Analyzer carries `common_tags + extra_tags`.

**CIS 3.x alignment.** The defaults here satisfy account-level controls 1.5 (IAM Access Analyzer), 1.8–1.11 (password policy), 1.17 (support role — deferred, needs a role), 1.20 (Access Analyzer for all regions — partial: this covers one region), and the S3/EC2 account-wide hardening implied by 2.x and 5.6.

**Brownfield import.** These are all singletons, so importing pre-existing settings is trivial:

```bash
tofu import 'module.iam_baseline.aws_iam_account_password_policy.this[0]' iam-account-password-policy
tofu import 'module.iam_baseline.aws_s3_account_public_access_block.this[0]' <account_id>
tofu import 'module.iam_baseline.aws_iam_account_alias.this[0]' <existing-alias>
tofu import 'module.iam_baseline.aws_ec2_instance_metadata_defaults.this[0]' <account_id>
```

Re-apply after import produces no drift if defaults match the existing state.

## Out of scope (Phase 1)

- IAM users, groups, and roles (blueprint composition or Phase 2).
- Organization-scoped Access Analyzer and Organization trail (single-account MVP).
- Multi-region Access Analyzer or IMDSv2 fan-out (requires provider aliases).
- SCPs and IAM permission boundaries.
- AWS Config, Security Hub, GuardDuty.

Revisit in Phase 2 when client demand validates.
