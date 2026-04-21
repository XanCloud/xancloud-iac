data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# ─── KMS key for CloudTrail encryption ────────────────────────────────────────

data "aws_iam_policy_document" "kms" {
  count = local.create_kms_key ? 1 : 0

  # Account root administration
  statement {
    sid    = "AllowRootAdministration"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    # tfsec:ignore:aws-iam-no-policy-wildcards — root admin statement required by KMS
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # CloudTrail encrypts logs before putting them to S3
  statement {
    sid    = "AllowCloudTrailEncrypt"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
    }
  }

  # CloudTrail describes key before use
  statement {
    sid    = "AllowCloudTrailDescribe"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:DescribeKey"]
    resources = ["*"]
  }

  # S3 decrypts objects when readers pull them through the bucket
  statement {
    sid    = "AllowS3Decrypt"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = ["*"]
  }

  # CloudWatch Logs encrypts log group contents (only when CW Logs is enabled)
  dynamic "statement" {
    for_each = var.cloudwatch_logs_enabled ? [1] : []
    content {
      sid    = "AllowCloudWatchLogs"
      effect = "Allow"
      principals {
        type        = "Service"
        identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
      }
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*",
      ]
      resources = ["*"]
      condition {
        test     = "ArnLike"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values   = [local.log_group_arn]
      }
    }
  }
}

resource "aws_kms_key" "trail" {
  count = local.create_kms_key ? 1 : 0

  description             = "KMS key for CloudTrail logs — ${local.name_prefix}"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms[0].json

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${local.name_prefix}-cloudtrail-kms"
  })
}

resource "aws_kms_alias" "trail" {
  count = local.create_kms_key ? 1 : 0

  name          = "alias/${local.name_prefix}-cloudtrail"
  target_key_id = aws_kms_key.trail[0].key_id
}

# ─── S3 bucket for trail logs ─────────────────────────────────────────────────

resource "aws_s3_bucket" "trail" {
  count = local.create_bucket ? 1 : 0

  bucket        = local.bucket_name
  force_destroy = false

  tags = merge(local.common_tags, var.extra_tags, {
    Name = local.bucket_name
  })
}

resource "aws_s3_bucket_versioning" "trail" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.trail[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.trail[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = local.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "trail" {
  count = local.create_bucket ? 1 : 0

  bucket                  = aws_s3_bucket.trail[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "trail" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.trail[0].id

  rule {
    id     = "log-retention"
    status = "Enabled"

    filter {}

    transition {
      days          = var.log_transition_to_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.log_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.log_expiration_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.trail]
}

# ─── S3 bucket policy ─────────────────────────────────────────────────────────

data "aws_iam_policy_document" "bucket" {
  count = local.create_bucket ? 1 : 0

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.trail[0].arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.trail[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid    = "DenyNonTLS"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.trail[0].arn, "${aws_s3_bucket.trail[0].arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "DenyUnencryptedObjectUploads"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.trail[0].arn}/*"]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }
}

resource "aws_s3_bucket_policy" "trail" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.trail[0].id
  policy = data.aws_iam_policy_document.bucket[0].json

  depends_on = [aws_s3_bucket_public_access_block.trail]
}

# ─── CloudWatch Logs delivery (opt-in) ────────────────────────────────────────

resource "aws_cloudwatch_log_group" "trail" {
  count = var.enabled && var.cloudwatch_logs_enabled ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.cloudwatch_logs_retention_days
  kms_key_id        = local.kms_key_arn

  tags = merge(local.common_tags, var.extra_tags, {
    Name = local.log_group_name
  })
}

data "aws_iam_policy_document" "cw_assume_role" {
  count = var.enabled && var.cloudwatch_logs_enabled ? 1 : 0

  statement {
    sid     = "AllowCloudTrailAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cw_permissions" {
  count = var.enabled && var.cloudwatch_logs_enabled ? 1 : 0

  statement {
    sid    = "AllowCloudTrailWriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.trail[0].arn}:*"]
  }
}

resource "aws_iam_role" "cloudwatch_delivery" {
  count = var.enabled && var.cloudwatch_logs_enabled ? 1 : 0

  name               = "${local.name_prefix}-cloudtrail-cw-role"
  assume_role_policy = data.aws_iam_policy_document.cw_assume_role[0].json

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${local.name_prefix}-cloudtrail-cw-role"
  })
}

resource "aws_iam_role_policy" "cloudwatch_delivery" {
  count = var.enabled && var.cloudwatch_logs_enabled ? 1 : 0

  name   = "${local.name_prefix}-cloudtrail-cw-policy"
  role   = aws_iam_role.cloudwatch_delivery[0].id
  policy = data.aws_iam_policy_document.cw_permissions[0].json
}

# ─── The trail ────────────────────────────────────────────────────────────────

resource "aws_cloudtrail" "this" {
  count = var.enabled ? 1 : 0

  name                          = local.trail_name
  s3_bucket_name                = local.bucket_name
  kms_key_id                    = local.kms_key_arn
  is_multi_region_trail         = var.is_multi_region_trail
  include_global_service_events = var.include_global_service_events
  enable_log_file_validation    = var.enable_log_file_validation
  enable_logging                = true

  cloud_watch_logs_group_arn = var.cloudwatch_logs_enabled ? "${aws_cloudwatch_log_group.trail[0].arn}:*" : null
  cloud_watch_logs_role_arn  = var.cloudwatch_logs_enabled ? aws_iam_role.cloudwatch_delivery[0].arn : null

  tags = merge(local.common_tags, var.extra_tags, {
    Name = local.trail_name
  })

  depends_on = [aws_s3_bucket_policy.trail]
}
