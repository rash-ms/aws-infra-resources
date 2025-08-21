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


data "aws_sqs_queue" "userplatform_cppv2_sqs_eu" {
  provider = aws.eu
  name     = "userplatform_cppv2_sqs_eu"
}

data "aws_sqs_queue" "userplatform_cppv2_sqs_dlq_eu" {
  provider = aws.eu
  name     = "userplatform_cppv2_sqs_dlq_eu"
}

data "aws_lambda_function" "cppv2_sqs_lambda_firehose_eu" {
  provider      = aws.eu
  function_name = "cppv2_sqs_lambda_firehose_eu"
}

# Reference the existing bucket
# data "aws_s3_bucket" "userplatform_bucket_eu" {
#   bucket = local.route_configs["eu"].bucket
# }


resource "aws_api_gateway_rest_api" "userplatform_cpp_rest_api_eu" {
  provider    = aws.eu
  name        = "userplatform_cpp_rest_api_eu"
  description = "REST API for Userplatform CPP EU Integration"
  endpoint_configuration {
    # types = ["REGIONAL"]
    types = ["EDGE"]
  }
}

resource "aws_api_gateway_resource" "userplatform_cpp_api_resource_eu" {
  provider    = aws.eu
  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id
  parent_id   = aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.root_resource_id
  path_part   = local.route_configs["eu"].route_path
}

resource "aws_api_gateway_method" "userplatform_cpp_api_method_eu" {
  provider         = aws.eu
  rest_api_id      = aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id
  resource_id      = aws_api_gateway_resource.userplatform_cpp_api_resource_eu.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}


# ARN format: arn:aws:apigateway:{region}:sqs:path/{account_id}/{queue_name}
# "arn:aws:apigateway:${local.route_configs["eu"].region}:sqs:path/${data.aws_sqs_queue.userplatform_cppv2_sqs_eu.name}"
# "arn:aws:apigateway:${local.route_configs["eu"].region}:sqs:path/${var.account_id}/${data.aws_sqs_queue.userplatform_cppv2_sqs_eu.name}"

resource "aws_api_gateway_integration" "userplatform_cpp_api_integration_eu" {
  provider                = aws.eu
  rest_api_id             = aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id
  resource_id             = aws_api_gateway_resource.userplatform_cpp_api_resource_eu.id
  http_method             = aws_api_gateway_method.userplatform_cpp_api_method_eu.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${local.route_configs["eu"].region}:sqs:path/${data.aws_sqs_queue.userplatform_cppv2_sqs_eu.name}"
  credentials             = aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.arn

  # WHEN_NO_MATCH: Pass raw request if Content-Type doesn't match any template
  # WHEN_NO_TEMPLATES: Strict – if any template exists, Content-Type must match exactly
  passthrough_behavior = "NEVER"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }
}

resource "aws_api_gateway_integration_response" "userplatform_cpp_apigateway_s3_integration_response_eu" {
  provider    = aws.eu
  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id
  resource_id = aws_api_gateway_resource.userplatform_cpp_api_resource_eu.id
  http_method = aws_api_gateway_method.userplatform_cpp_api_method_eu.http_method
  status_code = "200"

  depends_on = [
    aws_api_gateway_integration.userplatform_cpp_api_integration_eu,
    aws_api_gateway_method_response.userplatform_cpp_apigateway_s3_method_response_eu
  ]

  response_parameters = {
    "method.response.header.x-amz-request-id" = "integration.response.header.x-amz-request-id",
    "method.response.header.etag"             = "integration.response.header.ETag"
  }

  response_templates = {
    "application/json" = ""
  }
}

resource "aws_api_gateway_method_response" "userplatform_cpp_apigateway_s3_method_response_eu" {
  provider    = aws.eu
  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id
  resource_id = aws_api_gateway_resource.userplatform_cpp_api_resource_eu.id
  http_method = aws_api_gateway_method.userplatform_cpp_api_method_eu.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.x-amz-request-id" = true,
    "method.response.header.etag"             = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_api_key" "userplatform_cpp_api_key_eu" {
  provider = aws.eu
  name     = "eu_cpp_api_key"
  enabled  = true
}

resource "aws_api_gateway_usage_plan" "userplatform_cpp_api_usage_plan_eu" {
  provider = aws.eu
  name     = "eu_cpp_api_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id
    stage  = aws_api_gateway_stage.userplatform_cpp_api_stage_eu.stage_name
  }

  throttle_settings {
    rate_limit  = 1000
    burst_limit = 200
  }
}

