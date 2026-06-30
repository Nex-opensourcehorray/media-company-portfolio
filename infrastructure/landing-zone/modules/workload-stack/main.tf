terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
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

variable "force_destroy_buckets" {
  description = "Allow destructive deletion of non-empty workload buckets. Keep false in staging and production."
  type        = bool
  default     = false
}

variable "ingest_expiration_days" {
  type     = number
  default  = null
  nullable = true
}

variable "output_transition_days" {
  type    = number
  default = 30
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "waf_rate_limit" {
  type    = number
  default = 2000
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "shared_foundation" {
  source = "../../../modules/shared-foundation"

  project     = var.project_name
  environment = var.environment
  region      = var.aws_region
}

module "f6_security_observability" {
  source = "../../../modules/f6-security-observability"

  project_name   = var.project_name
  environment    = var.environment
  waf_rate_limit = var.waf_rate_limit
  tags            = var.tags
}

module "f1_auth_api" {
  source = "../../../modules/f1-auth-api"

  project_name             = var.project_name
  environment              = var.environment
  permissions_boundary_arn = module.f6_security_observability.boundary_arn
}

module "f2_live_stream" {
  source = "../../../modules/f2-live-stream"

  project_name             = var.project_name
  environment              = var.environment
  permissions_boundary_arn = module.f6_security_observability.boundary_arn
}

module "f3_vod_processing" {
  source = "../../../modules/f3-vod-processing"

  project_name             = var.project_name
  environment              = var.environment
  permissions_boundary_arn = module.f6_security_observability.boundary_arn
  force_destroy_buckets    = var.force_destroy_buckets
  ingest_expiration_days   = var.ingest_expiration_days
  output_transition_days   = var.output_transition_days
  log_retention_days       = var.log_retention_days
  tags                     = var.tags
}

module "f4_subtitle_processing" {
  source = "../../../modules/f4-subtitle-processing"

  project_name             = var.project_name
  environment              = var.environment
  permissions_boundary_arn = module.f6_security_observability.boundary_arn
}

module "f5_content_delivery" {
  source = "../../../modules/f5-content-delivery"

  project_name = var.project_name
  environment  = var.environment
}

output "permissions_boundary_arn" {
  value = module.f6_security_observability.boundary_arn
}

output "regional_waf_arn" {
  value = module.f6_security_observability.waf_acl_arn
}
