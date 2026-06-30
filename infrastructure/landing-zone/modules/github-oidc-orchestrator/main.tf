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

variable "role_name" {
  description = "Name of the GitHub Actions orchestration role."
  type        = string
  default     = "GitHubTerraformOrchestratorRole"
}

variable "github_subject_claims" {
  description = "Exact GitHub OIDC sub claims allowed to assume this role."
  type        = set(string)

  validation {
    condition     = length(var.github_subject_claims) > 0
    error_message = "At least one exact GitHub OIDC subject claim is required."
  }
}

variable "github_oidc_thumbprints" {
  description = "OIDC certificate thumbprints retained for compatibility. AWS validates GitHub using its trusted CA library."
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

variable "state_bucket_arn" {
  description = "ARN of the centralized Terraform state bucket."
  type        = string
}

variable "state_kms_key_arn" {
  description = "ARN of the KMS key encrypting Terraform state."
  type        = string
}

variable "state_key_prefixes" {
  description = "Only these state prefixes may be listed, read, written, and locked by CI."
  type        = set(string)

  validation {
    condition     = length(var.state_key_prefixes) > 0
    error_message = "At least one Terraform state prefix is required."
  }
}

variable "target_role_arns" {
  description = "Explicit delegated destination role ARNs that CI may assume."
  type        = set(string)

  validation {
    condition     = length(var.target_role_arns) > 0
    error_message = "At least one target deployment role ARN is required."
  }
}

variable "max_session_duration" {
  type    = number
  default = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.github_oidc_thumbprints

  tags = merge(var.tags, {
    ManagedBy = "Terraform"
    Purpose   = "GitHub Actions federation"
  })
}

data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "AllowGitHubActionsFederation"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.github_subject_claims
    }
  }
}

resource "aws_iam_role" "orchestrator" {
  name                 = var.role_name
  path                 = "/github-actions/"
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = var.max_session_duration

  tags = merge(var.tags, {
    ManagedBy = "Terraform"
    Purpose   = "Terraform cross-account orchestration"
  })
}

locals {
  normalized_state_prefixes = [for prefix in var.state_key_prefixes : trimsuffix(trimprefix(prefix, "/"), "/")]
}

data "aws_iam_policy_document" "orchestrator" {
  statement {
    sid    = "ListApprovedStatePrefixes"
    effect = "Allow"

    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [var.state_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = flatten([for prefix in local.normalized_state_prefixes : [prefix, "${prefix}/*"]])
    }
  }

  statement {
    sid    = "ReadWriteApprovedStateObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [for prefix in local.normalized_state_prefixes : "${var.state_bucket_arn}/${prefix}/*"]
  }

  statement {
    sid    = "UseTerraformStateKey"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]

    resources = [var.state_kms_key_arn]
  }

  statement {
    sid       = "AssumeApprovedDeploymentRoles"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = var.target_role_arns
  }
}

resource "aws_iam_role_policy" "orchestrator" {
  name   = "terraform-orchestrator"
  role   = aws_iam_role.orchestrator.id
  policy = data.aws_iam_policy_document.orchestrator.json
}

output "role_arn" {
  value = aws_iam_role.orchestrator.arn
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}

output "target_role_arns" {
  value = var.target_role_arns
}
