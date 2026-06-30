terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "REPLACE_STATE_BUCKET"
    key          = "landing-zone/organization-trail/terraform.tfstate"
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

variable "home_region" {
  description = "CloudTrail home Region. Must match the Region used by the log-archive bucket policy."
  type        = string
}

variable "management_account_id" {
  description = "AWS Organizations management account ID."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "management_account_id must be a 12-digit AWS account ID."
  }
}

variable "management_role_name" {
  description = "Management-account role used to create and manage the organization trail."
  type        = string
  default     = "TerraformOrganizationRole"
}

variable "external_id" {
  type      = string
  default   = null
  nullable  = true
  sensitive = true
}

variable "enable_organization_trail" {
  description = "Create and start the organization-wide CloudTrail trail. Keep false until the Step 2 bucket and KMS policies are deployed and verified."
  type        = bool
  default     = false
}

variable "trail_name" {
  description = "Organization trail name. Must match the name supplied to the log-archive account root."
  type        = string
  default     = "media-platform-organization-trail"
}

variable "state_bucket_name" {
  description = "Central Terraform state bucket containing the log-archive account state."
  type        = string
}

variable "state_bucket_region" {
  description = "Region of the central Terraform state bucket."
  type        = string
}

variable "log_archive_state_key" {
  description = "State key produced by infrastructure/landing-zone/accounts/log-archive."
  type        = string
  default     = "landing-zone/log-archive/terraform.tfstate"
}

variable "log_management_events" {
  type    = bool
  default = true
}

variable "read_write_type" {
  description = "Management event mode: All, ReadOnly, or WriteOnly."
  type        = string
  default     = "All"

  validation {
    condition     = contains(["All", "ReadOnly", "WriteOnly"], var.read_write_type)
    error_message = "read_write_type must be All, ReadOnly, or WriteOnly."
  }
}

variable "enable_insights" {
  description = "Enable CloudTrail Insights for API call and API error rate anomalies."
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

provider "aws" {
  region              = var.home_region
  allowed_account_ids = [var.management_account_id]

  assume_role {
    role_arn     = "arn:${var.aws_partition}:iam::${var.management_account_id}:role/terraform/${var.management_role_name}"
    session_name = "tf-organization-trail"
    external_id  = var.external_id
  }

  default_tags {
    tags = merge(var.tags, {
      Project     = "media-platform"
      Environment = "organization"
      ManagedBy   = "Terraform"
      Layer       = "AuditControlPlane"
    })
  }
}

data "aws_caller_identity" "management" {}

data "terraform_remote_state" "log_archive" {
  count   = var.enable_organization_trail ? 1 : 0
  backend = "s3"

  config = {
    bucket       = var.state_bucket_name
    key          = var.log_archive_state_key
    region       = var.state_bucket_region
    use_lockfile = true
  }
}

locals {
  archive_outputs = var.enable_organization_trail ? data.terraform_remote_state.log_archive[0].outputs : {}
}

resource "aws_cloudtrail" "organization" {
  count = var.enable_organization_trail ? 1 : 0

  name                          = var.trail_name
  s3_bucket_name                = local.archive_outputs.cloudtrail_bucket_name
  s3_key_prefix                 = local.archive_outputs.cloudtrail_log_prefix
  kms_key_id                    = local.archive_outputs.cloudtrail_kms_key_arn
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true

  event_selector {
    include_management_events = var.log_management_events
    read_write_type           = var.read_write_type
  }

  dynamic "insight_selector" {
    for_each = var.enable_insights ? toset(["ApiCallRateInsight", "ApiErrorRateInsight"]) : toset([])

    content {
      insight_type = insight_selector.value
    }
  }

  lifecycle {
    precondition {
      condition     = data.aws_caller_identity.management.account_id == var.management_account_id
      error_message = "The configured provider is not authenticated to the expected AWS Organizations management account."
    }

    precondition {
      condition     = local.archive_outputs.organization_trail_source_arn == "arn:${var.aws_partition}:cloudtrail:${var.home_region}:${var.management_account_id}:trail/${var.trail_name}"
      error_message = "The log-archive bucket policy was prepared for a different trail name, Region, partition, or management account. Redeploy Step 2 with matching values before enabling this trail."
    }
  }
}

output "organization_trail_arn" {
  value = try(aws_cloudtrail.organization[0].arn, null)
}

output "organization_trail_home_region" {
  value = var.enable_organization_trail ? var.home_region : null
}

output "log_archive_bucket_name" {
  value = var.enable_organization_trail ? local.archive_outputs.cloudtrail_bucket_name : null
}

output "organization_trail_enabled" {
  value = var.enable_organization_trail
}
