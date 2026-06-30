terraform {
  required_version = ">= 1.7.0"
}

variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

output "name_prefix" {
  value = local.name_prefix
}

output "common_tags" {
  value = local.common_tags
}

output "region" {
  value = var.region
}