resource "aws_api_gateway_usage_plan_key" "userplatform_cpp_api_usage_plan_key_eu" {
  provider      = aws.eu
  key_id        = aws_api_gateway_api_key.userplatform_cpp_api_key_eu.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.userplatform_cpp_api_usage_plan_eu.id
}

resource "aws_api_gateway_deployment" "userplatform_cpp_api_deployment_eu" {
  provider    = aws.eu
  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id

  depends_on = [
    aws_api_gateway_integration.userplatform_cpp_api_integration_eu,
    aws_api_gateway_method_response.userplatform_cpp_apigateway_s3_method_response_eu,
    aws_api_gateway_integration_response.userplatform_cpp_apigateway_s3_integration_response_eu
  ]

  triggers = {
    redeploy = sha1(jsonencode({
      request_templates       = aws_api_gateway_integration.userplatform_cpp_api_integration_eu.request_templates
      request_parameters      = aws_api_gateway_integration.userplatform_cpp_api_integration_eu.request_parameters
      uri                     = aws_api_gateway_integration.userplatform_cpp_api_integration_eu.uri
      integration_http_method = aws_api_gateway_integration.userplatform_cpp_api_integration_eu.integration_http_method
      credentials             = aws_api_gateway_integration.userplatform_cpp_api_integration_eu.credentials
      passthrough_behavior    = aws_api_gateway_integration.userplatform_cpp_api_integration_eu.passthrough_behavior
    }))
  }

  # triggers = {
  #   redeploy = "sqs-migration-${timestamp()}" # This will force a new deployment
  #   # OR use a static value that you increment manually:
  #   # redeploy = "sqs-migration-v2"
  # }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_api_gateway_stage" "userplatform_cpp_api_stage_eu" {
  provider      = aws.eu
  stage_name    = var.stage_name
  rest_api_id   = aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id
  deployment_id = aws_api_gateway_deployment.userplatform_cpp_api_deployment_eu.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.userplatform_cpp_api_gateway_logs_eu.arn
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

  depends_on = [aws_api_gateway_account.userplatform_cpp_api_account_settings_eu]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_method_settings" "userplatform_cpp_apigateway_method_settings_eu" {
  provider    = aws.eu
  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id
  stage_name  = aws_api_gateway_stage.userplatform_cpp_api_stage_eu.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true    # Enable CloudWatch metrics
    logging_level      = "ERROR" # Set logging level to INFO
    data_trace_enabled = true    # Enable data trace logging
  }
}

resource "aws_api_gateway_account" "userplatform_cpp_api_account_settings_eu" {
  provider            = aws.eu
  cloudwatch_role_arn = aws_iam_role.userplatform_cpp_api_gateway_cloudwatch_logging_role.arn

}

## --------------------------------------------------
## CLOUDWATCH RESOURCES
## --------------------------------------------------
## This section provisions Cloudwatch Log Group such as:
## - Log groups (APIGATEWAY, EVENTBRIDGE, FIREHOSE)
## --------------------------------------------------

