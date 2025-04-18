variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "stage_name" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "userplatform_s3_bucket" {
  type = map(string)
}

variable "route_path" {
  type = map(string)
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

variable "slack_channel_id" {
  type = string
}

variable "slack_workspace_id" {
  type = string
}
