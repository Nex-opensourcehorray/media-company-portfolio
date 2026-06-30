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

locals {
  name_prefix = "${var.project_name}-${var.environment}-f5"
}

output "module_status" {
  value = "${local.name_prefix}-scaffold"
}
