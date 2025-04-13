variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

# variable "userplatform_s3_bucket" {
#   type        = list(string)
#   description = "List of S3 bucket names for each route (order must match route_path)"
# }

variable "userplatform_s3_bucket" {
  type = map(string)
}


variable "route_path" {
  type = list(string)
}

variable "deployer_region" {
  type = list(string)
}

variable "tenant_name" {
  type    = string
  default = "data-platform"
}

variable "notification_emails" {
  description = "List of email addresses to receive alerts"
  type        = list(string)
}

# tags to be applied to resource
variable "tags" {
  type = map(any)

  default = {
    "created_by"  = "terraform"
    "application" = "aws-infra-resources"
    "owner"       = "data-platform"
  }
}
