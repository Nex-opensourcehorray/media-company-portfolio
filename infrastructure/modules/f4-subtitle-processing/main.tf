terraform {
  required_version = ">= 1.7.0"
}

variable "project_name" {
  type    = string
  default = "media-platform"
}

variable "environment" {
  type = string
}

variable "permissions_boundary_arn" {
  type     = string
  default  = null
  nullable = true
}

locals {
  name_prefix = "${var.project_name}-${var.environment}-f4"
}

# F4 contract: Transcribe batch, Translate, subtitle metadata and S3 outputs.
# Service resources are intentionally introduced in later implementation phases.

output "module_status" {
  value = "${local.name_prefix}-scaffold"
}

output "permissions_boundary_arn" {
  value = var.permissions_boundary_arn
}
