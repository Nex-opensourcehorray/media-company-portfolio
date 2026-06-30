data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_kms_key" "app" {
  count = var.secret_kms_key_arn == null ? 1 : 0

  description             = "KMS key for application config in ${var.project_name}-${var.environment}"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true

  tags = var.tags
}

resource "aws_kms_alias" "app" {
  count = var.secret_kms_key_arn == null ? 1 : 0

  name          = "alias/${var.project_name}-${var.environment}-app"
  target_key_id = aws_kms_key.app[0].key_id
}

resource "aws_secretsmanager_secret" "app" {
  name                    = "/${var.project_name}/${var.environment}/${trim(var.secret_name_suffix, "/")}"
  description             = var.secret_description
  kms_key_id              = var.secret_kms_key_arn != null ? var.secret_kms_key_arn : aws_kms_key.app[0].arn
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = var.tags
}

resource "aws_iam_policy" "app_reader" {
  name        = "${var.project_name}-${var.environment}-app-reader"
  description = "Read access to application configuration"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.app.arn
      }
    ]
  })

  tags = var.tags
}
