terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "REPLACE_STATE_BUCKET"
    key          = "landing-zone/staging/terraform.tfstate"
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
    session_name = "tf-staging"
    external_id  = var.external_id
  }

  default_tags {
    tags = {
      Environment = "staging"
      ManagedBy   = "Terraform"
      Layer       = "Workload"
    }
  }
}

locals {
  environment = "staging"
}

module "workload_stack" {
  source = "../../modules/workload-stack"

  project_name = "media-platform"
  environment  = local.environment
  aws_region   = var.aws_region

  force_destroy_buckets = false
  log_retention_days    = 30
  waf_rate_limit        = 2000
}
