locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    ManagedBy   = "opentofu"
    CostCenter  = var.cost_center
  }
  name_prefix = "${var.project}-${var.environment}"

  analyzer_name = coalesce(var.analyzer_name, "${local.name_prefix}-account-analyzer")

  do_s3_block        = var.enabled && var.enable_s3_account_public_access_block
  do_password_policy = var.enabled && var.enable_password_policy
  do_access_analyzer = var.enabled && var.enable_access_analyzer
  do_imdsv2_default  = var.enabled && var.enable_imdsv2_default
  do_account_alias   = var.enabled && var.account_alias != null
}
