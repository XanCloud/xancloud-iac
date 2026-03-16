# ─── Common variables (required in all modules) ───────────────────────────────

variable "environment" {
  type        = string
  description = "Deployment environment"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project" {
  type        = string
  description = "Project name used in resource naming and tags"
  default     = "xancloud"
}

variable "owner" {
  type        = string
  description = "Team or individual responsible for the resources"
  default     = "platform-team"
}

variable "cost_center" {
  type        = string
  description = "Cost center for billing attribution"
  default     = "CC-001"
}

variable "extra_tags" {
  type        = map(string)
  description = "Additional tags to merge with common tags"
  default     = {}
}

# ─── Module-specific variables ────────────────────────────────────────────────

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket for OpenTofu state files"
  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be 3-63 characters, lowercase alphanumeric and hyphens only, and cannot start or end with a hyphen."
  }
}

variable "allowed_roles" {
  type        = list(string)
  description = "ARNs of IAM roles authorized to access the state bucket and KMS key. If empty, only the account root has access."
  default     = []
}

variable "enable_replication" {
  type        = bool
  description = "Enable cross-region S3 replication for the state bucket"
  default     = false
}

variable "replication_region" {
  type        = string
  description = "Destination AWS region for cross-region replication. Required when enable_replication is true."
  default     = null
}

variable "kms_deletion_window" {
  type        = number
  description = "Number of days to wait before deleting the KMS key after it is scheduled for deletion"
  default     = 30
  validation {
    condition     = var.kms_deletion_window >= 7 && var.kms_deletion_window <= 30
    error_message = "kms_deletion_window must be between 7 and 30 days."
  }
}

variable "noncurrent_version_transitions_days" {
  type        = number
  description = "Number of days before transitioning noncurrent S3 object versions to Glacier"
  default     = 90
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Number of days before expiring noncurrent S3 object versions permanently"
  default     = 365
}
