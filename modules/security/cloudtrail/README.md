# CloudTrail

Multi-region account trail with log file validation, dedicated S3 bucket + KMS key, and optional CloudWatch Logs delivery.

Single-account MVP. Organization trail, data events, and insight events are out of scope.

## Usage

### Minimal

```hcl
module "cloudtrail" {
  source = "../../modules/security/cloudtrail"

  environment = "dev"
  project     = "xancloud"
  owner       = "platform-team"
  cost_center = "CC-001"
}
```

This creates:

- Dedicated KMS key (`alias/xancloud-dev-cloudtrail`), rotation enabled.
- S3 bucket `xancloud-dev-cloudtrail-<account_id>`, versioning + SSE-KMS + public access block.
- Lifecycle: 90 days → Glacier, 365 days → expiration.
- CloudTrail `xancloud-dev-cloudtrail`, multi-region, log file validation on.

### With CloudWatch Logs delivery

```hcl
module "cloudtrail" {
  source = "../../modules/security/cloudtrail"

  environment = "prod"
  project     = "xancloud"
  owner       = "platform-team"
  cost_center = "CC-001"

  cloudwatch_logs_enabled        = true
  cloudwatch_logs_retention_days = 731
}
```

Adds a KMS-encrypted Log Group plus the IAM role CloudTrail assumes to write events.

### Bring your own bucket and KMS key

```hcl
module "cloudtrail" {
  source = "../../modules/security/cloudtrail"

  environment = "prod"
  project     = "xancloud"
  owner       = "platform-team"
  cost_center = "CC-001"

  s3_bucket_name = "central-audit-logs"
  kms_key_arn    = "arn:aws:kms:us-east-1:111111111111:key/abc-123"
}
```

The module only creates the trail (and optional CW Logs plumbing). Bucket policy and KMS key policy must already allow CloudTrail.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `environment` | `string` | — | Deployment environment (`dev`, `staging`, `prod`) |
| `project` | `string` | `"xancloud"` | Project name for naming and tags |
| `owner` | `string` | `"platform-team"` | Responsible team or individual |
| `cost_center` | `string` | `"CC-001"` | Cost center for billing attribution |
| `extra_tags` | `map(string)` | `{}` | Additional tags merged with common tags |
| `enabled` | `bool` | `true` | Master switch for the module |
| `trail_name` | `string` | `null` | Override for the trail name |
| `s3_bucket_name` | `string` | `null` | Existing bucket name. If null, module creates one. |
| `kms_key_arn` | `string` | `null` | Existing KMS key ARN. If null, module creates one. |
| `kms_deletion_window` | `number` | `30` | Days before KMS key deletion (7–30) |
| `is_multi_region_trail` | `bool` | `true` | Capture events from every region |
| `include_global_service_events` | `bool` | `true` | Include IAM, STS, CloudFront events |
| `enable_log_file_validation` | `bool` | `true` | Emit digest files for tamper detection |
| `cloudwatch_logs_enabled` | `bool` | `false` | Deliver events to a CloudWatch Log Group |
| `cloudwatch_logs_retention_days` | `number` | `365` | Retention for the Log Group |
| `log_transition_to_glacier_days` | `number` | `90` | Days before moving S3 logs to Glacier |
| `log_expiration_days` | `number` | `365` | Days before S3 logs expire (>= 365, CIS baseline) |

## Outputs

| Name | Description |
|------|-------------|
| `trail_arn` | ARN of the CloudTrail trail |
| `trail_name` | Name of the trail |
| `s3_bucket_id` | Name of the bucket used (created or external) |
| `s3_bucket_arn` | ARN of the bucket |
| `kms_key_arn` | ARN of the KMS key used |
| `kms_key_alias_arn` | Alias ARN (null when external key) |
| `cloudwatch_log_group_arn` | Log Group ARN (null when disabled) |
| `cloudwatch_log_group_name` | Log Group name (null when disabled) |

## Design notes

**Multi-region on by default.** A single-region trail misses IAM, STS, and CloudFront (all global), plus any cross-region activity. Multi-region is the baseline for a production-credible trail.

**Log file validation on by default.** It's free and gives digest files that detect tampering after the fact. Baseline for CIS 3.x.

**CloudWatch Logs opt-in.** Shipping events to CW Logs roughly doubles ingestion cost and is only useful once you wire alarms or subscription filters. Off by default — flip the switch when you need it.

**365 day retention.** CIS 3.x requires at least 1 year. Clients with SOC2 or PCI mandates should bump `log_expiration_days` and `cloudwatch_logs_retention_days` to `2557` (7 years).

**Management events only.** Data events (S3 object-level, Lambda invoke) cost by the event and flood the trail. Out of scope for Phase 1.

## Out of scope (Phase 1)

- Organization trail (single-account MVP).
- Data events and insight events.
- Cross-account log delivery.
- CloudTrail Lake.

Revisit in Phase 2 when client demand validates.
