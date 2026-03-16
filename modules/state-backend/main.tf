data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ─── KMS key for state encryption ─────────────────────────────────────────────

data "aws_iam_policy_document" "kms" {
  # Allow account root full KMS administration
  statement {
    sid    = "AllowRootAdministration"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    # tfsec:ignore:aws-iam-no-policy-wildcards — root admin statement required by KMS
    actions   = ["kms:*"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.allowed_roles) > 0 ? [1] : []
    content {
      sid    = "AllowAuthorizedRolesUsage"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.allowed_roles
      }
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext",
        "kms:DescribeKey",
        "kms:ReEncryptFrom",
        "kms:ReEncryptTo",
      ]
      resources = ["*"]
    }
  }
}

resource "aws_kms_key" "state" {
  description             = "KMS key for OpenTofu state encryption — ${local.name_prefix}"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms.json

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${local.name_prefix}-state-kms"
  })
}

resource "aws_kms_alias" "state" {
  name          = "alias/${local.name_prefix}-state"
  target_key_id = aws_kms_key.state.key_id
}

# ─── S3 bucket for state files ────────────────────────────────────────────────

resource "aws_s3_bucket" "state" {
  bucket        = var.bucket_name
  force_destroy = false

  tags = merge(local.common_tags, var.extra_tags, {
    Name = var.bucket_name
  })
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "noncurrent-version-management"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = var.noncurrent_version_transitions_days
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}

# ─── S3 bucket policy ─────────────────────────────────────────────────────────

data "aws_iam_policy_document" "state_bucket" {
  # Deny all HTTP access — TLS only
  statement {
    sid    = "DenyNonTLS"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Deny access to anyone outside account root and allowed_roles
  statement {
    sid    = "DenyUnauthorizedAccess"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]
    condition {
      test     = "StringNotLike"
      variable = "aws:PrincipalArn"
      values = concat(
        ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"],
        var.allowed_roles,
      )
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}
