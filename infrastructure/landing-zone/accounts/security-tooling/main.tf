terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "REPLACE_STATE_BUCKET"
    key          = "landing-zone/security-tooling/terraform.tfstate"
    region       = "REPLACE_REGION"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}

variable "aws_partition" {
  description = "AWS partition, normally aws."
  type        = string
  default     = "aws"
}

variable "home_region" {
  description = "Security Hub aggregation home Region and GuardDuty management Region."
  type        = string
}

variable "security_account_id" {
  type = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.security_account_id))
    error_message = "security_account_id must be a 12-digit AWS account ID."
  }
}

variable "management_account_id" {
  type = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "management_account_id must be a 12-digit AWS account ID."
  }
}

variable "deployment_role_name" {
  type    = string
  default = "TerraformDeploymentRole"
}

variable "management_role_name" {
  type    = string
  default = "TerraformOrganizationRole"
}

variable "external_id" {
  type      = string
  default   = null
  nullable  = true
  sensitive = true
}

variable "enable_organization_management" {
  description = "Designate the security account and enable organization-wide GuardDuty and Security Hub configuration."
  type        = bool
  default     = false
}

variable "guardduty_features" {
  description = "GuardDuty organization features enabled for all current and future member accounts in this Region."
  type        = set(string)
  default = [
    "S3_DATA_EVENTS",
    "EBS_MALWARE_PROTECTION",
    "RDS_LOGIN_EVENTS",
    "LAMBDA_NETWORK_LOGS"
  ]
}

variable "securityhub_target_ids" {
  description = "Organization root, OU, or account IDs associated with the central Security Hub policy."
  type        = set(string)
  default     = []
}

provider "aws" {
  region              = var.home_region
  allowed_account_ids = [var.security_account_id]

  assume_role {
    role_arn     = "arn:${var.aws_partition}:iam::${var.security_account_id}:role/terraform/${var.deployment_role_name}"
    session_name = "tf-security-tooling"
    external_id  = var.external_id
  }

  default_tags {
    tags = {
      Environment = "security-tooling"
      ManagedBy   = "Terraform"
      Layer       = "SecurityControlPlane"
    }
  }
}

provider "aws" {
  alias               = "management"
  region              = var.home_region
  allowed_account_ids = [var.management_account_id]

  assume_role {
    role_arn     = "arn:${var.aws_partition}:iam::${var.management_account_id}:role/terraform/${var.management_role_name}"
    session_name = "tf-security-delegation"
    external_id  = var.external_id
  }
}

resource "aws_guardduty_organization_admin_account" "security" {
  count    = var.enable_organization_management ? 1 : 0
  provider = aws.management

  admin_account_id = var.security_account_id
}

resource "aws_securityhub_organization_admin_account" "security" {
  count    = var.enable_organization_management ? 1 : 0
  provider = aws.management

  admin_account_id = var.security_account_id
}

resource "aws_guardduty_detector" "security" {
  enable = true
}

resource "aws_guardduty_organization_configuration" "security" {
  count = var.enable_organization_management ? 1 : 0

  detector_id                     = aws_guardduty_detector.security.id
  auto_enable_organization_members = "ALL"

  depends_on = [aws_guardduty_organization_admin_account.security]
}

resource "aws_guardduty_organization_configuration_feature" "features" {
  for_each = var.enable_organization_management ? var.guardduty_features : toset([])

  detector_id = aws_guardduty_detector.security.id
  name        = each.value
  auto_enable = "ALL"

  depends_on = [aws_guardduty_organization_configuration.security]
}

resource "aws_securityhub_account" "security" {
  enable_default_standards = false
}

resource "aws_securityhub_finding_aggregator" "security" {
  linking_mode = "ALL_REGIONS"

  depends_on = [
    aws_securityhub_account.security,
    aws_securityhub_organization_admin_account.security
  ]
}

resource "aws_securityhub_organization_configuration" "security" {
  count = var.enable_organization_management ? 1 : 0

  auto_enable           = false
  auto_enable_standards = "NONE"

  organization_configuration {
    configuration_type = "CENTRAL"
  }

  depends_on = [aws_securityhub_finding_aggregator.security]
}

resource "aws_securityhub_configuration_policy" "baseline" {
  count = var.enable_organization_management ? 1 : 0

  name        = "media-platform-security-baseline"
  description = "Central Security Hub policy for the media platform organization"

  configuration_policy {
    service_enabled = true

    enabled_standard_arns = [
      "arn:${var.aws_partition}:securityhub:${var.home_region}::standards/aws-foundational-security-best-practices/v/1.0.0"
    ]

    security_controls_configuration {
      disabled_control_identifiers = []
    }
  }

  depends_on = [aws_securityhub_organization_configuration.security]
}

resource "aws_securityhub_configuration_policy_association" "baseline" {
  for_each = var.enable_organization_management ? var.securityhub_target_ids : toset([])

  target_id = each.value
  policy_id = aws_securityhub_configuration_policy.baseline[0].id
}

output "guardduty_detector_id" {
  value = aws_guardduty_detector.security.id
}

output "securityhub_aggregator_arn" {
  value = aws_securityhub_finding_aggregator.security.arn
}

output "securityhub_policy_id" {
  value = try(aws_securityhub_configuration_policy.baseline[0].id, null)
}
