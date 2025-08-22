## --------------------------------------------------
## IAM ROLES & POLICIES
## --------------------------------------------------
## This section provisions IAM components such as:
## - Execution roles for API Gateway, EventBridge, and Firehose
## - Policies granting PutEvents, PutRecord, and other actions
## - Cross-region access roles
## - Trust relationships for service integrations
## --------------------------------------------------

data "aws_sqs_queue" "userplatform_cppv2_sqs_us" {
  provider = aws.us
  name     = "userplatform_cppv2_sqs_us"
}

data "aws_sqs_queue" "userplatform_cppv2_sqs_dlq_us" {
  provider = aws.us
  name     = "userplatform_cppv2_sqs_dlq_us"
}

data "aws_lambda_function" "cppv2_sqs_lambda_firehose_us" {
  provider      = aws.us
  function_name = "cppv2_sqs_lambda_firehose_us"
}

# Reference the existing bucket
data "aws_s3_bucket" "userplatform_bucket_us" {
  bucket = local.route_configs["us"].bucket
}

resource "aws_iam_role" "cpp_integration_apigw_evtbridge_firehose_logs_role" {
  name = "cpp_integration_apigw_evtbridge_firehose_logs_role"
  # permissions_boundary = "arn:aws:iam::${var.account_id}:policy/tenant-${var.tenant_name}-boundary"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "apigateway.amazonaws.com",
            "events.amazonaws.com",
            "firehose.amazonaws.com",
            "chatbot.amazonaws.com",
            "lambda.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cpp_integration_apigw_evtbridge_firehose_logs_policy" {
  name = "cpp_integration_apigw_evtbridge_firehose_logs_policy"
  role = aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # EventBridge PutEvents (for API Gateway)
      {
        Effect = "Allow",
        Action = [
          "events:PutEvents"
        ],
        Resource = [
          "${aws_cloudwatch_event_bus.userplatform_cpp_event_bus_us.arn}",
          "${aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.arn}",
          "${aws_cloudwatch_event_bus.userplatform_cpp_event_bus_ap.arn}"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage"
        ],
        Resource = "*"
      },
      {
        Effect : "Allow",
        Action : [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ],
        Resource = "*"
      },
      # Firehose PutRecord from EventBridge
      {
        Effect = "Allow",
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ],
        Resource = [
          aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_us.arn,
          aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_eu.arn,
          aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_ap.arn
        ]
      },

      # Firehose Access to S3
      {
        Effect = "Allow",
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = [
          "arn:aws:s3:::${local.route_configs["us"].bucket}",
          "arn:aws:s3:::${local.route_configs["us"].bucket}/*",
          "arn:aws:s3:::${local.route_configs["eu"].bucket}",
          "arn:aws:s3:::${local.route_configs["eu"].bucket}/*",
          "arn:aws:s3:::${local.route_configs["ap"].bucket}",
          "arn:aws:s3:::${local.route_configs["ap"].bucket}/*"

        ]
      },

      # CloudWatch Logs from API-Gateway, EventBridge Rule, Firehose
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "${aws_cloudwatch_log_group.userplatform_cpp_api_gateway_logs_us.arn}:*",
          "${aws_cloudwatch_log_group.userplatform_cpp_api_gateway_logs_eu.arn}:*",
          "${aws_cloudwatch_log_group.userplatform_cpp_api_gateway_logs_ap.arn}:*",
          "${aws_cloudwatch_log_group.userplatform_cpp_event_bus_logs_us.arn}:*",
          "${aws_cloudwatch_log_group.userplatform_cpp_event_bus_logs_eu.arn}:*",
          "${aws_cloudwatch_log_group.userplatform_cpp_event_bus_logs_ap.arn}:*",
          "${aws_cloudwatch_log_group.userplatform_cpp_firehose_to_s3_us.arn}:*",
          "${aws_cloudwatch_log_group.userplatform_cpp_firehose_to_s3_eu.arn}:*",
          "${aws_cloudwatch_log_group.userplatform_cpp_firehose_to_s3_ap.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "userplatform_cpp_chatbot_attach" {
  role       = aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role" "userplatform_cpp_api_gateway_cloudwatch_logging_role" {
  name = "userplatform_cpp_api_gateway_cloudwatch_logging_role"
  # permissions_boundary = "arn:aws:iam::${var.account_id}:policy/tenant-${var.tenant_name}-boundary"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy" "userplatform_cpp_api_gateway_cloudwatch_logging_policy" {
  name = "userplatform_cpp_api_gateway_cloudwatch_logging_policy"
  role = aws_iam_role.userplatform_cpp_api_gateway_cloudwatch_logging_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:GetLogEvents",
        "logs:FilterLogEvents"
      ],
      Resource = "*"
    }]
  })
}

