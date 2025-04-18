# resource "aws_iam_role" "userplatform_cpp_api_gateway_eventbridge_role" {
#   name = "userplatform_cpp_api_gateway_eventbridge_role"
#   # permissions_boundary = "arn:aws:iam::${var.account_id}:policy/tenant-${var.tenant_name}-boundary"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "apigateway.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy" "userplatform_cpp_api_gateway_eventbridge_policy" {
#   name = "userplatform_cpp_api_gateway_eventbridge_policy"
#   role = aws_iam_role.userplatform_cpp_api_gateway_eventbridge_role.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Action = [
#         "events:PutEvents"
#       ],
#       Effect = "Allow",
#       Resource = [
#         "${aws_cloudwatch_event_bus.userplatform_cpp_event_bus_us.arn}",
#         "${aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.arn}",
#         "${aws_cloudwatch_event_bus.userplatform_cpp_event_bus_ap.arn}"
#       ]
#     }]
#   })
# }

# resource "aws_iam_role" "userplatform_cpp_api_gateway_cloudwatch_logging_role" {
#   name = "userplatform_cpp_api_gateway_cloudwatch_logging_role"
#   # permissions_boundary = "arn:aws:iam::${var.account_id}:policy/tenant-${var.tenant_name}-boundary"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Principal = {
#           Service = "apigateway.amazonaws.com"
#         },
#         Effect = "Allow"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy" "userplatform_cpp_api_gateway_cloudwatch_logging_policy" {
#   name = "userplatform_cpp_api_gateway_cloudwatch_logging_policy"
#   role = aws_iam_role.userplatform_cpp_api_gateway_cloudwatch_logging_role.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Action = [
#         "logs:CreateLogGroup",
#         "logs:CreateLogStream",
#         "logs:PutLogEvents",
#         "logs:DescribeLogGroups",
#         "logs:DescribeLogStreams",
#         "logs:GetLogEvents",
#         "logs:FilterLogEvents"
#       ],
#       Resource = "*"
#     }]
#   })
# }

# # REST API Gateway
# resource "aws_api_gateway_rest_api" "userplatform_cpp_rest_api_us" {
#   provider    = aws.us
#   name        = "userplatform_cpp_rest_api_us"
#   description = "REST API for Userplatform CPP US Integration"
#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }
# }

# # Create resources and methods for each route_path
# resource "aws_api_gateway_resource" "userplatform_cpp_api_resource_us" {
#   provider    = aws.us
#   rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
#   parent_id   = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.root_resource_id
#   path_part   = local.route_configs["us"].route_path
# }


# resource "aws_api_gateway_method" "userplatform_cpp_api_method_us" {
#   provider         = aws.us
#   rest_api_id      = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
#   resource_id      = aws_api_gateway_resource.userplatform_cpp_api_resource_us.id
#   http_method      = "POST"
#   authorization    = "NONE"
#   api_key_required = true
# }

# resource "aws_api_gateway_integration" "userplatform_cpp_api_integration_us" {
#   provider                = aws.us
#   rest_api_id             = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
#   resource_id             = aws_api_gateway_resource.userplatform_cpp_api_resource_us.id
#   http_method             = aws_api_gateway_method.userplatform_cpp_api_method_us.http_method
#   integration_http_method = "POST"
#   type                    = "AWS"
#   # uri                     = "arn:aws:apigateway:us-east-1:events:path//"
#   uri                  = "arn:aws:apigateway:${local.route_configs["us"].region}:events:path//"
#   credentials          = aws_iam_role.userplatform_cpp_api_gateway_eventbridge_role.arn
#   passthrough_behavior = "WHEN_NO_TEMPLATES"

#   request_templates = {
#     "application/json" = templatefile("${path.module}/templates/eventbridge.tftpl", {
#       event_bus_arn = local.route_configs["us"].event_bus
#     })
#   }
# }

