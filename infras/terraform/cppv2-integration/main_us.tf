# locals {
#   bucket_map = zipmap(var.deployer_region, var.userplatform_s3_bucket)
# }

locals {
  route_path      = var.route_path
  bucket_map      = var.userplatform_s3_bucket
  selected_bucket = local.bucket_map["us"]
}

# REST API Gateway
resource "aws_api_gateway_rest_api" "userplatform_cpp_rest_api" {
  provider = aws.us
  name     = "userplatform-cpp-rest-api"
}

# Create resources and methods for each route_path
resource "aws_api_gateway_resource" "userplatform_cpp_api_resources" {
  for_each = local.route_path

  provider    = aws.us
  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api.id
  parent_id   = aws_api_gateway_rest_api.userplatform_cpp_rest_api.root_resource_id
  path_part   = each.value
}

resource "aws_api_gateway_method" "userplatform_cpp_api_method" {
  for_each = aws_api_gateway_resource.userplatform_cpp_api_resources

  provider         = aws.us
  rest_api_id      = aws_api_gateway_rest_api.userplatform_cpp_rest_api.id
  resource_id      = each.value.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

# Deployment — depends directly on the methods (no null_resource needed)
resource "aws_api_gateway_deployment" "userplatform_cpp_api_deployment" {
  provider = aws.us

  depends_on = [
    for k in keys(local.route_path) : aws_api_gateway_method.userplatform_cpp_api_method[k]
  ]

  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api.id
}

# resource "aws_api_gateway_deployment" "userplatform_cpp_api_deployment" {
#   provider = aws.us

#   depends_on = [
#     aws_api_gateway_method.userplatform_cpp_api_method["us"],
#     aws_api_gateway_method.userplatform_cpp_api_method["eu"],
#     aws_api_gateway_method.userplatform_cpp_api_method["ap"]
#   ]


#   rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api.id
# }

# resource "null_resource" "gateway_dependencies" {
#   for_each = {
#     for route in local.route_path : route => route
#   }

#   provider = aws.us
#   triggers = {
#     method_id = aws_api_gateway_method.userplatform_cpp_api_method[each.key].id
#   }
# }

# resource "aws_api_gateway_deployment" "userplatform_cpp_api_deployment" {
#   provider = aws.us
#   depends_on = [
#     null_resource.gateway_dependencies["dev-us-collector"],
#     null_resource.gateway_dependencies["emea-us-collector"],
#     null_resource.gateway_dependencies["apac-us-collector"]
#   ]

#   rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api.id
# }

resource "aws_api_gateway_stage" "userplatform_cpp_api_stage" {
  provider      = aws.us
  deployment_id = aws_api_gateway_deployment.userplatform_cpp_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.userplatform_cpp_rest_api.id
  stage_name    = "cppv02"
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.userplatform_cpp_api_gateway_logs.arn
    format = jsonencode({
      requestId          = "$context.requestId",
      sourceIp           = "$context.identity.sourceIp",
      extendedRequestId  = "$context.extendedRequestId",
      apiId              = "$context.apiId",
      caller             = "$context.identity.caller",
      user               = "$context.identity.user",
      requestTime        = "$context.requestTime",
      httpMethod         = "$context.httpMethod",
      resourcePath       = "$context.resourcePath",
      status             = "$context.status",
      protocol           = "$context.protocol",
      responseLength     = "$context.responseLength"
      stage              = "$context.stage",
      userAgent          = "$context.identity.userAgent",
      integrationStatus  = "$context.integration.status",
      responseLatency    = "$context.responseLatency",
      integrationLatency = "$context.integration.latency",
      errorMessage       = "$context.error.message",
      errorResponseType  = "$context.error.responseType",
      requestTimeEpoch   = "$context.requestTimeEpoch"
    })
  }
  xray_tracing_enabled = true
}

resource "aws_api_gateway_integration" "userplatform_cpp_api_integration" {
  for_each = aws_api_gateway_resource.userplatform_cpp_api_resources

  provider                = aws.us
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
        "EventBusName": "${aws_cloudwatch_event_bus.userplatform_cpp_event_bus_us.name}"
      }
    ]
  }
  EOF
  }
}

# API Keys
resource "aws_api_gateway_api_key" "userplatform_cpp_api_key" {
  for_each = local.route_path

  provider = aws.us
  name     = "${each.key}-api-key"
  enabled  = true
}

# Usage Plans with high rate/burst
resource "aws_api_gateway_usage_plan" "userplatform_cpp_api_usage_plan" {
  for_each = local.route_path

  provider = aws.us
  name     = "${each.key}-usage-plan"

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
  for_each = local.route_path

  provider      = aws.us
  key_id        = aws_api_gateway_api_key.userplatform_cpp_api_key[each.key].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.userplatform_cpp_api_usage_plan[each.key].id
}

resource "aws_cloudwatch_log_group" "userplatform_cpp_api_gateway_logs" {
  provider          = aws.us
  name              = "/aws/apigateway/userplatform-cpp-rest-api"
  retention_in_days = 14
}

resource "aws_cloudwatch_event_bus" "userplatform_cpp_event_bus_us" {
  provider = aws.us
  name     = "userplatform_cpp_event_bus_us"
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
  role = aws_iam_role.userplatform_cpp_eventbridge_firehose_role.id
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
resource "aws_kinesis_firehose_delivery_stream" "userplatform_cpp_firehose_delivery_stream_us" {
  provider    = aws.us
  name        = "userplatform-cpp-firehose-delivery-stream-us"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.userplatform_cpp_eventbridge_firehose_role.arn
    bucket_arn          = "arn:aws:s3:::${local.selected_bucket}"
    prefix              = "raw/cppv2-collector/"
    error_output_prefix = "raw/cppv2-errors/"
    compression_format  = "UNCOMPRESSED"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/userplatform-cpp-firehose-delivery-stream-us"
      log_stream_name = "S3Delivery"
    }

    processing_configuration {
      enabled = false
    }
  }
}

resource "aws_sns_topic" "userplatform_cpp_firehose_failure_us" {
  provider = aws.us
  name     = "userplatform-cpp-irehose-failure-alert-us"
}

# CloudWatch alarm for Firehose failure delivery
resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_firehose_failure_alarm_us" {
  provider            = aws.us
  alarm_name          = "Userplatform-CPP-FirehoseDeliveryFailures-US"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DeliveryToS3.Failure"
  namespace           = "AWS/Firehose"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert when Firehose fails to deliver data to S3"
  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_us.name
  }
  alarm_actions = [aws_sns_topic.userplatform_cpp_firehose_failure_us.arn]
}

# EventBridge rules per route_path
resource "aws_cloudwatch_event_rule" "userplatform_cpp_cloudwatch_event_rule_us" {
  provider = aws.us
  name     = "userplatform-cpp-eventbridge-rule-us"

  event_pattern = jsonencode({
    detail = {
      market = ["US"]
    }
  })
}

resource "aws_cloudwatch_event_target" "userplatform_cpp_cloudwatch_event_target_us" {
  provider = aws.us
  rule     = aws_cloudwatch_event_rule.userplatform_cpp_cloudwatch_event_rule_us.name
  arn      = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_us.arn
  role_arn = aws_iam_role.userplatform_cpp_eventbridge_firehose_role.arn
}
