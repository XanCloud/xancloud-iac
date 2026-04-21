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

variable "enabled" {
  type        = bool
  description = "Master switch. CloudTrail is baseline in Phase 1 — default true."
  default     = true
}

variable "trail_name" {
  type        = string
  description = "Override for the trail name. Defaults to <project>-<environment>-cloudtrail."
  default     = null
}

variable "s3_bucket_name" {
  type        = string
  description = "Existing S3 bucket name for log delivery. If null, the module creates its own bucket."
  default     = null
  validation {
    condition     = var.s3_bucket_name == null || can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.s3_bucket_name))
    error_message = "s3_bucket_name must be 3-63 characters, lowercase alphanumeric and hyphens, not starting or ending with a hyphen."
  }
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of an existing KMS key for SSE-KMS. If null, the module creates a dedicated key."
  default     = null
  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.kms_key_arn))
    error_message = "kms_key_arn must be a valid KMS key ARN."
  }
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

variable "is_multi_region_trail" {
  type        = bool
  description = "Capture events from every region"
  default     = true
}

variable "include_global_service_events" {
  type        = bool
  description = "Include IAM, STS, and CloudFront events"
  default     = true
}

variable "enable_log_file_validation" {
  type        = bool
  description = "Emit digest files for tamper detection"
  default     = true
}

variable "cloudwatch_logs_enabled" {
  type        = bool
  description = "Also deliver events to a CloudWatch Log Group. Opt-in — default false."
  default     = false
}

variable "cloudwatch_logs_retention_days" {
  type        = number
  description = "Retention in days for the CloudWatch Log Group"
  default     = 365
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_logs_retention_days)
    error_message = "cloudwatch_logs_retention_days must be a valid CloudWatch Logs retention value."
  }
}

variable "log_transition_to_glacier_days" {
  type        = number
  description = "Number of days before transitioning S3 logs to Glacier"
  default     = 90
  validation {
    condition     = var.log_transition_to_glacier_days >= 30
    error_message = "log_transition_to_glacier_days must be >= 30."
  }
}

variable "log_expiration_days" {
  type        = number
  description = "Number of days before S3 logs expire. CIS 3.x baseline requires >= 365."
  default     = 365
  validation {
    condition     = var.log_expiration_days >= 365
    error_message = "log_expiration_days must be >= 365 (CIS 3.x baseline)."
  }
}
