output "bucket_id" {
  description = "ID (name) of the S3 state bucket"
  value       = aws_s3_bucket.state.id
}

output "bucket_arn" {
  description = "ARN of the S3 state bucket"
  value       = aws_s3_bucket.state.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for state encryption"
  value       = aws_kms_key.state.arn
}

output "kms_key_alias_arn" {
  description = "ARN of the KMS key alias"
  value       = aws_kms_alias.state.arn
}

output "backend_config" {
  description = "Backend configuration map for use in other modules' terraform blocks"
  value = {
    bucket       = aws_s3_bucket.state.id
    region       = data.aws_region.current.name
    encrypt      = true
    kms_key_id   = aws_kms_key.state.arn
    use_lockfile = true
  }
}
