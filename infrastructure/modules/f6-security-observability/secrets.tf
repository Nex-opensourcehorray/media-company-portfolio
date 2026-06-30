resource "aws_kms_key" "app" {
  count = var.secret_kms_key_arn == null ? 1 : 0

  description             = "KMS key for application config in ${var.project_name}-${var.environment}"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true

  tags = local.common_tags
}

resource "aws_kms_alias" "app" {
  count = var.secret_kms_key_arn == null ? 1 : 0

  name          = "alias/${var.project_name}-${var.environment}-app"
  target_key_id = aws_kms_key.app[0].key_id
}

resource "aws_secretsmanager_secret" "app" {
  name                    = local.application_secret_name
  description             = var.secret_description
  kms_key_id              = local.application_kms_key_arn
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = local.common_tags
}

resource "aws_iam_policy" "app_reader" {
  name        = "${local.name_prefix}-app-reader"
  description = "Read access to the application runtime configuration secret"

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
      },
      {
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = local.application_kms_key_arn
      }
    ]
  })

  tags = local.common_tags
}
