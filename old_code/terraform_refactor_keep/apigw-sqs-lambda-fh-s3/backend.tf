terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31"
    }
  }

  required_version = "~> 1.2.6"

  backend "s3" {}
}


