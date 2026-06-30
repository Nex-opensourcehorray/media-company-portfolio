resource "aws_cloudwatch_log_group" "workflow" {
  name              = "/aws/vendedlogs/states/${local.name_prefix}-vod"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

resource "aws_sfn_state_machine" "vod" {
  name     = "${local.name_prefix}-vod"
  role_arn = aws_iam_role.sfn_role.arn
  type     = "STANDARD"

  logging_configuration {
    include_execution_data = var.include_execution_data
    level                  = "ALL"
    log_destination        = "${aws_cloudwatch_log_group.workflow.arn}:*"
  }

  tracing_configuration {
    enabled = var.enable_xray
  }

  definition = jsonencode({
    StartAt = "ExtractSource"

    States = {
      ExtractSource = {
        Type = "Pass"
        Parameters = {
          "bucket.$"  = "$.detail.bucket.name"
          "key.$"     = "$.detail.object.key"
          "eventId.$" = "$.id"
        }
        ResultPath = "$.source"
        Next       = "SubmitMediaConvertJob"
      }

      SubmitMediaConvertJob = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::mediaconvert:createJob.sync"

        Parameters = {
          Role   = aws_iam_role.mediaconvert_role.arn
          Queue  = aws_media_convert_queue.vod.arn

          StatusUpdateInterval = "SECONDS_60"

          Settings = {
            Inputs = [
              {
                "FileInput.$" = "States.Format('s3://{}/{}', $.source.bucket, $.source.key)"
                AudioSelectors = {
                  "Audio Selector 1" = {
                    DefaultSelection = "DEFAULT"
                  }
                }
                TimecodeSource = "ZEROBASED"
              }
            ]

            OutputGroups = [
              {
                Name = "HLS Group"

                OutputGroupSettings = {
                  Type = "HLS_GROUP_SETTINGS"

                  HlsGroupSettings = {
                    "Destination.$" = "States.Format('s3://${aws_s3_bucket.output.bucket}/${var.output_prefix}{}/', $.source.eventId)"
                    SegmentLength   = var.hls_segment_length_seconds
                    MinSegmentLength = 0
                  }
                }

                Outputs = [
                  for profile in var.video_profiles : {
                    NameModifier = profile.name_modifier

                    ContainerSettings = {
                      Container     = "M3U8"
                      M3u8Settings   = {}
                    }

                    VideoDescription = {
                      Width  = profile.width
                      Height = profile.height

                      CodecSettings = {
                        Codec = "H_264"

                        H264Settings = {
                          RateControlMode = "QVBR"
                          MaxBitrate      = profile.max_bitrate
                          SceneChangeDetect = "TRANSITION_DETECTION"

                          QvbrSettings = {
                            QvbrQualityLevel = profile.qvbr_quality_level
                          }
                        }
                      }
                    }

                    AudioDescriptions = [
                      {
                        AudioSourceName = "Audio Selector 1"
                        CodecSettings = {
                          Codec = "AAC"

                          AacSettings = {
                            Bitrate    = 96000
                            CodingMode = "CODING_MODE_2_0"
                            SampleRate = 48000
                          }
                        }
                      }
                    ]
                  }
                ]
              }
            ]
          }

          UserMetadata = {
            "sourceBucket.$" = "$.source.bucket"
            "sourceKey.$"    = "$.source.key"
          }
        }

        ResultPath = "$.transcode"

        Retry = [
          {
            ErrorEquals = ["States.ALL"]
            IntervalSeconds = 5
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]

        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "SendFailureToQueue"
          }
        ]

        Next = "WorkflowSucceeded"
      }

      SendFailureToQueue = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::sqs:sendMessage"

        Parameters = {
          QueueUrl            = aws_sqs_queue.workflow_failures.id
          "MessageBody.$"    = "States.JsonToString($)"
        }

        Next = "WorkflowFailed"
      }

      WorkflowSucceeded = {
        Type = "Succeed"
      }

      WorkflowFailed = {
        Type  = "Fail"
        Error = "VodPipelineFailed"
        Cause = "VOD processing pipeline encountered an error"
      }
    }
  })
}

resource "aws_cloudwatch_event_rule" "vod_ingest" {
  name        = "${local.name_prefix}-vod-ingest"
  description = "Trigger VOD pipeline on S3 uploads"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    "detail-type" = ["Object Created"]

    detail = {
      bucket = {
        name = [aws_s3_bucket.ingest.bucket]
      }

      object = {
        key = [for ext in var.allowed_file_extensions : {
          wildcard = "${var.ingest_prefix}*${ext}"
        }]
      }
    }
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "vod_ingest_target" {
  rule     = aws_cloudwatch_event_rule.vod_ingest.name
  arn      = aws_sfn_state_machine.vod.arn
  role_arn = aws_iam_role.events_role.arn

  dead_letter_config {
    arn = aws_sqs_queue.event_delivery_dlq.arn
  }

  retry_policy {
    maximum_event_age_in_seconds = var.event_max_age_seconds
    maximum_retry_attempts       = var.event_retry_attempts
  }
}

resource "aws_sqs_queue_policy" "event_dlq_policy" {
  queue_url = aws_sqs_queue.event_delivery_dlq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridge"
        Effect = "Allow"

        Principal = {
          Service = "events.amazonaws.com"
        }

        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.event_delivery_dlq.arn

        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.vod_ingest.arn
          }
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "workflow_failures" {
  alarm_name          = "${local.name_prefix}-vod-workflow-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.vod.arn
  }

  alarm_actions = var.alarm_topic_arns
  tags          = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "event_dlq_depth" {
  alarm_name          = "${local.name_prefix}-event-dlq-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    QueueName = aws_sqs_queue.event_delivery_dlq.name
  }

  alarm_actions = var.alarm_topic_arns
  tags          = local.common_tags
}
