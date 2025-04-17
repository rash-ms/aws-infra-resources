locals {
  route_configs = {
    us = {
      detail_type = "US",
      region      = "us-east-1",
      route_path  = var.route_path["us"],
      bucket      = var.userplatform_s3_bucket["us"],
      event_bus   = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_us.arn
    },
    eu = {
      detail_type = "EU",
      region      = "eu-central-1",
      route_path  = var.route_path["eu"]
      bucket      = var.userplatform_s3_bucket["eu"],
      event_bus   = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.arn,
    },
    ap = {
      detail_type = "AP",
      region      = "ap-southeast-1",
      route_path  = var.route_path["ap"]
      bucket      = var.userplatform_s3_bucket["ap"],
      event_bus   = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_ap.arn,
    }
  }
}