## --------------------------------------------------
## API GATEWAY RESOURCES
## --------------------------------------------------
## This section provisions API Gateway components such as:
## - REST-API definitions
## - Routes and Methods
## - Integration with EventBridge
## - Api Key and Usage Plan
## - Stage and deployment management
## --------------------------------------------------

resource "aws_api_gateway_rest_api" "userplatform_cpp_rest_api_us" {
  provider    = aws.us
  name        = "userplatform_cpp_rest_api_us"
  description = "REST API for Userplatform CPP US Integration"
  endpoint_configuration {
    # types = ["REGIONAL"]
    types = ["EDGE"]
  }
}

resource "aws_api_gateway_resource" "userplatform_cpp_api_resource_us" {
  provider    = aws.us
  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
  parent_id   = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.root_resource_id
  path_part   = local.route_configs["us"].route_path
}

resource "aws_api_gateway_method" "userplatform_cpp_api_method_us" {
  provider         = aws.us
  rest_api_id      = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
  resource_id      = aws_api_gateway_resource.userplatform_cpp_api_resource_us.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}


locals {
  force_redeploy_us = "cppv2-release-v0"

  # force_redeploy_us = sha1(jsonencode({
  #   uri                     = aws_api_gateway_integration.userplatform_cpp_api_integration_us.uri
  #   request_templates       = aws_api_gateway_integration.userplatform_cpp_api_integration_us.request_templates
  #   request_parameters      = aws_api_gateway_integration.userplatform_cpp_api_integration_us.request_parameters
  #   integration_http_method = aws_api_gateway_integration.userplatform_cpp_api_integration_us.integration_http_method
  #   credentials             = aws_api_gateway_integration.userplatform_cpp_api_integration_us.credentials
  #   passthrough_behavior    = aws_api_gateway_integration.userplatform_cpp_api_integration_us.passthrough_behavior
  # }))
}

resource "aws_api_gateway_integration" "userplatform_cpp_api_integration_us" {
  provider                = aws.us
  rest_api_id             = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
  resource_id             = aws_api_gateway_resource.userplatform_cpp_api_resource_us.id
  http_method             = aws_api_gateway_method.userplatform_cpp_api_method_us.http_method
  integration_http_method = "POST"
  type                    = "AWS"

  #   uri                     = "arn:aws:apigateway:${local.route_configs["us"].region}:sqs:path/${var.account_id}/${data.aws_sqs_queue.userplatform_cppv2_sqs_us.name}"
  #   credentials             = aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.arn
  #
  #   # WHEN_NO_MATCH: Pass raw request if Content-Type doesn't match any template
  #   # WHEN_NO_TEMPLATES: Strict – if any template exists, Content-Type must match exactly
  #   passthrough_behavior = "NEVER"
  #
  #   request_parameters = {
  #     "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  #   }
  #
  #   request_templates = {
  #     "application/json" = "Action=SendMessage&MessageBody=$input.body"
  #   }

  uri         = "arn:aws:apigateway:${local.route_configs["us"].region}:events:path//"
  credentials = aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.arn

  # WHEN_NO_MATCH: Pass raw request if Content-Type doesn't match any template
  # WHEN_NO_TEMPLATES: Strict – if any template exists, Content-Type must match exactly
  passthrough_behavior = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = <<EOF
#set($context.requestOverride.header.X-Amz-Target = "AWSEvents.PutEvents")
#set($context.requestOverride.header.Content-Type = "application/x-amz-json-1.1")
{
  "Entries": [
    {
      "Source": "cpp-api-streamhook",
      "DetailType": "${local.route_configs["us"].route_path}",
      "Detail": "$util.escapeJavaScript($input.body)",
      "EventBusName": "${local.route_configs["us"].event_bus}"
    }
  ]
}
EOF
  }
}



