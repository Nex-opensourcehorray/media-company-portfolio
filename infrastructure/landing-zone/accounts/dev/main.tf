terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket = "REPLACE_STATE_BUCKET"
    key    = "landing-zone/dev/terraform.tfstate"
    region = "REPLACE_REGION"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "deployment_role_name" {
  type    = string
  default = "TerraformDeploymentRole"
}

variable "external_id" {
  type      = string
  default   = null
  sensitive = true
}

provider "aws" {
  region = var.aws_region

  allowed_account_ids = [var.account_id]

  assume_role {
    role_arn     = "arn:${data.aws_partition.current.partition}:iam::${var.account_id}:role/terraform/${var.deployment_role_name}"
    session_name = "tf-dev"
    external_id  = var.external_id
  }

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "Terraform"
      Layer       = "Workload"
    }
  }
}

locals {
  environment = "dev"
}

# Example integration with platform modules

module "security" {
  source = "../../../modules/f6-security-observability"

  project_name = "media-platform"
  environment   = local.environment
}

module "vod" {
  source = "../../../modules/f3-vod-processing"

  project_name = "media-platform"
  environment  = local.environment

  permissions_boundary_arn = module.security.boundary_arn
}

output "account" {
  value = var.account_id
}
