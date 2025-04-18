# # REST API Gateway
# resource "aws_api_gateway_rest_api" "userplatform_cpp_rest_api_ap" {
#   provider    = aws.ap
#   name        = "userplatform_cpp_rest_api_ap"
#   description = "REST API for Userplatform CPP AP Integration"
#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }
# }

# # Create resources and methods for each route_path
# resource "aws_api_gateway_resource" "userplatform_cpp_api_resource_ap" {
#   provider    = aws.ap
#   rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id
#   parent_id   = aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.root_resource_id
#   path_part   = local.route_configs["ap"].route_path
# }


# resource "aws_api_gateway_method" "userplatform_cpp_api_method_ap" {
#   provider         = aws.ap
#   rest_api_id      = aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id
#   resource_id      = aws_api_gateway_resource.userplatform_cpp_api_resource_ap.id
#   http_method      = "POST"
#   authorization    = "NONE"
#   api_key_required = true
# }

# resource "aws_api_gateway_integration" "userplatform_cpp_api_integration_ap" {
#   provider                = aws.ap
#   rest_api_id             = aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id
#   resource_id             = aws_api_gateway_resource.userplatform_cpp_api_resource_ap.id
#   http_method             = aws_api_gateway_method.userplatform_cpp_api_method_ap.http_method
#   integration_http_method = "POST"
#   type                    = "AWS"
#   # uri                     = "arn:aws:apigateway:ap-northeast-1:events:path//"
#   uri         = "arn:aws:apigateway:${local.route_configs["ap"].region}:events:path//"
#   credentials = aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.arn

#   # WHEN_NO_MATCH: Pass raw request if Content-Type doesn't match any template
#   # WHEN_NO_TEMPLATES: Strict – if any template exists, Content-Type must match exactly
#   passthrough_behavior = "WHEN_NO_TEMPLATES"

#   request_templates = {
#     "application/json" = templatefile("${path.module}/templates/apigateway_reqst_template.tftpl", {
#       event_bus_arn = local.route_configs["ap"].event_bus
#     })
#   }
# }


# resource "aws_api_gateway_integration_response" "userplatform_cpp_apigateway_s3_integration_response_ap" {
#   provider    = aws.ap
#   rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id
#   resource_id = aws_api_gateway_resource.userplatform_cpp_api_resource_ap.id
#   http_method = aws_api_gateway_method.userplatform_cpp_api_method_ap.http_method
#   status_code = "200"

#   depends_on = [
#     aws_api_gateway_integration.userplatform_cpp_api_integration_ap,
#     aws_api_gateway_method_response.userplatform_cpp_apigateway_s3_method_response_ap
#   ]

#   response_parameters = {
#     "method.response.header.x-amz-request-id" = "integration.response.header.x-amz-request-id",
#     "method.response.header.etag"             = "integration.response.header.ETag"
#   }

#   response_templates = {
#     "application/json" = ""
#   }
# }


# resource "aws_api_gateway_method_response" "userplatform_cpp_apigateway_s3_method_response_ap" {
#   provider    = aws.ap
#   rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id
#   resource_id = aws_api_gateway_resource.userplatform_cpp_api_resource_ap.id
#   http_method = aws_api_gateway_method.userplatform_cpp_api_method_ap.http_method
#   status_code = "200"

#   response_parameters = {
#     "method.response.header.x-amz-request-id" = true,
#     "method.response.header.etag"             = true
#   }

#   response_models = {
#     "application/json" = "Empty"
#   }
# }

# # API Keys
# resource "aws_api_gateway_api_key" "userplatform_cpp_api_key_ap" {
#   provider = aws.ap
#   name     = "ap_cpp_api_key"
#   enabled  = true
# }

# # Usage Plans with high rate/burst
# resource "aws_api_gateway_usage_plan" "userplatform_cpp_api_usage_plan_ap" {
#   provider = aws.ap
#   name     = "ap_cpp_api_usage_plan"

#   api_stages {
#     api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id
#     stage  = aws_api_gateway_stage.userplatform_cpp_api_stage_ap.stage_name
#   }

#   throttle_settings {
#     rate_limit  = 1000
#     burst_limit = 200
#   }
# }

# resource "aws_api_gateway_usage_plan_key" "userplatform_cpp_api_usage_plan_key_ap" {
#   provider      = aws.ap
#   key_id        = aws_api_gateway_api_key.userplatform_cpp_api_key_ap.id
#   key_type      = "API_KEY"
#   usage_plan_id = aws_api_gateway_usage_plan.userplatform_cpp_api_usage_plan_ap.id
# }

# resource "aws_cloudwatch_log_group" "userplatform_cpp_api_gateway_logs_ap" {
#   provider          = aws.ap
#   name              = "/aws/apigateway/userplatform_cpp_api_gateway_logs_ap"
#   retention_in_days = 14
# }

# resource "aws_cloudwatch_log_group" "userplatform_cpp_event_bus_logs_ap" {
#   provider          = aws.ap
#   name              = "/aws/events/userplatform_cpp_event_bus_logs_ap"
#   retention_in_days = 14
# }

