data "aws_caller_identity" "current" {}

# ─── Networking ───────────────────────────────────────────────────────────────

module "vpc" {
  source = "../../modules/networking/vpc"

  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  extra_tags  = var.extra_tags

  vpcs = var.vpcs
}

# ─── Audit trail ──────────────────────────────────────────────────────────────

module "cloudtrail" {
  source = "../../modules/security/cloudtrail"

  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  extra_tags  = var.extra_tags

  enabled                        = var.cloudtrail_enabled
  is_multi_region_trail          = var.cloudtrail_multi_region
  cloudwatch_logs_enabled        = var.cloudtrail_cloudwatch_logs_enabled
  cloudwatch_logs_retention_days = var.cloudtrail_log_retention_days
  log_expiration_days            = var.cloudtrail_log_expiration_days
}

# ─── IAM baseline (account-level, singleton via is_account_owner) ─────────────

module "iam_baseline" {
  source = "../../modules/identity/iam-baseline"

  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  extra_tags  = var.extra_tags

  enabled = var.is_account_owner

  enable_s3_account_public_access_block = var.iam_baseline_enable_s3_block
  enable_password_policy                = var.iam_baseline_enable_password_policy
  enable_access_analyzer                = var.iam_baseline_enable_access_analyzer
  enable_imdsv2_default                 = var.iam_baseline_enable_imdsv2_default

  account_alias = var.account_alias
}
