provider "aws" {
  alias  = "dev"
  region = "us-east-1"
  assume_role {
    # role_arn = "arn:aws:iam::022499035350:role/byt-internal-workspace-dev-role"
    role_arn = "arn:aws:iam::022499035568:role/byt-internal-workspace-dev-role"
  }
}

provider "aws" {
  alias  = "prod"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::022499035568:role/byt-internal-workspace-prod-role"
  }
}

locals {
  bucket_config = yamldecode(file("${path.module}/aws-s3-bucket-yaml/us/us-workspace-s3-buckets.yaml"))
}

locals {
  bucket_environment_pairs = flatten([
    for bucket_name, bucket_data in local.bucket_config : [
      for env in bucket_data.project-environment : {
        bucket_name    = bucket_name
        environment    = env
        region         = bucket_data.region
        team_names     = bucket_data["project-team-names"]
      }
    ]
  ])
}

# # S3 Buckets for dev environment
# resource "aws_s3_bucket" "s3_buckets_dev" {
#   for_each = { for pair in local.bucket_environment_pairs : "${pair.bucket_name}-${pair.environment}" => pair if pair.environment == "dev" }

#   provider = aws.dev

#   bucket = "byt-${each.value.bucket_name}-${each.value.environment}"
#   acl    = "private"

#   tags = {
#     Name        = "byt-${each.value.bucket_name}-${each.value.environment}"
#     Environment = each.value.environment
#     Team        = join(", ", each.value.team_names)
#   }
# }

# # S3 Buckets for prod environment
# resource "aws_s3_bucket" "s3_buckets_prod" {
#   for_each = { for pair in local.bucket_environment_pairs : "${pair.bucket_name}-${pair.environment}" => pair if pair.environment == "prod" }

#   provider = aws.prod

#   bucket = "byt-${each.value.bucket_name}-${each.value.environment}"
#   acl    = "private"

#   tags = {
#     Name        = "byt-${each.value.bucket_name}-${each.value.environment}"
#     Environment = each.value.environment
#     Team        = join(", ", each.value.team_names)
#   }
# }