# resource "aws_api_gateway_deployment" "userplatform_cpp_api_deployment_ap" {
#   provider    = aws.ap
#   rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id

#   depends_on = [
#     aws_api_gateway_integration.userplatform_cpp_api_integration_ap,
#     aws_api_gateway_method_response.userplatform_cpp_apigateway_s3_method_response_ap,
#     aws_api_gateway_integration_response.userplatform_cpp_apigateway_s3_integration_response_ap
#   ]
# }

# resource "aws_api_gateway_stage" "userplatform_cpp_api_stage_ap" {
#   provider      = aws.ap
#   stage_name    = var.stage_name
#   rest_api_id   = aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id
#   deployment_id = aws_api_gateway_deployment.userplatform_cpp_api_deployment_ap.id

#   access_log_settings {
#     destination_arn = aws_cloudwatch_log_group.userplatform_cpp_api_gateway_logs_ap.arn
#     format = jsonencode({
#       requestId          = "$context.requestId",
#       sourceIp           = "$context.identity.sourceIp",
#       extendedRequestId  = "$context.extendedRequestId",
#       apiId              = "$context.apiId",
#       caller             = "$context.identity.caller",
#       user               = "$context.identity.user",
#       requestTime        = "$context.requestTime",
#       httpMethod         = "$context.httpMethod",
#       resourcePath       = "$context.resourcePath",
#       status             = "$context.status",
#       protocol           = "$context.protocol",
#       responseLength     = "$context.responseLength"
#       stage              = "$context.stage",
#       userAgent          = "$context.identity.userAgent",
#       integrationStatus  = "$context.integration.status",
#       responseLatency    = "$context.responseLatency",
#       integrationLatency = "$context.integration.latency",
#       errorMessage       = "$context.error.message",
#       errorResponseType  = "$context.error.responseType",
#       requestTimeEpoch   = "$context.requestTimeEpoch"
#     })
#   }
#   xray_tracing_enabled = true
#   depends_on           = [aws_api_gateway_account.userplatform_cpp_api_account_settings_ap]
# }

# # Configure Method Settings for Detailed Logging
# resource "aws_api_gateway_method_settings" "userplatform_cpp_apigateway_method_settings_ap" {
#   provider    = aws.ap
#   rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id
#   stage_name  = aws_api_gateway_stage.userplatform_cpp_api_stage_ap.stage_name
#   method_path = "*/*" # Apply to all methods and resources

#   settings {
#     metrics_enabled    = true    # Enable CloudWatch metrics
#     logging_level      = "ERROR" # Set logging level to INFO
#     data_trace_enabled = true    # Enable data trace logging
#   }
# }

# resource "aws_api_gateway_account" "userplatform_cpp_api_account_settings_ap" {
#   provider            = aws.ap
#   cloudwatch_role_arn = aws_iam_role.userplatform_cpp_api_gateway_cloudwatch_logging_role.arn

# }

# resource "aws_cloudwatch_event_bus" "userplatform_cpp_event_bus_ap" {
#   provider = aws.ap
#   name     = "userplatform_cpp_event_bus_ap"
# }

# # Firehose delivery streams + SNS for failure
# resource "aws_kinesis_firehose_delivery_stream" "userplatform_cpp_firehose_delivery_stream_ap" {
#   provider    = aws.ap
#   name        = "userplatform_cpp_firehose_delivery_stream_ap"
#   destination = "extended_s3"

#   extended_s3_configuration {
#     role_arn            = aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.arn
#     bucket_arn          = "arn:aws:s3:::${local.route_configs["ap"].bucket}"
#     prefix              = "raw/cppv2-collector/"
#     error_output_prefix = "raw/cppv2-errors/"
#     compression_format  = "UNCOMPRESSED"

#     cloudwatch_logging_options {
#       enabled         = true
#       log_group_name  = aws_cloudwatch_log_group.userplatform_cpp_firehose_to_s3_ap.name
#       log_stream_name = aws_cloudwatch_log_stream.userplatform_cpp_firehose_to_s3_log_stream_ap.name
#     }

#     processing_configuration {
#       enabled = "true"

#       # New line delimiter processor
#       processors {
#         type = "AppendDelimiterToRecord"
#       }
#     }
#   }
# }

# # EventBridge rules per route_path
# resource "aws_cloudwatch_event_rule" "userplatform_cpp_eventbridge_to_firehose_rule_ap" {
#   provider       = aws.ap
#   name           = "userplatform_cpp_eventbridge_to_firehose_rule_ap"
#   event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_ap.name

#   event_pattern = jsonencode({
#     "source" : ["cpp-api-streamhook"]
#   })

# }

# resource "aws_cloudwatch_log_group" "userplatform_cpp_firehose_to_s3_ap" {
#   provider          = aws.ap
#   name              = "/aws/kinesisfirehose/userplatform_cpp_firehose_to_s3_ap"
#   retention_in_days = 30
# }

