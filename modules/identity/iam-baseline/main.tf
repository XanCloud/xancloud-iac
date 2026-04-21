data "aws_caller_identity" "current" {}

# ─── S3 account-level Block Public Access ─────────────────────────────────────

resource "aws_s3_account_public_access_block" "this" {
  count = local.do_s3_block ? 1 : 0

  block_public_acls       = var.s3_block_public_acls
  block_public_policy     = var.s3_block_public_policy
  ignore_public_acls      = var.s3_ignore_public_acls
  restrict_public_buckets = var.s3_restrict_public_buckets
}

# ─── IAM account password policy ──────────────────────────────────────────────

resource "aws_iam_account_password_policy" "this" {
  count = local.do_password_policy ? 1 : 0

  minimum_password_length        = var.password_minimum_length
  require_lowercase_characters   = var.password_require_lowercase
  require_uppercase_characters   = var.password_require_uppercase
  require_numbers                = var.password_require_numbers
  require_symbols                = var.password_require_symbols
  allow_users_to_change_password = var.password_allow_users_to_change
  max_password_age               = var.password_max_age
  password_reuse_prevention      = var.password_reuse_prevention
  hard_expiry                    = var.password_hard_expiry
}

# ─── IAM Access Analyzer (account scope, regional) ────────────────────────────

resource "aws_accessanalyzer_analyzer" "account" {
  count = local.do_access_analyzer ? 1 : 0

  analyzer_name = local.analyzer_name
  type          = var.analyzer_type

  tags = merge(local.common_tags, var.extra_tags, {
    Name = local.analyzer_name
  })
}

# ─── EC2 instance metadata defaults (IMDSv2, regional) ────────────────────────

resource "aws_ec2_instance_metadata_defaults" "this" {
  count = local.do_imdsv2_default ? 1 : 0

  http_tokens                 = var.imdsv2_http_tokens
  http_put_response_hop_limit = var.imdsv2_http_put_response_hop_limit
  http_endpoint               = var.imdsv2_http_endpoint
  instance_metadata_tags      = var.imdsv2_instance_metadata_tags
}

# ─── Account alias (opt-in) ───────────────────────────────────────────────────

resource "aws_iam_account_alias" "this" {
  count = local.do_account_alias ? 1 : 0

  account_alias = var.account_alias
}
