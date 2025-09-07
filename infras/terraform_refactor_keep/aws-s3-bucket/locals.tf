locals {
  bkt_configs = {
    us = {
      region = "us-east-1",
      bucket = var.lambda_artefact_buckets["us"],

    },
    eu = {
      region = "eu-central-1",
      bucket = var.lambda_artefact_buckets["eu"],
    },
    ap = {
      region = "ap-northeast-1",
      bucket = var.lambda_artefact_buckets["ap"],
    }
  }
}