# resource "aws_cloudwatch_log_stream" "userplatform_cpp_firehose_to_s3_log_stream_ap" {
#   provider       = aws.ap
#   name           = "userplatform_cpp_firehose_to_s3_log_stream_ap"
#   log_group_name = aws_cloudwatch_log_group.userplatform_cpp_firehose_to_s3_ap.name
# }

# # CloudWatch alarm for Apigateway 5XX Server Errors (backend failure)
# resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_apigw_5xx_errors_ap" {
#   provider    = aws.ap
#   alarm_name  = "Userplatform-CPP-APIGW-5XX-Errors-AP"
#   namespace   = "AWS/ApiGateway"
#   metric_name = "5XXError"
#   dimensions = {
#     ApiName = aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.name
#     Stage   = aws_api_gateway_stage.userplatform_cpp_api_stage_ap.stage_name
#   }
#   statistic           = "Sum"
#   period              = 300
#   evaluation_periods  = 1
#   threshold           = 1
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   alarm_description   = "Triggers when backend integrations fail (5XX)"
#   alarm_actions       = [aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_ap.arn]
# }

# # CloudWatch alarm for Apigateway 4XX Client Errors (bad requests)
# resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_apigw_4xx_errors_ap" {
#   provider    = aws.ap
#   alarm_name  = "Userplatform-CPP-APIGW-4XX-Errors-AP"
#   namespace   = "AWS/ApiGateway"
#   metric_name = "4XXError"
#   dimensions = {
#     ApiName = aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.name
#     Stage   = aws_api_gateway_stage.userplatform_cpp_api_stage_ap.stage_name
#   }
#   statistic           = "Sum"
#   period              = 300
#   evaluation_periods  = 1
#   threshold           = 5
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   alarm_description   = "Triggers on high client-side error rate"
#   alarm_actions       = [aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_ap.arn]
# }

# # CloudWatch alarm for EventBridge Failed Invocation to Target
# resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_eventbridge_failed_invocations_ap" {
#   provider    = aws.ap
#   alarm_name  = "Userplatform-CPP-EventBridge-Failed-Invocations-AP"
#   namespace   = "AWS/Events"
#   metric_name = "FailedInvocations"
#   dimensions = {
#     RuleName     = aws_cloudwatch_event_rule.userplatform_cpp_eventbridge_to_firehose_rule_ap.name
#     EventBusName = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_ap.name
#   }
#   statistic           = "Sum"
#   period              = 300
#   evaluation_periods  = 1
#   threshold           = 1
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   alarm_description   = "EventBridge failed to invoke a target"
#   alarm_actions       = [aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_ap.arn]
# }

# # CloudWatch alarm for Firehose for No Incoming Data for 24hrs
# resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_firehose_no_data_24h_ap" {
#   provider    = aws.ap
#   alarm_name  = "Userplatform-CPP-Firehose-No-Incoming-Data-24h-AP"
#   namespace   = "AWS/Firehose"
#   metric_name = "IncomingBytes"
#   dimensions = {
#     DeliveryStreamName = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_ap.name
#   }
#   statistic           = "Sum"
#   period              = 300 #86400 # 24 hours 
#   evaluation_periods  = 1
#   threshold           = 0
#   comparison_operator = "LessThanOrEqualToThreshold"
#   alarm_description   = "Triggers if no data is ingested into Firehose in 24 hours"
#   alarm_actions       = [aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_ap.arn]
# }

# # CloudWatch alarm for Firehose failure delivery
# resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_firehose_failure_alarm_ap" {
#   provider            = aws.ap
#   alarm_name          = "Userplatform-CPP-FirehoseDeliveryFailures-AP"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 1
#   metric_name         = "DeliveryToS3.DataDeliveryFailed"
#   namespace           = "AWS/Firehose"
#   period              = 300
#   statistic           = "Sum"
#   threshold           = 0
#   alarm_description   = "Alert when Firehose fails to deliver data to S3"
#   dimensions = {
#     DeliveryStreamName = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_ap.name
#   }
#   alarm_actions = [aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_ap.arn]
# }

# resource "aws_cloudwatch_event_target" "userplatform_cpp_cloudwatch_event_target_ap" {
#   provider       = aws.ap
#   rule           = aws_cloudwatch_event_rule.userplatform_cpp_eventbridge_to_firehose_rule_ap.name
#   arn            = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_ap.arn
#   role_arn       = aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.arn
#   event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_ap.name
# }

# resource "aws_cloudwatch_event_target" "userplatform_cpp_eventbridge_to_log_target_ap" {
#   provider       = aws.ap
#   rule           = aws_cloudwatch_event_rule.userplatform_cpp_eventbridge_to_firehose_rule_ap.name
#   arn            = aws_cloudwatch_log_group.userplatform_cpp_event_bus_logs_ap.arn
#   event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_ap.name
#   depends_on     = [aws_cloudwatch_log_group.userplatform_cpp_event_bus_logs_ap]
# }


# # SNS Topic for alerts
# resource "aws_sns_topic" "userplatform_cpp_firehose_failure_alert_topic_ap" {
#   provider = aws.ap
#   name     = "userplatform_cpp_firehose_failure_alert_topic_ap"
# }