# resource "aws_api_gateway_integration_response" "userplatform_cpp_apigateway_s3_integration_response_us" {
#   provider    = aws.us
#   rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
#   resource_id = aws_api_gateway_resource.userplatform_cpp_api_resource_us.id
#   http_method = aws_api_gateway_method.userplatform_cpp_api_method_us.http_method
#   status_code = "200"
#
#   depends_on = [
#     aws_api_gateway_integration.userplatform_cpp_api_integration_us,
#     aws_api_gateway_method_response.userplatform_cpp_apigateway_s3_method_response_us
#   ]
#
#   response_parameters = {
#     "method.response.header.x-amz-request-id" = "integration.response.header.x-amz-request-id",
#     "method.response.header.etag"             = "integration.response.header.ETag"
#   }
#
#   response_templates = {
#     "application/json" = ""
#   }
# }
#
# resource "aws_api_gateway_method_response" "userplatform_cpp_apigateway_s3_method_response_us" {
#   provider    = aws.us
#   rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
#   resource_id = aws_api_gateway_resource.userplatform_cpp_api_resource_us.id
#   http_method = aws_api_gateway_method.userplatform_cpp_api_method_us.http_method
#   status_code = "200"
#
#   response_parameters = {
#     "method.response.header.x-amz-request-id" = true,
#     "method.response.header.etag"             = true
#   }
#
#   response_models = {
#     "application/json" = "Empty"
#   }
# }

resource "aws_api_gateway_api_key" "userplatform_cpp_api_key_us" {
  provider = aws.us
  name     = "us_cpp_api_key"
  enabled  = true
}

resource "aws_api_gateway_usage_plan" "userplatform_cpp_api_usage_plan_us" {
  provider = aws.us
  name     = "us_cpp_api_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
    stage  = aws_api_gateway_stage.userplatform_cpp_api_stage_us.stage_name
  }

  throttle_settings {
    rate_limit  = 1000
    burst_limit = 200
  }
}

resource "aws_api_gateway_usage_plan_key" "userplatform_cpp_api_usage_plan_key_us" {
  provider      = aws.us
  key_id        = aws_api_gateway_api_key.userplatform_cpp_api_key_us.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.userplatform_cpp_api_usage_plan_us.id
}


resource "aws_api_gateway_deployment" "userplatform_cpp_api_deployment_us" {
  provider    = aws.us
  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id

  depends_on = [
    aws_api_gateway_integration.userplatform_cpp_api_integration_us,
    # aws_api_gateway_method_response.userplatform_cpp_apigateway_s3_method_response_us,
    # aws_api_gateway_integration_response.userplatform_cpp_apigateway_s3_integration_response_us
  ]

  triggers = {
    redeploy = local.force_redeploy_us
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_deployment" "cppv2_base_deployment_us" {
  provider    = aws.us
  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id

  depends_on = [aws_api_gateway_deployment.userplatform_cpp_api_deployment_us]

  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [aws_api_gateway_deployment.userplatform_cpp_api_deployment_us]
  }

}

resource "aws_api_gateway_stage" "userplatform_cpp_api_stage_us" {
  provider    = aws.us
  stage_name  = var.stage_name
  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
  # deployment_id = aws_api_gateway_deployment.userplatform_cpp_api_deployment_us.id
  deployment_id = aws_api_gateway_deployment.cppv2_base_deployment_us.id



  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.userplatform_cpp_api_gateway_logs_us.arn
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
  depends_on           = [aws_api_gateway_account.userplatform_cpp_api_account_settings_us]
}

resource "aws_api_gateway_method_settings" "userplatform_cpp_apigateway_method_settings_us" {
  provider    = aws.us
  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
  stage_name  = aws_api_gateway_stage.userplatform_cpp_api_stage_us.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true    # Enable CloudWatch metrics
    logging_level      = "ERROR" # Set logging level to INFO
    data_trace_enabled = true    # Enable data trace logging
  }
}

resource "aws_api_gateway_account" "userplatform_cpp_api_account_settings_us" {
  provider            = aws.us
  cloudwatch_role_arn = aws_iam_role.userplatform_cpp_api_gateway_cloudwatch_logging_role.arn

}

