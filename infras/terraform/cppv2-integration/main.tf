locals {
  bucket_map = zipmap(var.route_path, var.userplatform_s3_bucket)

  route_config = {
    "us-collector" = {
      region   = "us-east-1"
      provider = aws.us
    }
    "emea-collector" = {
      region   = "eu-central-1"
      provider = aws.eu
    }
    "apac-collector" = {
      region   = "ap-northeast-1"
      provider = aws.ap
    }
  }
}


# REST API Gateway
resource "aws_api_gateway_rest_api" "userplatform_cpp_rest_api" {
  name = "userplatform-cpp-rest-api"
}

resource "aws_api_gateway_deployment" "userplatform_cpp_api_deployment" {
  depends_on  = values(aws_api_gateway_method.userplatform_cpp_api_method)
  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api.id
}

resource "aws_api_gateway_stage" "userplatform_cpp_api_stage" {
  deployment_id = aws_api_gateway_deployment.userplatform_cpp_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.userplatform_cpp_rest_api.id
  stage_name    = "cppv02"
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.userplatform_cpp_api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId",
      ip             = "$context.identity.sourceIp",
      caller         = "$context.identity.caller",
      user           = "$context.identity.user",
      requestTime    = "$context.requestTime",
      httpMethod     = "$context.httpMethod",
      resourcePath   = "$context.resourcePath",
      status         = "$context.status",
      protocol       = "$context.protocol",
      responseLength = "$context.responseLength"
    })
  }
  xray_tracing_enabled = true
}

resource "aws_cloudwatch_log_group" "userplatform_cpp_api_gateway_logs" {
  name              = "/aws/apigateway/userplatform-cpp-rest-api"
  retention_in_days = 14
}

# Create resources and methods for each route_path
resource "aws_api_gateway_resource" "userplatform_cpp_api_resources" {
  for_each = toset(var.route_path)

  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api.id
  parent_id   = aws_api_gateway_rest_api.userplatform_cpp_rest_api.root_resource_id
  path_part   = each.key
}

resource "aws_api_gateway_method" "userplatform_cpp_api_method" {
  for_each = aws_api_gateway_resource.userplatform_cpp_api_resources

  rest_api_id      = aws_api_gateway_rest_api.userplatform_cpp_rest_api.id
  resource_id      = each.value.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_cloudwatch_event_bus" "userplatform_cpp_event_bus" {
  name = "userplatform_cpp_event_bus"
}

resource "aws_api_gateway_integration" "userplatform_cpp_api_integration" {
  for_each = aws_api_gateway_resource.userplatform_cpp_api_resources

  rest_api_id             = aws_api_gateway_rest_api.userplatform_cpp_rest_api.id
  resource_id             = each.value.id
  http_method             = aws_api_gateway_method.userplatform_cpp_api_method[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:events:action/PutEvents"
  credentials             = aws_iam_role.userplatform_cpp_api_gateway_eventbridge_role.arn
  request_templates = {
    "application/json" = <<EOF
  {
    "Entries": [
      {
        "Source": "cpp-${each.key}-api",
        "DetailType": "cpp-event-${each.key}",
        "Detail": "$util.escapeJavaScript($input.body)",
        "EventBusName": "${aws_cloudwatch_event_bus.userplatform_cpp_event_bus.name}"
      }
    ]
  }
  EOF
  }
}

resource "aws_iam_role" "userplatform_cpp_api_gateway_eventbridge_role" {
  name = "api-gateway-eventbridge-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "userplatform_cpp_api_gateway_eventbridge_policy" {
  name = "api-gateway-eventbridge-policy"
  role = aws_iam_role.userplatform_cpp_api_gateway_eventbridge_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["events:PutEvents"],
        Resource = "*"
      }
    ]
  })
}

# API Keys
resource "aws_api_gateway_api_key" "userplatform_cpp_api_key" {
  for_each = toset(var.route_path)

  name    = "${each.key}-api-key"
  enabled = true
}

# Usage Plans with high rate/burst
resource "aws_api_gateway_usage_plan" "userplatform_cpp_api_usage_plan" {
  for_each = toset(var.route_path)

  name = "${each.key}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api.id
    stage  = aws_api_gateway_stage.userplatform_cpp_api_stage.stage_name
  }

  throttle_settings {
    rate_limit  = 1000
    burst_limit = 200
  }
}

resource "aws_api_gateway_usage_plan_key" "userplatform_cpp_api_usage_plan_key" {
  for_each = toset(var.route_path)

  key_id        = aws_api_gateway_api_key.userplatform_cpp_api_key[each.key].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.userplatform_cpp_api_usage_plan[each.key].id
}

