data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Project      = var.project_name
    Environment  = var.environment
    ManagedBy    = "Terraform"
    Architecture = "F6-Security-Observability"
  })

  application_secret_name = "/${var.project_name}/${var.environment}/${trim(var.secret_name_suffix, "/")}"
  application_kms_key_arn = var.secret_kms_key_arn != null ? var.secret_kms_key_arn : aws_kms_key.application[0].arn
}
