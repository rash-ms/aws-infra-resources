# EU EventBridge
resource "aws_cloudwatch_event_bus" "userplatform_cpp_event_bus_eu" {
  provider = aws.eu
  name     = "userplatform_cpp_event_bus_eu"
}

resource "aws_cloudwatch_event_bus_policy" "userplatform_cpp_eventbridge_cross_region_eu_policy" {
  provider       = aws.eu
  event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowUSAPIGatewayToEU",
        Effect = "Allow",
        Principal = {
          AWS = "${var.account_id}"
        },
        Action   = "events:PutEvents",
        Resource = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.arn
      }
    ]
  })
  depends_on = [
    aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu
  ]
}

resource "aws_iam_role_policy" "userplatform_cpp_eventbridge_firehose_policy_eu" {
  name = "userplatform_cpp_eventbridge_firehose_policy_eu"
  role = aws_iam_role.userplatform_cpp_eventbridge_firehose_role.id

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
          "arn:aws:s3:::${local.route_configs["eu"].bucket}",
          "arn:aws:s3:::${local.route_configs["eu"].bucket}/*"
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
    role_arn = aws_iam_role.userplatform_cpp_eventbridge_firehose_role.arn
    # bucket_arn          = "arn:aws:s3:::${local.selected_bucket_eu}"
    bucket_arn          = "arn:aws:s3:::${local.route_configs["eu"].bucket}"
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
    "detail-type" : ["EU"]
  })

}

resource "aws_cloudwatch_event_target" "userplatform_cpp_cloudwatch_event_target_eu" {
  provider       = aws.eu
  rule           = aws_cloudwatch_event_rule.userplatform_cpp_eventbridge_to_firehose_rule_eu.name
  arn            = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_eu.arn
  role_arn       = aws_iam_role.userplatform_cpp_eventbridge_firehose_role.arn
  event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.name
}

resource "aws_cloudwatch_event_target" "userplatform_cpp_eventbridge_to_log_target_eu" {
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


