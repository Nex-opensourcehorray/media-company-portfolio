terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}

variable "role_name" {
  description = "Name of the delegated Terraform role created in a target account."
  type        = string
  default     = "TerraformDeploymentRole"
}

variable "trusted_principal_arns" {
  description = "IAM principal ARNs allowed to assume this role, normally from the Terraform tooling account."
  type        = set(string)

  validation {
    condition     = length(var.trusted_principal_arns) > 0
    error_message = "At least one trusted principal ARN is required."
  }
}

variable "external_id" {
  description = "Optional external ID required when assuming the role."
  type        = string
  default     = null
  nullable    = true
}

variable "max_session_duration" {
  description = "Maximum role session duration in seconds."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary applied to the deployment role."
  type        = string
  default     = null
  nullable    = true
}

variable "managed_policy_arns" {
  description = "Managed policies attached to the deployment role. Empty by default to prevent accidental broad access."
  type        = set(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Optional customer-supplied IAM policy JSON for deployment permissions."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.inline_policy_json == null || can(jsondecode(var.inline_policy_json))
    error_message = "inline_policy_json must be null or valid JSON."
  }
}

variable "state_bucket_arn" {
  description = "Optional central Terraform state bucket ARN."
  type        = string
  default     = null
  nullable    = true
}

variable "state_kms_key_arn" {
  description = "Optional KMS key ARN used by the central state bucket."
  type        = string
  default     = null
  nullable    = true
}

variable "state_key_prefixes" {
  description = "State object prefixes this account role may access."
  type        = set(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
  default     = {}
}

data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "AllowTerraformToolingAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.trusted_principal_arns
    }

    dynamic "condition" {
      for_each = var.external_id == null ? [] : [var.external_id]

      content {
        test     = "StringEquals"
        variable = "sts:ExternalId"
        values   = [condition.value]
      }
    }
  }
}

resource "aws_iam_role" "terraform" {
  name                 = var.role_name
  path                 = "/terraform/"
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = var.max_session_duration
  permissions_boundary = var.permissions_boundary_arn

  tags = merge(var.tags, {
    ManagedBy = "Terraform"
    Purpose   = "Cross-account infrastructure deployment"
  })
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = var.managed_policy_arns

  role       = aws_iam_role.terraform.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count = var.inline_policy_json == null ? 0 : 1

  name   = "terraform-deployment-inline"
  role   = aws_iam_role.terraform.id
  policy = var.inline_policy_json
}

data "aws_iam_policy_document" "state_access" {
  count = var.state_bucket_arn == null || length(var.state_key_prefixes) == 0 ? 0 : 1

  statement {
    sid     = "ListStatePrefixes"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [var.state_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [for prefix in var.state_key_prefixes : "${trimsuffix(prefix, "/")}/*"]
    }
  }

  statement {
    sid    = "ReadWriteStateAndLockfiles"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = flatten([
      for prefix in var.state_key_prefixes : [
        "${var.state_bucket_arn}/${trimsuffix(prefix, "/")}/*"
      ]
    ])
  }

  dynamic "statement" {
    for_each = var.state_kms_key_arn == null ? [] : [var.state_kms_key_arn]

    content {
      sid    = "UseStateEncryptionKey"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey"
      ]
      resources = [statement.value]
    }
  }
}

resource "aws_iam_role_policy" "state_access" {
  count = length(data.aws_iam_policy_document.state_access) == 0 ? 0 : 1

  name   = "terraform-state-access"
  role   = aws_iam_role.terraform.id
  policy = data.aws_iam_policy_document.state_access[0].json
}

output "role_arn" {
  description = "ARN of the delegated Terraform role."
  value       = aws_iam_role.terraform.arn
}

output "role_name" {
  description = "Name of the delegated Terraform role."
  value       = aws_iam_role.terraform.name
}
