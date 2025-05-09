locals {
  route_configs = {
    us = {
      region                = "us-east-1",
      route_path            = var.route_path["us"],
      bucket                = var.userplatform_s3_bucket["us"],
      event_bus             = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_us.arn,
      apigw_backend_logs_us = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id}/${aws_api_gateway_stage.userplatform_cpp_api_stage_us.stage_name}"

    },
    eu = {
      region                = "eu-central-1",
      route_path            = var.route_path["eu"],
      bucket                = var.userplatform_s3_bucket["eu"],
      event_bus             = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.arn,
      apigw_backend_logs_eu = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id}/${aws_api_gateway_stage.userplatform_cpp_api_stage_eu.stage_name}"
    },
    ap = {
      region                = "ap-northeast-1",
      route_path            = var.route_path["ap"],
      bucket                = var.userplatform_s3_bucket["ap"],
      event_bus             = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_ap.arn,
      apigw_backend_logs_ap = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id}/${aws_api_gateway_stage.userplatform_cpp_api_stage_ap.stage_name}"
    }
  }
}