## --------------------------------------------------
## CLOUDWATCH RESOURCES
## --------------------------------------------------
## This section provisions Cloudwatch Log Group such as:
## - Log groups (APIGATEWAY, EVENTBRIDGE, FIREHOSE)
## --------------------------------------------------

resource "aws_cloudwatch_log_group" "userplatform_cpp_api_gateway_logs_us" {
  provider          = aws.us
  name              = "/aws/apigateway/userplatform_cpp_api_gateway_logs_us"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "userplatform_cpp_event_bus_logs_us" {
  provider          = aws.us
  name              = "/aws/events/userplatform_cpp_event_bus_logs_us"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "userplatform_cpp_firehose_to_s3_us" {
  provider          = aws.us
  name              = "/aws/kinesisfirehose/userplatform_cpp_firehose_to_s3_us"
  retention_in_days = 7
}

## --------------------------------------------------
## EVENTBRIDGE RESOURCES
## --------------------------------------------------
## This section provisions EventBridge components such as:
## - Custom event buses (regional)
## - Rules for routing and filtering events
## - Event targets (Firehose, Logs, etc.)
## --------------------------------------------------

resource "aws_cloudwatch_event_bus" "userplatform_cpp_event_bus_us" {
  provider = aws.us
  name     = "userplatform_cpp_event_bus_us"
}

resource "aws_cloudwatch_event_rule" "userplatform_cpp_eventbridge_to_firehose_rule_us" {
  provider       = aws.us
  name           = "userplatform_cpp_eventbridge_to_firehose_rule_us"
  event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_us.name

  event_pattern = jsonencode({
    "source" : ["cpp-api-streamhook"]
  })

}

## --------------------------------------------------
## KINESIS FIREHOSE RESOURCES
## --------------------------------------------------
## This section provisions Kinesis Firehose components such as:
## - Delivery streams for streaming event data
## - Integration with S3
## - Used as EventBridge targets for processing
## --------------------------------------------------

resource "aws_cloudwatch_log_stream" "userplatform_cpp_firehose_to_s3_log_stream_us" {
  provider       = aws.us
  name           = "userplatform_cpp_firehose_to_s3_log_stream_us"
  log_group_name = aws_cloudwatch_log_group.userplatform_cpp_firehose_to_s3_us.name
}

resource "aws_kinesis_firehose_delivery_stream" "userplatform_cpp_firehose_delivery_stream_us" {
  provider    = aws.us
  name        = "userplatform_cpp_firehose_delivery_stream_us"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.arn
    bucket_arn         = "arn:aws:s3:::${local.route_configs["us"].bucket}"
    buffering_size     = 64
    compression_format = "UNCOMPRESSED"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.userplatform_cpp_firehose_to_s3_us.name
      log_stream_name = aws_cloudwatch_log_stream.userplatform_cpp_firehose_to_s3_log_stream_us.name
    }

    dynamic_partitioning_configuration {
      enabled = "true"
    }

    prefix              = "raw/cppv2-raw/source=!{partitionKeyFromQuery:source}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "raw/cppv2-raw-errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"


    processing_configuration {
      enabled = "true"

      # New line delimiter processor
      processors {
        type = "AppendDelimiterToRecord"
      }

      # MetadataExtraction processor for dynamic partitioning
      processors {
        type = "MetadataExtraction"

        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }

        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{source: .source}"
        }
      }
    }
  }
}

# resource "aws_cloudwatch_event_target" "userplatform_cpp_cloudwatch_event_target_us" {
#   provider       = aws.us
#   rule           = aws_cloudwatch_event_rule.userplatform_cpp_eventbridge_to_firehose_rule_us.name
#   arn            = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_us.arn
#   role_arn       = aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.arn
#   event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_us.name
# }
#
# resource "aws_cloudwatch_event_target" "userplatform_cpp_eventbridge_to_log_target_us" {
#   provider       = aws.us
#   rule           = aws_cloudwatch_event_rule.userplatform_cpp_eventbridge_to_firehose_rule_us.name
#   arn            = aws_cloudwatch_log_group.userplatform_cpp_event_bus_logs_us.arn
#   event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_us.name
#   depends_on     = [aws_cloudwatch_log_group.userplatform_cpp_event_bus_logs_us]
# }

