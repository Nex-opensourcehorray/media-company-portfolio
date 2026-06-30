variable "project_name" {
  description = "Lowercase project identifier used in names and tags."
  type        = string
  default     = "media-platform"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,18}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 3-20 lowercase alphanumeric or hyphen characters and cannot start or end with a hyphen."
  }
}

variable "environment" {
  description = "Deployment environment identifier."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,8}[a-z0-9]$", var.environment))
    error_message = "environment must be 2-10 lowercase alphanumeric or hyphen characters and cannot start or end with a hyphen."
  }
}

variable "protected_regional_resource_arns" {
  description = "Regional AWS resource ARNs to associate with the regional WAF web ACL, such as an API Gateway stage ARN."
  type        = set(string)
  default     = []
}

variable "waf_rate_limit" {
  description = "Maximum requests per five-minute evaluation window for a single source IP before blocking."
  type        = number
  default     = 2000

  validation {
    condition     = var.waf_rate_limit >= 100
    error_message = "waf_rate_limit must be at least 100."
  }
}

variable "enable_waf_logging" {
  description = "Enable full AWS WAF request logging to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "waf_log_retention_days" {
  description = "Retention period for WAF request logs."
  type        = number
  default     = 30
}

variable "waf_blocked_request_alarm_threshold" {
  description = "Blocked-request count in five minutes that triggers the WAF alarm."
  type        = number
  default     = 100

  validation {
    condition     = var.waf_blocked_request_alarm_threshold >= 1
    error_message = "waf_blocked_request_alarm_threshold must be at least 1."
  }
}

variable "alarm_topic_arns" {
  description = "Optional SNS topic ARNs receiving security alarm notifications."
  type        = list(string)
  default     = []
}

variable "secret_name_suffix" {
  description = "Path suffix for the application runtime secret container."
  type        = string
  default     = "application/runtime"

  validation {
    condition     = length(trim(var.secret_name_suffix, "/")) > 0
    error_message = "secret_name_suffix cannot be empty."
  }
}

variable "secret_description" {
  description = "Description for the application runtime secret container."
  type        = string
  default     = "Application runtime configuration. Populate the value outside Terraform."
}

variable "secret_kms_key_arn" {
  description = "Optional customer-managed KMS key ARN for Secrets Manager. When null, the module creates one."
  type        = string
  default     = null
  nullable    = true
}

variable "secret_recovery_window_in_days" {
  description = "Recovery window applied when the secret is deleted."
  type        = number
  default     = 30

  validation {
    condition     = var.secret_recovery_window_in_days >= 7 && var.secret_recovery_window_in_days <= 30
    error_message = "secret_recovery_window_in_days must be between 7 and 30."
  }
}

variable "kms_deletion_window_in_days" {
  description = "Waiting period before deletion of a module-created Secrets Manager KMS key."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "kms_deletion_window_in_days must be between 7 and 30."
  }
}

variable "tags" {
  description = "Additional tags applied to F6 resources."
  type        = map(string)
  default     = {}
}
