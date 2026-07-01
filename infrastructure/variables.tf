variable "project_name" {
  description = "Short lowercase project identifier used in resource names and tags."
  type        = string
  default     = "media-platform"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.project_name))
    error_message = "project_name must contain 3-24 lowercase letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS Region used for regional resources. CloudFront remains a global service."
  type        = string
  default     = "ap-southeast-1"
}

variable "force_destroy" {
  description = "Allow Terraform to delete non-empty S3 buckets. Keep false outside disposable development environments."
  type        = bool
  default     = false
}

variable "ingest_expiration_days" {
  description = "Number of days before temporary ingest objects expire."
  type        = number
  default     = 7

  validation {
    condition     = var.ingest_expiration_days >= 1
    error_message = "ingest_expiration_days must be at least 1."
  }
}

variable "processed_transition_days" {
  description = "Number of days before processed content transitions to S3 Intelligent-Tiering."
  type        = number
  default     = 30

  validation {
    condition     = var.processed_transition_days >= 1
    error_message = "processed_transition_days must be at least 1."
  }
}

variable "cloudfront_price_class" {
  description = "CloudFront price class used by the development distribution."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition = contains([
      "PriceClass_100",
      "PriceClass_200",
      "PriceClass_All"
    ], var.cloudfront_price_class)
    error_message = "cloudfront_price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "additional_tags" {
  description = "Additional tags merged with the mandatory project tags."
  type        = map(string)
  default     = {}
}
