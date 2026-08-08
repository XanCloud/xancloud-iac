locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    ManagedBy   = "opentofu"
    CostCenter  = var.cost_center
  }
  name_prefix = "${var.project}-${var.environment}"
  trail_name  = coalesce(var.trail_name, "${local.name_prefix}-cloudtrail")

  create_bucket  = var.enabled && var.s3_bucket_name == null
  create_kms_key = var.enabled && var.kms_key_arn == null

  bucket_name    = coalesce(var.s3_bucket_name, "${local.name_prefix}-cloudtrail-${data.aws_caller_identity.current.account_id}")
  bucket_arn     = local.create_bucket ? aws_s3_bucket.trail[0].arn : "arn:${data.aws_partition.current.partition}:s3:::${local.bucket_name}"
  kms_key_arn    = local.create_kms_key ? aws_kms_key.trail[0].arn : var.kms_key_arn
  log_group_name = "/aws/cloudtrail/${local.name_prefix}"
  trail_arn      = "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${local.trail_name}"
  log_group_arn  = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group_name}"
}
