terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # version = ">= 4.54.0"
      version = ">= 5.31.0"
    }
  }

  required_version = "~> 1.2.6"

  backend "s3" {}
}




# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 3.0"
#       version = ">= 4.54.0"
#     }
#   }
#
#   required_version = "~> 1.2.6"
#
#   backend "s3" {}
# }