# IAM role for EventBridge to Firehose
resource "aws_iam_role" "userplatform_cpp_eventbridge_firehose_role" {
  name = "userplatform_cpp_eventbridge-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "userplatform_cpp_firehose_policy" {
  name = "userplatform-cpp-eventbridge-firehose-access-policy"
  role = aws_iam_role.userplatform_cpp_eventbridge_to_firehose_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["firehose:PutRecord", "firehose:PutRecordBatch"],
        Resource = "*"
      }
    ]
  })
}

# Firehose delivery streams + SNS for failure
resource "aws_kinesis_firehose_delivery_stream" "userplatform_cpp_firehose_delivery_stream" {
  for_each = local.route_config

  provider    = each.value.provider
  name        = "${each.key}-delivery-stream"
  destination = "s3"

  s3_configuration {
    role_arn           = aws_iam_role.userplatform_cpp_eventbridge_to_firehose_role.arn
    bucket_arn         = "arn:aws:s3:::${local.bucket_map[each.key]}"
    prefix             = "raw/cppv2-${each.key}/"
    buffer_size        = 5
    buffer_interval    = 300
    compression_format = "UNCOMPRESSED"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/${each.key}-delivery-stream"
      log_stream_name = "S3Delivery"
    }

    data_format_conversion_configuration {
      enabled = true

      input_format_configuration {
        deserializer {
          json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          json_ser_de {
            record_delimiter = "\n"
          }
        }
      }
    }
  }

  failure_s3_configuration {
    role_arn   = aws_iam_role.userplatform_cpp_eventbridge_to_firehose_role.arn
    bucket_arn = "arn:aws:s3:::${local.bucket_map[each.key]}"
    prefix     = "raw/cppv2-errors-${each.key}/"
  }
}

# resource "aws_kinesis_firehose_delivery_stream" "userplatform_cpp_firehose_delivery_stream" {
#   for_each    = toset(var.route_path)
#   provider    = local.route_provider_alias[each.key]
#   name        = "${each.key}-delivery-stream"
#   destination = "s3"

#   s3_configuration {
#     role_arn   = aws_iam_role.userplatform_cpp_eventbridge_to_firehose_role.arn
#     bucket_arn = "arn:aws:s3:::${local.bucket_map[each.key]}"

#     prefix             = "raw/cppv2-${each.key}/"
#     buffer_size        = 5
#     buffer_interval    = 300
#     compression_format = "UNCOMPRESSED"

#     cloudwatch_logging_options {
#       enabled         = true
#       log_group_name  = "/aws/kinesisfirehose/${each.key}-delivery-stream"
#       log_stream_name = "S3Delivery"
#     }

#     data_format_conversion_configuration {
#       enabled = true

#       input_format_configuration {
#         deserializer {
#           json_ser_de {}
#         }
#       }

#       output_format_configuration {
#         serializer {
#           json_ser_de {
#             record_delimiter = "\n"
#           }
#         }
#       }
#     }
#   }

#   failure_s3_configuration {
#     role_arn   = aws_iam_role.userplatform_cpp_eventbridge_to_firehose_role.arn
#     bucket_arn = "arn:aws:s3:::${local.bucket_map[each.key]}"
#     prefix     = "raw/cppv2-errors-${each.key}/"
#   }

#   # tags = {
#   #   Environment = var.environment
#   # }
# }

resource "aws_sns_topic" "userplatform_cpp_firehose_failure" {
  name = "userplatform-cpp-irehose-failure-alert"
}

# CloudWatch alarm for Firehose failure delivery
resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_firehose_failure_alarm" {
  for_each = toset(var.route_path)

  alarm_name          = "${each.key}-FirehoseDeliveryFailures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DeliveryToS3.Failure"
  namespace           = "AWS/Firehose"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert when Firehose fails to deliver data to S3"
  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream[each.key].name
  }
  alarm_actions = [aws_sns_topic.userplatform_cpp_firehose_failure.arn]
}

# EventBridge rules per route_path
resource "aws_cloudwatch_event_rule" "userplatform_cpp_cloudwatch_event_rule" {
  for_each = toset(var.route_path)

  name = "${each.key}-rule"
  event_pattern = jsonencode({
    source = ["custom.api"],
    detail = {
      route_path = [each.key]
    }
  })
}

resource "aws_cloudwatch_event_target" "userplatform_cpp_cloudwatch_event_target" {
  for_each = toset(var.route_path)

  rule     = aws_cloudwatch_event_rule.userplatform_cpp_cloudwatch_event_rule[each.key].name
  arn      = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream[each.key].arn
  role_arn = aws_iam_role.userplatform_cpp_eventbridge_to_firehose_role.arn
}

# Output API keys for reference
output "userplatform_cpp_api_keys" {
  value = {
    for k, v in aws_api_gateway_api_key.userplatform_cpp_api_key :
    k => v.value
  }
  sensitive = true
}
