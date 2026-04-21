output "account_id" {
  description = "AWS account ID where the landing zone was deployed"
  value       = data.aws_caller_identity.current.account_id
}

# ─── VPC ──────────────────────────────────────────────────────────────────────

output "vpcs" {
  description = "Map of VPC info (id, cidr_block) keyed by VPC name"
  value       = module.vpc.vpcs
}

output "vpc_ids" {
  description = "Map of VPC IDs keyed by VPC name"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids_by_vpc" {
  description = "Public subnet IDs grouped by VPC name"
  value       = module.vpc.public_subnet_ids_by_vpc
}

output "private_subnet_ids_by_vpc" {
  description = "Private subnet IDs grouped by VPC name"
  value       = module.vpc.private_subnet_ids_by_vpc
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs keyed by VPC name"
  value       = module.vpc.nat_gateway_ids
}

# ─── CloudTrail ───────────────────────────────────────────────────────────────

output "cloudtrail_arn" {
  description = "ARN of the account CloudTrail. Null when disabled."
  value       = module.cloudtrail.trail_arn
}

output "cloudtrail_s3_bucket_id" {
  description = "S3 bucket storing trail logs. Null when disabled."
  value       = module.cloudtrail.s3_bucket_id
}

output "cloudtrail_kms_key_arn" {
  description = "KMS key ARN encrypting the trail. Null when disabled."
  value       = module.cloudtrail.kms_key_arn
}

# ─── IAM baseline ─────────────────────────────────────────────────────────────

output "iam_access_analyzer_arn" {
  description = "ARN of the IAM Access Analyzer. Null when this environment is not the account owner."
  value       = module.iam_baseline.access_analyzer_arn
}

output "account_alias" {
  description = "Account alias managed by this module. Null when not owner or unset."
  value       = module.iam_baseline.account_alias
}
