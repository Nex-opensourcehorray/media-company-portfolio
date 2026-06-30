terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn     = var.management_role_arn
    session_name = "landing-zone-org"
  }
}

variable "aws_region" {
  type = string
}

variable "management_role_arn" {
  type = string
}

variable "enable_guardrails" {
  type    = bool
  default = false
}

variable "target_ou_ids" {
  type    = set(string)
  default = []
}

resource "aws_organizations_policy" "guardrails" {
  count = var.enable_guardrails ? 1 : 0

  name        = "landing-zone-guardrails"
  description = "Baseline SCP guardrails for media platform"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyRootUserActions"
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:root"
          }
        }
      },
      {
        Sid    = "DenyDisableSecurityServices"
        Effect = "Deny"
        Action = [
          "cloudtrail:StopLogging",
          "cloudtrail:DeleteTrail",
          "config:StopConfigurationRecorder",
          "guardduty:DeleteDetector"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyLeavingOrganization"
        Effect = "Deny"
        Action = "organizations:LeaveOrganization"
        Resource = "*"
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "attach" {
  for_each = var.enable_guardrails ? var.target_ou_ids : []

  policy_id = aws_organizations_policy.guardrails[0].id
  target_id = each.value
}

output "guardrails_policy_id" {
  value = try(aws_organizations_policy.guardrails[0].id, null)
}