data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Component = "VODProcessing"
    }
  )
}

resource "aws_media_convert_queue" "vod" {
  name            = "${local.name_prefix}-vod"
  description     = "On-demand queue for VOD processing"
  pricing_plan    = "ON_DEMAND"
  status          = "ACTIVE"
  concurrent_jobs = var.media_convert_concurrent_jobs

  tags = local.common_tags
}
