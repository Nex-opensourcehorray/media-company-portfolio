terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "REPLACE_STATE_BUCKET"
    key          = "landing-zone/log-archive/terraform.tfstate"
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
  description = "Region hosting the log archive bucket and KMS key."
  type        = string
}

variable "log_archive_account_id" {
  type = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.log_archive_account_id))
    error_message = "log_archive_account_id must be a 12-digit AWS account ID."
  }
}

variable "management_account_id" {
  type = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "management_account_id must be a 12-digit AWS account ID."
  }
}

variable "organization_id" {
  type = string
}

variable "trail_home_region" {
  description = "Home Region where Step 4 will create the organization trail."
  type        = string
}

variable "trail_name" {
  type    = string
  default = "media-platform-organization-trail"
}

variable "bucket_name" {
  description = "Globally unique organization audit log bucket name."
  type        = string
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

variable "reader_principal_arns" {
  description = "Security or audit role ARNs permitted to read and decrypt organization logs."
  type        = set(string)
  default     = []
}

variable "enable_object_lock" {
  description = "Enable Object Lock at bucket creation. This decision is irreversible for the bucket."
  type        = bool
  default     = true
}

variable "object_lock_mode" {
  description = "Use GOVERNANCE initially; move to COMPLIANCE only after operational and legal approval."
  type        = string
  default     = "GOVERNANCE"
}

variable "object_lock_retention_days" {
  type    = number
  default = 365
}

variable "expiration_days" {
  description = "Seven-year default retention for audit logs."
  type        = number
  default     = 2555
}

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.log_archive_account_id]

  assume_role {
    role_arn     = "arn:${var.aws_partition}:iam::${var.log_archive_account_id}:role/terraform/${var.deployment_role_name}"
    session_name = "tf-log-archive"
    external_id  = var.external_id
  }

  default_tags {
    tags = {
      Project     = "media-platform"
      Environment = "log-archive"
      ManagedBy   = "Terraform"
      Layer       = "AuditVault"
      Criticality = "high"
    }
  }
}

module "log_archive" {
  source = "../../modules/log-archive"

  bucket_name           = var.bucket_name
  management_account_id = var.management_account_id
  organization_id       = var.organization_id
  trail_home_region     = var.trail_home_region
  trail_name            = var.trail_name
  log_prefix             = "cloudtrail"
  reader_principal_arns  = var.reader_principal_arns

  enable_object_lock         = var.enable_object_lock
  object_lock_mode           = var.object_lock_mode
  object_lock_retention_days = var.object_lock_retention_days

  transition_to_glacier_days      = 90
  transition_to_deep_archive_days = 365
  expiration_days                 = var.expiration_days
  force_destroy                   = false
}

output "cloudtrail_bucket_name" {
  value = module.log_archive.bucket_name
}

output "cloudtrail_bucket_arn" {
  value = module.log_archive.bucket_arn
}

output "cloudtrail_kms_key_arn" {
  value = module.log_archive.kms_key_arn
}

output "organization_trail_source_arn" {
  value = module.log_archive.trail_source_arn
}

output "cloudtrail_log_prefix" {
  value = module.log_archive.log_prefix
}
