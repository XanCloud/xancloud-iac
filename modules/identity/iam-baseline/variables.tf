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

# ─── Master switch ────────────────────────────────────────────────────────────

variable "enabled" {
  type        = bool
  description = "Master switch. IAM baseline hardening is baseline in Phase 1 — default true."
  default     = true
}

# ─── Feature toggles ──────────────────────────────────────────────────────────

variable "enable_s3_account_public_access_block" {
  type        = bool
  description = "Manage the account-level S3 Block Public Access settings"
  default     = true
}

variable "enable_password_policy" {
  type        = bool
  description = "Manage the IAM account password policy"
  default     = true
}

variable "enable_access_analyzer" {
  type        = bool
  description = "Create an IAM Access Analyzer in the configured region"
  default     = true
}

variable "enable_imdsv2_default" {
  type        = bool
  description = "Manage regional EC2 instance metadata defaults (IMDSv2 enforcement)"
  default     = true
}

# ─── S3 account-level Block Public Access overrides ───────────────────────────

variable "s3_block_public_acls" {
  type        = bool
  description = "Block new public ACLs on buckets and objects in the account"
  default     = true
}

variable "s3_block_public_policy" {
  type        = bool
  description = "Block new public bucket policies in the account"
  default     = true
}

variable "s3_ignore_public_acls" {
  type        = bool
  description = "Ignore public ACLs on buckets and objects in the account"
  default     = true
}

variable "s3_restrict_public_buckets" {
  type        = bool
  description = "Restrict access to buckets with public policies in the account"
  default     = true
}

# ─── Password policy (CIS 3.x defaults) ───────────────────────────────────────

variable "password_minimum_length" {
  type        = number
  description = "Minimum password length"
  default     = 14
  validation {
    condition     = var.password_minimum_length >= 8 && var.password_minimum_length <= 128
    error_message = "password_minimum_length must be between 8 and 128."
  }
}

variable "password_require_lowercase" {
  type        = bool
  description = "Require at least one lowercase character"
  default     = true
}

variable "password_require_uppercase" {
  type        = bool
  description = "Require at least one uppercase character"
  default     = true
}

variable "password_require_numbers" {
  type        = bool
  description = "Require at least one number"
  default     = true
}

variable "password_require_symbols" {
  type        = bool
  description = "Require at least one symbol"
  default     = true
}

variable "password_allow_users_to_change" {
  type        = bool
  description = "Allow IAM users to change their own password"
  default     = true
}

variable "password_max_age" {
  type        = number
  description = "Maximum password age in days before rotation is required"
  default     = 90
  validation {
    condition     = var.password_max_age >= 1 && var.password_max_age <= 1095
    error_message = "password_max_age must be between 1 and 1095 days."
  }
}

variable "password_reuse_prevention" {
  type        = number
  description = "Number of previous passwords that cannot be reused"
  default     = 24
  validation {
    condition     = var.password_reuse_prevention >= 1 && var.password_reuse_prevention <= 24
    error_message = "password_reuse_prevention must be between 1 and 24."
  }
}

variable "password_hard_expiry" {
  type        = bool
  description = "Block users from resetting their own password after it expires"
  default     = false
}

# ─── IAM Access Analyzer ──────────────────────────────────────────────────────

variable "analyzer_name" {
  type        = string
  description = "Override for the analyzer name. Defaults to <project>-<environment>-account-analyzer."
  default     = null
  validation {
    condition     = var.analyzer_name == null || can(regex("^[A-Za-z0-9_.-]{1,255}$", var.analyzer_name))
    error_message = "analyzer_name must be 1-255 chars, alphanumeric, dot, underscore, or hyphen."
  }
}

variable "analyzer_type" {
  type        = string
  description = "Analyzer type. Organization-scoped types are rejected — this is a single-account module."
  default     = "ACCOUNT"
  validation {
    condition     = contains(["ACCOUNT", "ACCOUNT_UNUSED_ACCESS", "ACCOUNT_INTERNAL_ACCESS"], var.analyzer_type)
    error_message = "analyzer_type must be ACCOUNT, ACCOUNT_UNUSED_ACCESS, or ACCOUNT_INTERNAL_ACCESS."
  }
}

# ─── IMDSv2 regional defaults ─────────────────────────────────────────────────

variable "imdsv2_http_tokens" {
  type        = string
  description = "Whether IMDSv2 session tokens are required. `required` enforces IMDSv2."
  default     = "required"
  validation {
    condition     = contains(["required", "optional", "no-preference"], var.imdsv2_http_tokens)
    error_message = "imdsv2_http_tokens must be required, optional, or no-preference."
  }
}

variable "imdsv2_http_put_response_hop_limit" {
  type        = number
  description = "IMDS response hop limit. 2 is the baseline for container workloads (ECS/EKS)."
  default     = 2
  validation {
    condition     = var.imdsv2_http_put_response_hop_limit >= 1 && var.imdsv2_http_put_response_hop_limit <= 64
    error_message = "imdsv2_http_put_response_hop_limit must be between 1 and 64."
  }
}

variable "imdsv2_http_endpoint" {
  type        = string
  description = "Whether the instance metadata endpoint is enabled"
  default     = "enabled"
  validation {
    condition     = contains(["enabled", "disabled", "no-preference"], var.imdsv2_http_endpoint)
    error_message = "imdsv2_http_endpoint must be enabled, disabled, or no-preference."
  }
}

variable "imdsv2_instance_metadata_tags" {
  type        = string
  description = "Whether instance tags are accessible from the metadata endpoint"
  default     = "enabled"
  validation {
    condition     = contains(["enabled", "disabled", "no-preference"], var.imdsv2_instance_metadata_tags)
    error_message = "imdsv2_instance_metadata_tags must be enabled, disabled, or no-preference."
  }
}

# ─── Account alias ────────────────────────────────────────────────────────────

variable "account_alias" {
  type        = string
  description = "Account alias. Null means the module leaves any existing alias alone."
  default     = null
  validation {
    condition     = var.account_alias == null || can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.account_alias))
    error_message = "account_alias must be 3-63 chars, lowercase alphanumeric and hyphens, not starting or ending with a hyphen."
  }
}
