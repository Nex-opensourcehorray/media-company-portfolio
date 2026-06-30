data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Project      = var.project_name
    Environment  = var.environment
    ManagedBy    = "Terraform"
    Architecture = "F3-VOD-Processing"
  })

  effective_kms_key_arn = var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.vod[0].arn
  ingest_bucket_name    = "${local.name_prefix}-${data.aws_caller_identity.current.account_id}-vod-ingest"
  output_bucket_name    = "${local.name_prefix}-${data.aws_caller_identity.current.account_id}-vod-output"
}

resource "aws_kms_key" "vod" {
  count = var.kms_key_arn == null ? 1 : 0

  description             = "KMS key for ${local.name_prefix} F3 VOD S3 data"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true

  tags = local.common_tags
}

resource "aws_kms_alias" "vod" {
  count = var.kms_key_arn == null ? 1 : 0

  name          = "alias/${local.name_prefix}-vod"
  target_key_id = aws_kms_key.vod[0].key_id
}

resource "aws_s3_bucket" "ingest" {
  bucket        = local.ingest_bucket_name
  force_destroy = var.force_destroy_buckets

  tags = merge(local.common_tags, {
    Name        = local.ingest_bucket_name
    DataPurpose = "VOD source ingest"
  })
}

resource "aws_s3_bucket" "output" {
  bucket        = local.output_bucket_name
  force_destroy = var.force_destroy_buckets

  tags = merge(local.common_tags, {
    Name        = local.output_bucket_name
    DataPurpose = "VOD transcoded output"
  })
}

resource "aws_s3_bucket_ownership_controls" "ingest" {
  bucket = aws_s3_bucket.ingest.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_ownership_controls" "output" {
  bucket = aws_s3_bucket.output.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "ingest" {
  bucket = aws_s3_bucket.ingest.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "output" {
  bucket = aws_s3_bucket.output.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "ingest" {
  bucket = aws_s3_bucket.ingest.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "output" {
  bucket = aws_s3_bucket.output.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ingest" {
  bucket = aws_s3_bucket.ingest.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      kms_master_key_id = local.effective_kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "output" {
  bucket = aws_s3_bucket.output.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      kms_master_key_id = local.effective_kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ingest" {
  bucket = aws_s3_bucket.ingest.id

  rule {
    id     = "ingest-housekeeping"
    status = "Enabled"

    filter {
      prefix = var.ingest_prefix
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    dynamic "expiration" {
      for_each = var.ingest_expiration_days == null ? [] : [var.ingest_expiration_days]

      content {
        days = expiration.value
      }
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  depends_on = [aws_s3_bucket_versioning.ingest]
}

resource "aws_s3_bucket_lifecycle_configuration" "output" {
  bucket = aws_s3_bucket.output.id

  rule {
    id     = "output-tiering"
    status = "Enabled"

    filter {
      prefix = var.output_prefix
    }

    transition {
      days          = var.output_transition_days
      storage_class = "INTELLIGENT_TIERING"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  depends_on = [aws_s3_bucket_versioning.output]
}

data "aws_iam_policy_document" "ingest_bucket" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.ingest.arn,
      "${aws_s3_bucket.ingest.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "output_bucket" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.output.arn,
      "${aws_s3_bucket.output.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "ingest" {
  bucket = aws_s3_bucket.ingest.id
  policy = data.aws_iam_policy_document.ingest_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.ingest]
}

resource "aws_s3_bucket_policy" "output" {
  bucket = aws_s3_bucket.output.id
  policy = data.aws_iam_policy_document.output_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.output]
}

resource "aws_s3_bucket_notification" "ingest" {
  bucket      = aws_s3_bucket.ingest.id
  eventbridge = true
}

resource "aws_sqs_queue" "event_delivery_dlq" {
  name                      = "${local.name_prefix}-vod-event-delivery-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true

  tags = local.common_tags
}

resource "aws_sqs_queue" "workflow_failures" {
  name                       = "${local.name_prefix}-vod-workflow-failures"
  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 300
  sqs_managed_sse_enabled    = true

  tags = local.common_tags
}

resource "aws_media_convert_queue" "vod" {
  name            = "${local.name_prefix}-vod"
  description     = "On-demand MediaConvert queue for ${local.name_prefix} VOD processing"
  pricing_plan    = "ON_DEMAND"
  status          = "ACTIVE"
  concurrent_jobs = var.media_convert_concurrent_jobs

  tags = local.common_tags
}
