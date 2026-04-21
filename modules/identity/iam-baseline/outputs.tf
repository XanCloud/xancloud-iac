output "account_id" {
  description = "AWS account ID this module applied to"
  value       = data.aws_caller_identity.current.account_id
}

output "account_alias" {
  description = "Account alias managed by this module. Null when not set."
  value       = try(aws_iam_account_alias.this[0].account_alias, null)
}

output "access_analyzer_arn" {
  description = "ARN of the account-scope IAM Access Analyzer. Null when disabled."
  value       = try(aws_accessanalyzer_analyzer.account[0].arn, null)
}

output "access_analyzer_id" {
  description = "ID of the IAM Access Analyzer. Null when disabled."
  value       = try(aws_accessanalyzer_analyzer.account[0].id, null)
}

output "access_analyzer_name" {
  description = "Name of the IAM Access Analyzer. Null when disabled."
  value       = try(aws_accessanalyzer_analyzer.account[0].analyzer_name, null)
}

output "password_policy_applied" {
  description = "True when the account password policy was managed by this module."
  value       = local.do_password_policy
}

output "s3_public_access_block_applied" {
  description = "True when the account-level S3 Block Public Access was managed by this module."
  value       = local.do_s3_block
}

output "imdsv2_default_applied" {
  description = "True when regional EC2 instance metadata defaults were managed by this module."
  value       = local.do_imdsv2_default
}
