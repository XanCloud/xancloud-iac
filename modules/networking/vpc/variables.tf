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
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project))
    error_message = "Project must be lowercase alphanumeric with hyphens, 2-21 chars."
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
  description = "Additional tags to merge with common tags"
  default     = {}
}

# ─── VPC configuration ─────────────────────────────────────────────────────────

variable "vpcs" {
  description = "Map of VPC configurations to create"
  type = map(object({
    cidr                  = string
    azs                   = number
    single_nat            = bool
    vpc_endpoints         = list(string)
    flow_logs_destination = string
  }))

  validation {
    condition = alltrue([
      for vpc_key, vpc in var.vpcs : can(regex("^[a-z][a-z0-9-]{1,20}$", vpc_key))
    ])
    error_message = "VPC keys must be lowercase alphanumeric with hyphens, 2-21 chars."
  }

  validation {
    condition = alltrue([
      for vpc in var.vpcs : can(regex("^10\\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\\.(0|1[6-9]|2[0-4][0-9])\\/(1[6-9]|2[0-9]|3[0-2])$", vpc.cidr))
    ])
    error_message = "CIDR must be 10.x.x.x/16 to /32 (RFC 1918 10.0.0.0/8 range)."
  }

  validation {
    condition = alltrue([
      for vpc in var.vpcs : contains([2, 3], vpc.azs)
    ])
    error_message = "Number of AZs must be 2 or 3."
  }

  validation {
    condition = alltrue([
      for vpc in var.vpcs : contains(["cloudwatch", "s3"], vpc.flow_logs_destination)
    ])
    error_message = "Flow logs destination must be cloudwatch or s3."
  }

  validation {
    condition = alltrue([
      for vpc in var.vpcs : alltrue([
        for ep in vpc.vpc_endpoints : contains(["s3", "dynamodb", "ssm", "ecr.api", "ecr.dkr", "logs", "cloudwatchlogs", "secretsmanager", "ssmmessages", "ssmcontacts"], ep)
      ])
    ])
    error_message = "VPC endpoints must be valid AWS service names (s3, dynamodb, ssm, ecr.api, ecr.dkr, logs, cloudwatchlogs, secretsmanager, ssmmessages, ssmcontacts)."
  }
}
