terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for organization CloudTrail logs."
  type        = string
}

variable "management_account_id" {
  description = "AWS Organizations management account ID that owns the organization trail."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "management_account_id must be a 12-digit AWS account ID."
  }
}

variable "organization_id" {
  description = "AWS Organizations ID, for example o-abc123xyz."
  type        = string

  validation {
    condition     = can(regex("^o-[a-z0-9]{10,32}$", var.organization_id))
    error_message = "organization_id must be a valid AWS Organizations ID."
  }
}

variable "trail_home_region" {
  description = "Home Region in which the organization trail will be created."
  type        = string
}

variable "trail_name" {
  description = "Future organization trail name used to scope the bucket and KMS policies."
  type        = string
  default     = "media-platform-organization-trail"
}

variable "log_prefix" {
  description = "Optional S3 prefix before AWSLogs."
  type        = string
  default     = "cloudtrail"
}

variable "reader_principal_arns" {
  description = "IAM principal ARNs allowed to list and read encrypted audit logs."
  type        = set(string)
  default     = []
}

variable "enable_object_lock" {
  description = "Enable S3 Object Lock. This is a bucket creation-time decision."
  type        = bool
  default     = true
}

variable "object_lock_mode" {
  description = "Default Object Lock retention mode. Use GOVERNANCE while testing; COMPLIANCE cannot be bypassed or shortened."
  type        = string
  default     = "GOVERNANCE"

  validation {
    condition     = contains(["GOVERNANCE", "COMPLIANCE"], var.object_lock_mode)
    error_message = "object_lock_mode must be GOVERNANCE or COMPLIANCE."
  }
}

variable "object_lock_retention_days" {
  description = "Default retention period applied to new log object versions."
  type        = number
  default     = 365

  validation {
    condition     = var.object_lock_retention_days >= 1
    error_message = "object_lock_retention_days must be at least 1."
  }
}

variable "transition_to_glacier_days" {
  type    = number
  default = 90
}

variable "transition_to_deep_archive_days" {
  type    = number
  default = 365
}

variable "expiration_days" {
  description = "Retention before lifecycle expiration. Object Lock retention takes precedence while active."
  type        = number
  default     = 2555
}

variable "kms_deletion_window_days" {
  type    = number
  default = 30
}

variable "force_destroy" {
  description = "Allow Terraform to delete a non-empty archive bucket. Keep false outside disposable tests."
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

locals {
  normalized_prefix = trim(var.log_prefix, "/")
  object_prefix     = local.normalized_prefix == "" ? "" : "${local.normalized_prefix}/"
  trail_arn         = "arn:${data.aws_partition.current.partition}:cloudtrail:${var.trail_home_region}:${var.management_account_id}:trail/${var.trail_name}"

  common_tags = merge(var.tags, {
    ManagedBy = "Terraform"
    Layer     = "LogArchive"
    Purpose   = "Organization audit logs"
  })
}

data "aws_iam_policy_document" "kms" {
  statement {
    sid    = "EnableLogArchiveAccountAdministration"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailEncrypt"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${var.management_account_id}:trail/*"]
    }
  }

  dynamic "statement" {
    for_each = length(var.reader_principal_arns) == 0 ? [] : [1]

    content {
      sid    = "AllowAuditReadersDecrypt"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = var.reader_principal_arns
      }

      actions   = ["kms:Decrypt", "kms:DescribeKey"]
      resources = ["*"]

      condition {
        test     = "Null"
        variable = "kms:EncryptionContext:aws:cloudtrail:arn"
        values   = ["false"]
      }
    }
  }
}

resource "aws_kms_key" "cloudtrail" {
  description             = "KMS key for organization CloudTrail log encryption"
  enable_key_rotation     = true
  deletion_window_in_days = var.kms_deletion_window_days
  policy                  = data.aws_iam_policy_document.kms.json

  tags = local.common_tags
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/media-platform-cloudtrail-logs"
  target_key_id = aws_kms_key.cloudtrail.key_id
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket              = var.bucket_name
  force_destroy       = var.force_destroy
  object_lock_enabled = var.enable_object_lock

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudtrail.arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_object_lock_configuration" "cloudtrail" {
  count = var.enable_object_lock ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    default_retention {
      mode = var.object_lock_mode
      days = var.object_lock_retention_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.cloudtrail]
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "archive-cloudtrail-logs"
    status = "Enabled"

    filter {
      prefix = local.object_prefix
    }

    transition {
      days          = var.transition_to_glacier_days
      storage_class = "GLACIER"
    }

    transition {
      days          = var.transition_to_deep_archive_days
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = var.expiration_days
    }

    noncurrent_version_transition {
      noncurrent_days = var.transition_to_glacier_days
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.expiration_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.cloudtrail]
}

data "aws_iam_policy_document" "bucket" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.cloudtrail.arn,
      "${aws_s3_bucket.cloudtrail.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AWSCloudTrailAclCheck20150319"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid    = "AWSCloudTrailManagementAccountWrite20150319"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.cloudtrail.arn}/${local.object_prefix}AWSLogs/${var.management_account_id}/*"
    ]

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
    sid    = "AWSCloudTrailOrganizationWrite20150319"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.cloudtrail.arn}/${local.object_prefix}AWSLogs/${var.organization_id}/*"
    ]

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

  dynamic "statement" {
    for_each = length(var.reader_principal_arns) == 0 ? [] : [1]

    content {
      sid    = "AllowAuditReadersList"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = var.reader_principal_arns
      }

      actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
      resources = [aws_s3_bucket.cloudtrail.arn]
    }
  }

  dynamic "statement" {
    for_each = length(var.reader_principal_arns) == 0 ? [] : [1]

    content {
      sid    = "AllowAuditReadersGetObjects"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = var.reader_principal_arns
      }

      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion"
      ]

      resources = ["${aws_s3_bucket.cloudtrail.arn}/${local.object_prefix}AWSLogs/*"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.bucket.json

  depends_on = [aws_s3_bucket_public_access_block.cloudtrail]
}

output "bucket_name" {
  value = aws_s3_bucket.cloudtrail.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.cloudtrail.arn
}

output "kms_key_arn" {
  value = aws_kms_key.cloudtrail.arn
}

output "trail_source_arn" {
  value = local.trail_arn
}

output "log_prefix" {
  value = local.normalized_prefix
}
