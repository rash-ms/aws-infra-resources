locals {
  route_configs = {
    us = {
      region      = "us-east-1",
      event_bus   = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_us.arn,
      detail_type = "US",
      bucket      = var.userplatform_s3_bucket["us"]
    },
    eu = {
      region      = "eu-west-1",
      event_bus   = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.arn,
      detail_type = "EU",
      bucket      = var.userplatform_s3_bucket["eu"]
    },
    ap = {
      region      = "ap-southeast-1",
      event_bus   = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_ap.arn,
      detail_type = "AP",
      bucket      = var.userplatform_s3_bucket["ap"]
    }
  }
}