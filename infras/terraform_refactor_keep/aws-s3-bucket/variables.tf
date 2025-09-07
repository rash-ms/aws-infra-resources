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

variable "lambda_artefact_buckets" {
  type = map(string)
}

variable "tenant_name" {
  type    = string
  default = "data-platform"
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