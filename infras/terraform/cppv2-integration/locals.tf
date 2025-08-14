locals {
  route_configs = {
    us = {
      region     = "us-east-1",
      route_path = var.route_path["us"],
      bucket     = var.userplatform_s3_bucket["us"]

    },
    eu = {
      region     = "eu-central-1",
      route_path = var.route_path["eu"],
      bucket     = var.userplatform_s3_bucket["eu"]
    },
    ap = {
      region     = "ap-northeast-1",
      route_path = var.route_path["ap"],
      bucket     = var.userplatform_s3_bucket["ap"]
    }
  }
}