# resource "aws_api_gateway_integration_response" "userplatform_cpp_apigateway_s3_integration_response_us" {
#   provider    = aws.us
#   rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
#   resource_id = aws_api_gateway_resource.userplatform_cpp_api_resource_us.id
#   http_method = aws_api_gateway_method.userplatform_cpp_api_method_us.http_method
#   status_code = "200"

#   depends_on = [
#     aws_api_gateway_integration.userplatform_cpp_api_integration_us,
#     aws_api_gateway_method_response.userplatform_cpp_apigateway_s3_method_response_us
#   ]

#   response_parameters = {
#     "method.response.header.x-amz-request-id" = "integration.response.header.x-amz-request-id",
#     "method.response.header.etag"             = "integration.response.header.ETag"
#   }

#   response_templates = {
#     "application/json" = ""
#   }
# }


# resource "aws_api_gateway_method_response" "userplatform_cpp_apigateway_s3_method_response_us" {
#   provider    = aws.us
#   rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
#   resource_id = aws_api_gateway_resource.userplatform_cpp_api_resource_us.id
#   http_method = aws_api_gateway_method.userplatform_cpp_api_method_us.http_method
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
# resource "aws_api_gateway_api_key" "userplatform_cpp_api_key_us" {
#   provider = aws.us
#   name     = "us_cpp_api_key"
#   enabled  = true
# }

# # Usage Plans with high rate/burst
# resource "aws_api_gateway_usage_plan" "userplatform_cpp_api_usage_plan_us" {
#   provider = aws.us
#   name     = "us_cpp_api_usage_plan"

#   api_stages {
#     api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
#     stage  = aws_api_gateway_stage.userplatform_cpp_api_stage_us.stage_name
#   }

#   throttle_settings {
#     rate_limit  = 1000
#     burst_limit = 200
#   }
# }

# resource "aws_api_gateway_usage_plan_key" "userplatform_cpp_api_usage_plan_key_us" {
#   provider      = aws.us
#   key_id        = aws_api_gateway_api_key.userplatform_cpp_api_key_us.id
#   key_type      = "API_KEY"
#   usage_plan_id = aws_api_gateway_usage_plan.userplatform_cpp_api_usage_plan_us.id
# }

# resource "aws_cloudwatch_log_group" "userplatform_cpp_api_gateway_logs_us" {
#   provider          = aws.us
#   name              = "/aws/apigateway/userplatform_cpp_api_gateway_logs_us"
#   retention_in_days = 14
# }

# resource "aws_cloudwatch_log_group" "userplatform_cpp_event_bus_logs_us" {
#   provider          = aws.us
#   name              = "/aws/events/userplatform_cpp_event_bus_logs_us"
#   retention_in_days = 14
# }

# resource "aws_api_gateway_deployment" "userplatform_cpp_api_deployment_us" {
#   provider    = aws.us
#   rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id

#   depends_on = [
#     aws_api_gateway_integration.userplatform_cpp_api_integration_us,
#     aws_api_gateway_method_response.userplatform_cpp_apigateway_s3_method_response_us,
#     aws_api_gateway_integration_response.userplatform_cpp_apigateway_s3_integration_response_us
#   ]
# }

# resource "aws_api_gateway_stage" "userplatform_cpp_api_stage_us" {
#   provider      = aws.us
#   stage_name    = "cpp-v02"
#   rest_api_id   = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
#   deployment_id = aws_api_gateway_deployment.userplatform_cpp_api_deployment_us.id

#   cache_cluster_enabled = true
#   cache_cluster_size    = "0.5"

#   access_log_settings {
#     destination_arn = aws_cloudwatch_log_group.userplatform_cpp_api_gateway_logs_us.arn
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
#   depends_on           = [aws_api_gateway_account.userplatform_cpp_api_account_settings_us]
# }

