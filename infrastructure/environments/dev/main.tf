terraform {
  required_version = ">= 1.7.0"

  backend "s3" {
    bucket         = "REPLACE_WITH_BOOTSTRAP_BUCKET"
    key            = "media-platform/dev/terraform.tfstate"
    region         = "REPLACE_WITH_REGION"
    dynamodb_table = "REPLACE_WITH_LOCK_TABLE"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  environment = "dev"
  project     = var.project_name

  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

module "shared_foundation" {
  source      = "../../modules/shared-foundation"
  project     = var.project_name
  environment = local.environment
  region      = var.aws_region
}

module "f1_auth_api" {
  source      = "../../modules/f1-auth-api"
  environment = local.environment
}

module "f3_vod_processing" {
  source      = "../../modules/f3-vod-processing"
  environment = local.environment
}

module "f5_content_delivery" {
  source      = "../../modules/f5-content-delivery"
  environment = local.environment
}

module "f6_security_observability" {
  source      = "../../modules/f6-security-observability"
  environment = local.environment
}

variable "project_name" {
  type    = string
  default = "media-platform"
}

variable "aws_region" {
  type = string
}
