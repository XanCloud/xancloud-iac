output "trail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = try(aws_cloudtrail.this[0].arn, null)
}

output "trail_name" {
  description = "Name of the CloudTrail trail"
  value       = try(aws_cloudtrail.this[0].name, null)
}

output "s3_bucket_id" {
  description = "Name of the S3 bucket receiving trail logs (created or external)"
  value       = var.enabled ? local.bucket_name : null
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket receiving trail logs"
  value       = var.enabled ? local.bucket_arn : null
}

output "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt trail logs"
  value       = var.enabled ? local.kms_key_arn : null
}

output "kms_key_alias_arn" {
  description = "ARN of the KMS key alias. Null when an external key is provided."
  value       = try(aws_kms_alias.trail[0].arn, null)
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group receiving trail events. Null when CW Logs is disabled."
  value       = try(aws_cloudwatch_log_group.trail[0].arn, null)
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group. Null when CW Logs is disabled."
  value       = try(aws_cloudwatch_log_group.trail[0].name, null)
}
