locals {
  route_configs = {
    us = {
      region     = "us-east-1",
      route_path = var.route_path["us"],
      bucket     = var.userplatform_s3_bucket["us"],
      # event_bus  = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_us.arn

    },
    eu = {
      region     = "eu-central-1",
      route_path = var.route_path["eu"],
      bucket     = var.userplatform_s3_bucket["eu"],
      # event_bus  = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.arn,
    },
    ap = {
      region     = "ap-northeast-1",
      route_path = var.route_path["ap"],
      bucket     = var.userplatform_s3_bucket["ap"],
      # event_bus  = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_ap.arn,
    }
  }
}
