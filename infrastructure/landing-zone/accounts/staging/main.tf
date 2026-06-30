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

variable "aws_partition" {
  type    = string
  default = "aws"
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be a 12-digit AWS account ID."
  }
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

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.account_id]

  assume_role {
    role_arn     = "arn:${var.aws_partition}:iam::${var.account_id}:role/terraform/${var.deployment_role_name}"
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

module "workload_stack" {
  source = "../../modules/workload-stack"

  project_name = "media-platform"
  environment  = "staging"
  aws_region   = var.aws_region

  force_destroy_buckets = false
  log_retention_days    = 30
  waf_rate_limit        = 2000
}

output "account_id" {
  value = var.account_id
}
