locals {
  # route_path      = var.route_path
  # bucket_map      = var.userplatform_s3_bucket
  selected_bucket_eu = local.bucket_map["eu"]
}


# resource "aws_cloudwatch_log_group" "userplatform_cpp_event_bus_logs" {
#   provider          = aws.us
#   name              = "/aws/events/userplatform_cpp_event_bus_logs"
#   retention_in_days = 14
# }

resource "aws_cloudwatch_event_bus" "userplatform_cpp_event_bus_eu" {
  provider = aws.eu
  name     = "userplatform_cpp_event_bus_eu"
}


resource "aws_iam_role" "userplatform_cpp_eventbridge_firehose_role_eu" {
  name = "userplatform_cpp_eventbridge_firehose_role_eu"
  # permissions_boundary = "arn:aws:iam::${var.account_id}:policy/tenant-${var.tenant_name}-boundary"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "userplatform_cpp_eventbridge_firehose_policy_eu" {
  name = "userplatform_cpp_eventbridge_firehose_policy_eu"
  role = aws_iam_role.userplatform_cpp_eventbridge_firehose_role_eu.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "firehose:PutRecord",
        "firehose:PutRecordBatch"
      ],
      Effect   = "Allow",
      Resource = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_eu.arn
      },
      {
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::${local.selected_bucket_eu}",
          "arn:aws:s3:::${local.selected_bucket_eu}/*"
        ]
      },
      {
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams"
        ],
        Effect   = "Allow",
        Resource = "*"
    }]
  })
}

# Firehose delivery streams + SNS for failure
resource "aws_kinesis_firehose_delivery_stream" "userplatform_cpp_firehose_delivery_stream_eu" {
  provider    = aws.eu
  name        = "userplatform-cpp-firehose-delivery-stream-eu"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.userplatform_cpp_eventbridge_firehose_role_eu.arn
    bucket_arn          = "arn:aws:s3:::${local.selected_bucket_eu}"
    prefix              = "raw/cppv2-collector/"
    error_output_prefix = "raw/cppv2-errors/"
    compression_format  = "UNCOMPRESSED"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "aws_cloudwatch_log_group.userplatform_cpp_firehose_to_s3_eu.name"
      log_stream_name = "aws_cloudwatch_log_stream.userplatform_cpp_firehose_to_s3_log_stream_eu.name"
    }

    processing_configuration {
      enabled = "true"

      # New line delimiter processor
      processors {
        type = "AppendDelimiterToRecord"
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "userplatform_cpp_firehose_to_s3_eu" {
  name              = "/aws/kinesisfirehose/userplatform_cpp_firehose_to_s3_eu"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "userplatform_cpp_firehose_to_s3_log_stream_eu" {
  name           = "userplatform_cpp_firehose_to_s3_log_stream_eu"
  log_group_name = aws_cloudwatch_log_group.userplatform_cpp_firehose_to_s3_eu.name
}

# CloudWatch alarm for Firehose failure delivery
resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_firehose_failure_alarm_eu" {
  provider            = aws.eu
  alarm_name          = "Userplatform-CPP-FirehoseDeliveryFailures-EU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DeliveryToS3.DataDeliveryFailed"
  namespace           = "AWS/Firehose"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when Firehose fails to deliver data to S3"
  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_eu.name
  }
  alarm_actions = [aws_sns_topic.userplatform_cpp_firehose_failure_eu.arn]
}

# EventBridge rules per route_path
resource "aws_cloudwatch_event_rule" "userplatform_cpp_eventbridge_to_firehose_rule_eu" {
  provider       = aws.eu
  name           = "userplatform_cpp_eventbridge_to_firehose_rule_eu"
  event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.name

  event_pattern = jsonencode({
    "detail-type" : ["US"]
  })

}

# resource "aws_cloudwatch_event_rule" "userplatform_cpp_eventbridge_to_firehose_rule_eu" {
#   provider       = aws.us
#   name           = "userplatform_cpp_eventbridge_to_firehose_rule_eu"
#   event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.name
#
#   event_pattern = jsonencode({
#     "detail" : [{
#       "prefix" : "{\"body\":{\"payload\":{\"fullDocument_payload\":{\"market\":\"US\""
#     }]
#   })
#
# }

resource "aws_cloudwatch_event_target" "userplatform_cpp_cloudwatch_event_target_eu" {
  provider       = aws.eu
  rule           = aws_cloudwatch_event_rule.userplatform_cpp_eventbridge_to_firehose_rule_eu.name
  arn            = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_eu.arn
  role_arn       = aws_iam_role.userplatform_cpp_eventbridge_firehose_role_eu.arn
  event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.name
}

resource "aws_cloudwatch_event_target" "chargebee_retention_eventbridge_to_log_target_eu" {
  provider       = aws.eu
  rule           = aws_cloudwatch_event_rule.userplatform_cpp_eventbridge_to_firehose_rule_eu.name
  arn            = aws_cloudwatch_log_group.userplatform_cpp_event_bus_logs.arn
  event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.name
  depends_on     = [aws_cloudwatch_log_group.userplatform_cpp_event_bus_logs]
}


# 1. SNS Topic for alerts
resource "aws_sns_topic" "userplatform_cpp_firehose_failure_eu" {
  provider = aws.eu
  name     = "userplatform-cpp-firehose-failure-alert-eu"
}

# # 2. IAM Role for AWS Chatbot
# resource "aws_iam_role" "userplatform_cpp_chatbot_role_us" {
#   name = "userplatform_cpp_chatbot_role_us"
#   # permissions_boundary = "arn:aws:iam::${var.account_id}:policy/tenant-${var.tenant_name}-boundary"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Service = "chatbot.amazonaws.com"
#       },
#       Action = "sts:AssumeRole"
#     }]
#   })
# }
#
# resource "aws_iam_role_policy_attachment" "userplatform_cpp_chatbot_attach_us" {
#   role       = aws_iam_role.userplatform_cpp_chatbot_role_us.name
#   policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
# }

# # 3. AWS Chatbot Slack Configuration
# resource "aws_chatbot_slack_channel_configuration" "userplatform_cpp_firehose_alerts_to_slack_eu" {
#   configuration_name = "userplatform_cpp_firehose_alerts_to_slack_eu"
#   slack_channel_id   = var.slack_channel_id
#   slack_team_id      = var.slack_workspace_id
#
#   sns_topic_arns = [aws_sns_topic.userplatform_cpp_firehose_failure_eu.arn]
#   iam_role_arn   = aws_iam_role.userplatform_cpp_chatbot_role_us.arn
#   logging_level  = "ERROR"
# }