# # Configure Method Settings for Detailed Logging and Caching
# resource "aws_api_gateway_method_settings" "userplatform_cpp_apigateway_method_settings_us" {
#   provider    = aws.us
#   rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
#   stage_name  = aws_api_gateway_stage.userplatform_cpp_api_stage_us.stage_name
#   method_path = "*/*" # Apply to all methods and resources

#   settings {
#     metrics_enabled      = true    # Enable CloudWatch metrics
#     logging_level        = "ERROR" # Set logging level to INFO
#     data_trace_enabled   = true    # Enable data trace logging
#     caching_enabled      = true    # Enable caching
#     cache_ttl_in_seconds = 300     # Set TTL for cache (5 minutes)
#   }
# }

# resource "aws_api_gateway_account" "userplatform_cpp_api_account_settings_us" {
#   provider            = aws.us
#   cloudwatch_role_arn = aws_iam_role.userplatform_cpp_api_gateway_cloudwatch_logging_role.arn
# }

# resource "aws_cloudwatch_event_bus" "userplatform_cpp_event_bus_us" {
#   provider = aws.us
#   name     = "userplatform_cpp_event_bus_us"
# }

# resource "aws_iam_role" "userplatform_cpp_eventbridge_firehose_role_us" {
#   name = "userplatform_cpp_eventbridge_firehose_role_us"
#   # permissions_boundary = "arn:aws:iam::${var.account_id}:policy/tenant-${var.tenant_name}-boundary"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "events.amazonaws.com"
#         }
#       },
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "firehose.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy" "userplatform_cpp_eventbridge_firehose_policy_us" {
#   name = "userplatform_cpp_eventbridge_firehose_policy_us"
#   role = aws_iam_role.userplatform_cpp_eventbridge_firehose_role_us.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Action = [
#         "firehose:PutRecord",
#         "firehose:PutRecordBatch"
#       ],
#       Effect   = "Allow",
#       Resource = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_us.arn
#       },
#       {
#         Action = [
#           "s3:AbortMultipartUpload",
#           "s3:GetBucketLocation",
#           "s3:GetObject",
#           "s3:ListBucket",
#           "s3:ListBucketMultipartUploads",
#           "s3:PutObject",
#           "s3:PutObjectAcl"
#         ],
#         Effect = "Allow",
#         Resource = [
#           "arn:aws:s3:::${local.route_configs["us"].bucket}",
#           "arn:aws:s3:::${local.route_configs["us"].bucket}/*"
#         ]
#       },
#       {
#         Action = [
#           "logs:PutLogEvents",
#           "logs:CreateLogStream",
#           "logs:CreateLogGroup",
#           "logs:DescribeLogStreams"
#         ],
#         Effect   = "Allow",
#         Resource = "*"
#     }]
#   })
# }

# # Firehose delivery streams + SNS for failure
# resource "aws_kinesis_firehose_delivery_stream" "userplatform_cpp_firehose_delivery_stream_us" {
#   provider    = aws.us
#   name        = "userplatform_cpp_firehose_delivery_stream_us"
#   destination = "extended_s3"

#   extended_s3_configuration {
#     role_arn            = aws_iam_role.userplatform_cpp_eventbridge_firehose_role_us.arn
#     bucket_arn          = "arn:aws:s3:::${local.route_configs["us"].bucket}"
#     prefix              = "raw/cppv2-collector/"
#     error_output_prefix = "raw/cppv2-errors/"
#     compression_format  = "UNCOMPRESSED"

#     cloudwatch_logging_options {
#       enabled         = true
#       log_group_name  = aws_cloudwatch_log_group.userplatform_cpp_firehose_to_s3_us.name
#       log_stream_name = aws_cloudwatch_log_stream.userplatform_cpp_firehose_to_s3_log_stream_us.name
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

# resource "aws_cloudwatch_log_group" "userplatform_cpp_firehose_to_s3_us" {
#   provider          = aws.us
#   name              = "/aws/kinesisfirehose/userplatform_cpp_firehose_to_s3_us"
#   retention_in_days = 30
# }

# resource "aws_cloudwatch_log_stream" "userplatform_cpp_firehose_to_s3_log_stream_us" {
#   provider       = aws.us
#   name           = "userplatform_cpp_firehose_to_s3_log_stream_us"
#   log_group_name = aws_cloudwatch_log_group.userplatform_cpp_firehose_to_s3_us.name
# }

# # CloudWatch alarm for Firehose failure delivery
# resource "aws_cloudwatch_metric_alarm" "userplatform_cpp_firehose_failure_alarm_us" {
#   provider            = aws.us
#   alarm_name          = "Userplatform-CPP-FirehoseDeliveryFailures-US"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 1
#   metric_name         = "DeliveryToS3.DataDeliveryFailed"
#   namespace           = "AWS/Firehose"
#   period              = 300
#   statistic           = "Sum"
#   threshold           = 0
#   alarm_description   = "Alert when Firehose fails to deliver data to S3"
#   dimensions = {
#     DeliveryStreamName = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_us.name
#   }
#   alarm_actions = [aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_us.arn]
# }

# # EventBridge rules per route_path
# resource "aws_cloudwatch_event_rule" "userplatform_cpp_eventbridge_to_firehose_rule_us" {
#   provider       = aws.us
#   name           = "userplatform_cpp_eventbridge_to_firehose_rule_us"
#   event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_us.name

#   event_pattern = jsonencode({
#     "detail-type" : ["US"]
#   })

# }

# resource "aws_cloudwatch_event_target" "userplatform_cpp_cloudwatch_event_target_us" {
#   provider       = aws.us
#   rule           = aws_cloudwatch_event_rule.userplatform_cpp_eventbridge_to_firehose_rule_us.name
#   arn            = aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_us.arn
#   role_arn       = aws_iam_role.userplatform_cpp_eventbridge_firehose_role_us.arn
#   event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_us.name
# }

# resource "aws_cloudwatch_event_target" "userplatform_cpp_eventbridge_to_log_target_us" {
#   provider       = aws.us
#   rule           = aws_cloudwatch_event_rule.userplatform_cpp_eventbridge_to_firehose_rule_us.name
#   arn            = aws_cloudwatch_log_group.userplatform_cpp_event_bus_logs_us.arn
#   event_bus_name = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_us.name
#   depends_on     = [aws_cloudwatch_log_group.userplatform_cpp_event_bus_logs_us]
# }


# # 1. SNS Topic for alerts
# resource "aws_sns_topic" "userplatform_cpp_firehose_failure_alert_topic_us" {
#   provider = aws.us
#   name     = "userplatform_cpp_firehose_failure_alert_topic_us"
# }

# # 2. IAM Role for AWS Chatbot
# resource "aws_iam_role" "userplatform_cpp_chatbot_role" {
#   name = "userplatform_cpp_chatbot_role"
#   # permissions_boundary = "arn:aws:iam::${var.account_id}:policy/tenant-${var.tenant_name}-boundary"

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

# resource "aws_iam_role_policy_attachment" "userplatform_cpp_chatbot_attach" {
#   role       = aws_iam_role.userplatform_cpp_chatbot_role.name
#   policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
# }

# # 3. AWS Chatbot Slack Configuration
# resource "aws_chatbot_slack_channel_configuration" "userplatform_cpp_firehose_alerts_to_slack" {
#   configuration_name = "userplatform_cpp_firehose_alerts_to_slack"
#   slack_channel_id   = var.slack_channel_id
#   slack_team_id      = var.slack_workspace_id

#   sns_topic_arns = [
#     aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_us.arn,
#     aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_eu.arn,
#     aws_sns_topic.userplatform_cpp_firehose_failure_alert_topic_ap.arn
#   ]

#   iam_role_arn  = aws_iam_role.userplatform_cpp_chatbot_role.arn
#   logging_level = "ERROR"
# }