## --------------------------------------------------
## CLOUDWATCH MONITORING RESOURCES
## --------------------------------------------------
## This section provisions CloudWatch components such as:
## - Metric alarms for API Gateway (5XX and 4XX)
## - Metric alarms for Firehose (IncomingByte )
## - Metric alarms for Firehose (S3DataDeliveryFailed)
## --------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_apigw_5xx_errors_us" {
  provider    = aws.us
  alarm_name  = "Userplatform-CPP-APIGW-5XX-Errors-US"
  namespace   = "AWS/ApiGateway"
  metric_name = "5XXError"
  dimensions = {
    ApiName = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.name
    Stage   = aws_api_gateway_stage.userplatform_cpp_api_stage_us.stage_name
  }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 2
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_description   = "Triggers on backend (5XX) integration failures"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_us.arn]
}

resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_apigw_4xx_errors_us" {
  provider    = aws.us
  alarm_name  = "Userplatform-CPP-APIGW-4XX-Errors-US"
  namespace   = "AWS/ApiGateway"
  metric_name = "4XXError"
  dimensions = {
    ApiName = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.name
    Stage   = aws_api_gateway_stage.userplatform_cpp_api_stage_us.stage_name
  }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 2
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_description   = "High rate of 4XX client errors detected"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_us.arn]
}

# # Filter "MalformedDetail" on EventBridge
# resource "aws_cloudwatch_log_metric_filter" "userplatform_cpp_eventbridge_metric_filter_us" {
#   provider       = aws.us
#   name           = "Userplatform-CPP-MalformedDetailFiltered-US"
#   log_group_name = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id}/${aws_api_gateway_stage.userplatform_cpp_api_stage_us.stage_name}"
#   pattern        = "\"MalformedDetail\""
#
#   metric_transformation {
#     name          = "MalformedEvents"
#     namespace     = "EventBridge/Custom"
#     value         = "1"
#     default_value = 0
#   }
# }

resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_malformed_eventbridge_events_us" {
  provider            = aws.us
  alarm_name          = "Userplatform-CPP-EventBridge-MalformedEvents-Alarm-US"
  alarm_description   = "Triggered Malformed Payload To EventBridge"
  namespace           = "EventBridge/Custom"
  metric_name         = "MalformedEvents"
  statistic           = "Sum"
  period              = 60 # 1 minutes
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_us.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_firehose_no_data_24h_us" {
  provider    = aws.us
  alarm_name  = "Userplatform-CPP-Firehose-No-Incoming-Data-24h-US"
  namespace   = "AWS/Firehose"
  metric_name = "IncomingBytes"
  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_us.name
  }
  statistic           = "Sum"
  period              = 86400 # 24 hours
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "LessThanOrEqualToThreshold"
  alarm_description   = "Firehose inactivity for 24 hours"
  alarm_actions       = [aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_us.arn]
}

resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_firehose_failure_alarm_us" {
  provider            = aws.us
  alarm_name          = "Userplatform-CPP-FirehoseDeliveryFailures-US"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DeliveryToS3.DataDeliveryFailed"
  namespace           = "AWS/Firehose"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Firehose delivery to S3 failed"
  treat_missing_data  = "notBreaching"
  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_us.name
  }
  alarm_actions = [aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_us.arn]
}

## --------------------------------------------------
## ALERTING RESOURCES
## --------------------------------------------------
## This section provisions Alerting components such as:
## - SNS topics
## - Slack for alert notifications
## --------------------------------------------------

resource "aws_sns_topic" "userplatform_cpp_firehose_failure_alert_topic_us" {
  provider = aws.us
  name     = "userplatform_cpp_firehose_failure_alert_topic_us"
}

# resource "aws_chatbot_slack_channel_configuration" "userplatform_cpp_firehose_alerts_to_slack" {
#   configuration_name = "userplatform_cpp_firehose_alerts_to_slack"
#   slack_channel_id   = var.slack_channel_id
#   slack_team_id      = var.slack_workspace_id

#   sns_topic_arns = [
#     aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_us.arn,
#     aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_eu.arn,
#     aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_ap.arn
#   ]

#   iam_role_arn  = aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.arn
#   logging_level = "ERROR"
# }
