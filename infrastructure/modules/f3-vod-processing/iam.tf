data "aws_iam_policy_document" "mediaconvert_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["mediaconvert.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "mediaconvert_role" {
  name               = "${local.name_prefix}-mediaconvert-role"
  assume_role_policy = data.aws_iam_policy_document.mediaconvert_assume.json

  tags = local.common_tags
}

# MediaConvert permissions

data "aws_iam_policy_document" "mediaconvert_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = ["${aws_s3_bucket.ingest.arn}/${var.ingest_prefix}*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    resources = ["${aws_s3_bucket.output.arn}/${var.output_prefix}*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.ingest.arn, aws_s3_bucket.output.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [local.effective_kms_key_arn]
  }
}

resource "aws_iam_role_policy" "mediaconvert" {
  name   = "${local.name_prefix}-mediaconvert-policy"
  role   = aws_iam_role.mediaconvert_role.id
  policy = data.aws_iam_policy_document.mediaconvert_policy.json
}

# Step Functions execution role

data "aws_iam_policy_document" "sfn_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "sfn_role" {
  name               = "${local.name_prefix}-sfn-role"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume.json

  tags = local.common_tags
}

# Step Functions permissions

data "aws_iam_policy_document" "sfn_policy" {
  statement {
    effect = "Allow"

    actions = ["mediaconvert:CreateJob"]

    resources = [aws_media_convert_queue.vod.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "mediaconvert:GetJob",
      "mediaconvert:CancelJob"
    ]

    resources = ["arn:${data.aws_partition.current.partition}:mediaconvert:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:jobs/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/ManagedByService"
      values   = ["AWSStepFunctions"]
    }
  }

  statement {
    effect = "Allow"

    actions = ["iam:PassRole"]

    resources = [aws_iam_role.mediaconvert_role.arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["mediaconvert.amazonaws.com"]
    }
  }

  statement {
    effect = "Allow"

    actions = ["sqs:SendMessage"]

    resources = [aws_sqs_queue.workflow_failures.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "sfn_policy_attach" {
  name   = "${local.name_prefix}-sfn-policy"
  role   = aws_iam_role.sfn_role.id
  policy = data.aws_iam_policy_document.sfn_policy.json
}

# EventBridge invoke role

data "aws_iam_policy_document" "events_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "events_role" {
  name               = "${local.name_prefix}-events-role"
  assume_role_policy = data.aws_iam_policy_document.events_assume.json

  tags = local.common_tags
}

resource "aws_iam_role_policy" "events_policy" {
  name = "${local.name_prefix}-events-policy"
  role = aws_iam_role.events_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "states:StartExecution"
      Resource = aws_sfn_state_machine.vod.arn
    }]
  })
}
