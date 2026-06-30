terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}

variable "bucket_name" {
  description = "Central Terraform state bucket name."
  type        = string
}

variable "kms_key_deletion_days" {
  type    = number
  default = 30
}

variable "allowed_account_root_arns" {
  description = "Root ARNs of accounts allowed to access state."
  type        = set(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_kms_key" "state" {
  description         = "KMS key for Terraform state encryption"
  enable_key_rotation = true

  deletion_window_in_days = var.kms_key_deletion_days

  tags = var.tags
}

resource "aws_s3_bucket" "state" {
  bucket = var.bucket_name

  tags = var.tags
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
      kms_master_key_id = aws_kms_key.state.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "state" {
  count  = length(var.allowed_account_root_arns) == 0 ? 0 : 1
  bucket = aws_s3_bucket.state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountStateAccess"
        Effect = "Allow"

        Principal = {
          AWS = var.allowed_account_root_arns
        }

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]

        Resource = [
          aws_s3_bucket.state.arn,
          "${aws_s3_bucket.state.arn}/*"
        ]
      }
    ]
  })
}

output "bucket_name" {
  value = aws_s3_bucket.state.bucket
}

output "kms_key_arn" {
  value = aws_kms_key.state.arn
}
