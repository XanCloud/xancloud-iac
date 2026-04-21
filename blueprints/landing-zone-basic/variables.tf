# ─── Core / common ────────────────────────────────────────────────────────────

variable "region" {
  type        = string
  description = "AWS region where the blueprint is deployed"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d$", var.region))
    error_message = "region must be a valid AWS region identifier (e.g. us-east-1)."
  }
}

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
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project))
    error_message = "project must be lowercase, 2-21 chars, start with a letter, alphanumeric and hyphens."
  }
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
  description = "Additional tags merged with common tags"
  default     = {}
}

# ─── VPC ──────────────────────────────────────────────────────────────────────

variable "vpcs" {
  type = map(object({
    cidr                  = string
    azs                   = number
    single_nat            = bool
    vpc_endpoints         = list(string)
    flow_logs_destination = string
  }))
  description = "Map of VPCs to create. Key is the VPC logical name. See modules/networking/vpc for field semantics."
}

# ─── IAM baseline (account-level singleton) ───────────────────────────────────

variable "is_account_owner" {
  type        = bool
  description = "Set to true in EXACTLY ONE environment per AWS account. When true, this root manages account-level hardening (password policy, S3 BPA, IMDSv2 defaults, account alias). Two owners in the same account will collide."
  default     = false
}

variable "account_alias" {
  type        = string
  description = "Account alias. Only applied when is_account_owner = true. Null leaves any existing alias alone."
  default     = null
}

variable "iam_baseline_enable_s3_block" {
  type        = bool
  description = "Manage account-level S3 Block Public Access (requires is_account_owner = true)"
  default     = true
}

variable "iam_baseline_enable_password_policy" {
  type        = bool
  description = "Manage the IAM account password policy (requires is_account_owner = true)"
  default     = true
}

variable "iam_baseline_enable_access_analyzer" {
  type        = bool
  description = "Create an IAM Access Analyzer (requires is_account_owner = true)"
  default     = true
}

variable "iam_baseline_enable_imdsv2_default" {
  type        = bool
  description = "Manage regional EC2 instance metadata defaults (requires is_account_owner = true)"
  default     = true
}

# ─── CloudTrail ───────────────────────────────────────────────────────────────

variable "cloudtrail_enabled" {
  type        = bool
  description = "Master switch for the CloudTrail module"
  default     = true
}

variable "cloudtrail_multi_region" {
  type        = bool
  description = "Capture events from every region"
  default     = true
}

variable "cloudtrail_cloudwatch_logs_enabled" {
  type        = bool
  description = "Also deliver trail events to a CloudWatch Log Group"
  default     = false
}

variable "cloudtrail_log_retention_days" {
  type        = number
  description = "Retention in days for the CloudWatch Log Group"
  default     = 365
}

variable "cloudtrail_log_expiration_days" {
  type        = number
  description = "Days before S3 trail logs expire. CIS 3.x baseline requires >= 365."
  default     = 365
}
