terraform {
  required_version = ">= 1.7.0"
}

variable "environment" {
  type = string
}

variable "project_name" {
  type    = string
  default = "media-platform"
}

variable "permissions_boundary_arn" {
  description = "IAM permissions boundary ARN for future F1 execution roles."
  type        = string
  default     = null
}

locals {
  name = "${var.project_name}-${var.environment}-f1"
}

# F1: Authentication and Application API
# This module currently exposes a validated interface only. Resource
# implementation will add Cognito, API Gateway, Lambda and DynamoDB.

output "module_status" {
  value = "${local.name}-scaffold"
}

output "permissions_boundary_arn" {
  value = var.permissions_boundary_arn
}
