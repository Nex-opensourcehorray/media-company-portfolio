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
  region              = var.aws_region
  allowed_account_ids = [var.target_account_id]

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Layer       = "AccountBootstrap"
    }
  }
}

module "deployment_role" {
  source = "../modules/deployment-role"

  role_name               = var.deployment_role_name
  trusted_principal_arns  = [var.tooling_principal_arn]
  external_id             = var.external_id
  permissions_boundary_arn = var.permissions_boundary_arn
  managed_policy_arns     = var.managed_policy_arns
  inline_policy_json      = var.inline_policy_json
  state_bucket_arn        = var.state_bucket_arn
  state_kms_key_arn       = var.state_kms_key_arn
  state_key_prefixes      = var.state_key_prefixes

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

variable "project_name" {
  type    = string
  default = "media-platform"
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "target_account_id" {
  type = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.target_account_id))
    error_message = "target_account_id must be a 12-digit AWS account ID."
  }
}

variable "tooling_principal_arn" {
  type = string
}

variable "deployment_role_name" {
  type    = string
  default = "TerraformDeploymentRole"
}

variable "external_id" {
  type      = string
  default   = null
  nullable  = true
  sensitive = true
}

variable "permissions_boundary_arn" {
  type     = string
  default  = null
  nullable = true
}

variable "managed_policy_arns" {
  type    = set(string)
  default = []
}

variable "inline_policy_json" {
  type      = string
  default   = null
  nullable  = true
  sensitive = true
}

variable "state_bucket_arn" {
  type     = string
  default  = null
  nullable = true
}

variable "state_kms_key_arn" {
  type     = string
  default  = null
  nullable = true
}

variable "state_key_prefixes" {
  type    = set(string)
  default = []
}

output "deployment_role_arn" {
  value = module.deployment_role.role_arn
}