resource "aws_cloudwatch_log_group" "userplatform_cpp_api_gateway_logs_eu" {
  provider          = aws.eu
  name              = "/aws/apigateway/userplatform_cpp_api_gateway_logs_eu"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "userplatform_cpp_event_bus_logs_eu" {
  provider          = aws.eu
  name              = "/aws/events/userplatform_cpp_event_bus_logs_eu"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "userplatform_cpp_firehose_to_s3_eu" {
  provider          = aws.eu
  name              = "/aws/kinesisfirehose/userplatform_cpp_firehose_to_s3_eu"
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

resource "aws_cloudwatch_event_bus" "userplatform_cpp_event_bus_eu" {
  provider = aws.eu
  name     = "userplatform_cpp_event_bus_eu"
}

resource "aws_cloudwatch_event_rule" "userplatform_cpp_eventbridge_to_firehose_rule_eu" {
  provider       = aws.eu
  name           = "userplatform_cpp_eventbridge_to_firehose_rule_eu"
  event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.name

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

resource "aws_cloudwatch_log_stream" "userplatform_cpp_firehose_to_s3_log_stream_eu" {
  provider       = aws.eu
  name           = "userplatform_cpp_firehose_to_s3_log_stream_eu"
  log_group_name = aws_cloudwatch_log_group.userplatform_cpp_firehose_to_s3_eu.name
}

resource "aws_kinesis_firehose_delivery_stream" "userplatform_cpp_firehose_delivery_stream_eu" {
  provider    = aws.eu
  name        = "userplatform_cpp_firehose_delivery_stream_eu"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.arn
    bucket_arn         = "arn:aws:s3:::${local.route_configs["eu"].bucket}"
    buffering_size     = 64
    compression_format = "UNCOMPRESSED"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.userplatform_cpp_firehose_to_s3_eu.name
      log_stream_name = aws_cloudwatch_log_stream.userplatform_cpp_firehose_to_s3_log_stream_eu.name
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

      # Add MetadataExtraction processor for dynamic partitioning
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

# resource "aws_cloudwatch_event_target" "userplatform_cpp_cloudwatch_event_target_eu" {
#   provider       = aws.eu
#   rule           = aws_cloudwatch_event_rule.userplatform_cpp_eventbridge_to_firehose_rule_eu.name
#   arn            = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_eu.arn
#   role_arn       = aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.arn
#   event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.name
# }
#
# resource "aws_cloudwatch_event_target" "userplatform_cpp_eventbridge_to_log_target_eu" {
#   provider       = aws.eu
#   rule           = aws_cloudwatch_event_rule.userplatform_cpp_eventbridge_to_firehose_rule_eu.name
#   arn            = aws_cloudwatch_log_group.userplatform_cpp_event_bus_logs_eu.arn
#   event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.name
#   depends_on     = [aws_cloudwatch_log_group.userplatform_cpp_event_bus_logs_eu]
# }

## --------------------------------------------------
## CLOUDWATCH MONITORING RESOURCES
## --------------------------------------------------
## This section provisions CloudWatch components such as:
## - Metric alarms for API Gateway (5XX and 4XX)
## - Metric alarms for Firehose (IncomingByte )
## - Metric alarms for Firehose (S3DataDeliveryFailed)
## --------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_apigw_5xx_errors_eu" {
  provider    = aws.eu
  alarm_name  = "Userplatform-CPP-APIGW-5XX-Errors-EU"
  namespace   = "AWS/ApiGateway"
  metric_name = "5XXError"
  dimensions = {
    ApiName = aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.name
    Stage   = aws_api_gateway_stage.userplatform_cpp_api_stage_eu.stage_name
  }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 2
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_description   = "Triggers on backend (5XX) integration failures"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_eu.arn]
}

resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_apigw_4xx_errors_eu" {
  provider    = aws.eu
  alarm_name  = "Userplatform-CPP-APIGW-4XX-Errors-EU"
  namespace   = "AWS/ApiGateway"
  metric_name = "4XXError"
  dimensions = {
    ApiName = aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.name
    Stage   = aws_api_gateway_stage.userplatform_cpp_api_stage_eu.stage_name
  }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 2
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_description   = "High rate of 4XX client errors detected"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_eu.arn]
}

# # Filter "MalformedDetail" on EventBridge
# resource "aws_cloudwatch_log_metric_filter" "userplatform_cpp_eventbridge_metric_filter_eu" {
#   provider       = aws.eu
#   name           = "Userplatform-CPP-MalformedDetailFiltered-EU"
#   log_group_name = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id}/${aws_api_gateway_stage.userplatform_cpp_api_stage_eu.stage_name}"
#   pattern        = "\"MalformedDetail\""
#
#   metric_transformation {
#     name          = "MalformedEvents"
#     namespace     = "EventBridge/Custom"
#     value         = "1"
#     default_value = 0
#   }
# }

resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_malformed_eventbridge_events_eu" {
  provider            = aws.eu
  alarm_name          = "Userplatform-CPP-EventBridge-MalformedEvents-Alarm-EU"
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
    aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_eu.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_firehose_no_data_24h_eu" {
  provider    = aws.eu
  alarm_name  = "Userplatform-CPP-Firehose-No-Incoming-Data-24h-EU"
  namespace   = "AWS/Firehose"
  metric_name = "IncomingBytes"
  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_eu.name
  }
  statistic           = "Sum"
  period              = 86400 # 24 hours
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "LessThanOrEqualToThreshold"
  alarm_description   = "Firehose inactivity for 24 hours"
  alarm_actions       = [aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_eu.arn]
}

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
  alarm_description   = "Firehose delivery to S3 failed"
  treat_missing_data  = "notBreaching"
  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_eu.name
  }
  alarm_actions = [aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_eu.arn]
}

## --------------------------------------------------------------
## ALERTING RESOURCES
## --------------------------------------------------------------
## This section provisions Alerting components such as:
## - SNS topics + Add to'aws_chatbot_slack_channel_configuration'
##   in `main_us_deployer`
## --------------------------------------------------------------

resource "aws_sns_topic" "userplatform_cpp_firehose_failure_alert_topic_eu" {
  provider = aws.eu
  name     = "userplatform_cpp_firehose_failure_alert_topic_eu"
}
