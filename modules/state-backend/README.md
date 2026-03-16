# State Backend

S3 bucket + KMS key for OpenTofu remote state. Bootstrap-first: apply with local state, then migrate.

Native S3 locking via `use_lockfile = true` — no DynamoDB needed.

## Usage

### Bootstrap (first apply)

```hcl
# No backend block — local state for bootstrap
module "state_backend" {
  source = "../../modules/state-backend"

  environment = "dev"
  project     = "xancloud"
  owner       = "platform-team"
  cost_center = "CC-001"
  bucket_name = "xancloud-dev-tfstate"

  allowed_roles = [
    "arn:aws:iam::123456789012:role/TerraformAdmin",
  ]
}
```

### Backend config in other modules (after migration)

```hcl
terraform {
  backend "s3" {
    bucket       = "xancloud-dev-tfstate"
    key          = "networking/vpc/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    kms_key_id   = "arn:aws:kms:us-east-1:123456789012:key/<key-id>"
    use_lockfile = true
  }
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
| `bucket_name` | `string` | — | S3 bucket name (3-63 chars, lowercase alphanumeric + hyphens) |
| `allowed_roles` | `list(string)` | `[]` | IAM role ARNs authorized to access state. Empty = root only. |
| `enable_replication` | `bool` | `false` | Enable cross-region S3 replication |
| `replication_region` | `string` | `null` | Destination region for replication (required if enabled) |
| `kms_deletion_window` | `number` | `30` | Days before KMS key deletion (7–30) |
| `noncurrent_version_transitions_days` | `number` | `90` | Days before moving old versions to Glacier |
| `noncurrent_version_expiration_days` | `number` | `365` | Days before deleting old versions |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | S3 bucket name |
| `bucket_arn` | S3 bucket ARN |
| `kms_key_arn` | KMS key ARN |
| `kms_key_alias_arn` | KMS key alias ARN |
| `backend_config` | Map with all backend configuration values |

## Bootstrap process

1. Apply with local state — no `backend` block:
   ```bash
   tofu init && tofu apply
   ```

2. Add `backend "s3"` block to your root module using the `backend_config` output values.

3. Migrate local state to S3:
   ```bash
   tofu init -migrate-state
   ```

4. Confirm the migration when prompted. Local `terraform.tfstate` is now stale — safe to delete.

## Notes

- State locking uses native S3 (`use_lockfile = true`). No DynamoDB required. Requires OpenTofu >= 1.10.
- Cross-region replication is disabled by default. When enabled, a second AWS provider aliased `replication` must be configured in the calling module.
- `force_destroy = false` — bucket deletion is protected. Remove state files manually before destroying.
- KMS key rotation is enabled by default (annual). Existing state files remain readable after rotation.
