variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "environment" {
  type    = string
  default = "stg"
}

variable "martech_s3_bucket" {
  type    = string
  default = "dev"
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
