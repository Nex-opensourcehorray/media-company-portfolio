data "aws_iam_policy_document" "permissions_boundary" {
  statement {
    sid    = "AllowAll"
    effect = "Allow"

    actions   = ["*"]
    resources = ["*"]
  }

  statement {
    sid    = "DenyHighRiskIAMOperations"
    effect = "Deny"

    actions = [
      "iam:CreateUser",
      "iam:DeleteUser",
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      "iam:UpdateAccessKey",
      "iam:PutUserPolicy",
      "iam:AttachUserPolicy",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:PutRolePolicy",
      "iam:AttachRolePolicy",
      "iam:UpdateAssumeRolePolicy",
      "iam:PutRolePermissionsBoundary",
      "iam:DeleteRolePermissionsBoundary"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "DenyOrgAndBillingEscalation"
    effect = "Deny"

    actions = [
      "organizations:*",
      "account:*",
      "billing:*"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "DenySecurityControlTampering"
    effect = "Deny"

    actions = [
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail",
      "config:StopConfigurationRecorder",
      "config:DeleteConfigurationRecorder",
      "guardduty:DeleteDetector",
      "kms:ScheduleKeyDeletion",
      "kms:DisableKey",
      "kms:PutKeyPolicy"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "permissions_boundary" {
  name        = "${local.name_prefix}-permissions-boundary"
  description = "IAM permissions boundary for ${local.name_prefix} workloads"
  policy      = data.aws_iam_policy_document.permissions_boundary.json

  tags = local.common_tags
}
