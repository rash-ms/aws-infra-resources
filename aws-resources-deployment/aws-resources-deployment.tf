module "iam_deployment" {
  source = "../aws-resources-infra/aws-s3-bucket"
}

# module "aws-apigateway-s3" {
#   source = "/aws-resources-deployment/aws-apigateway-s3/"
# }

# module "aws-lambda-function" {
#   source = "/aws-resources-deployment/aws-lambda-function/"
# }

# module "aws-apigateway-eventbridge-firehose-s3" {
#   source = "/aws-resources-deployment/aws-apigateway-eventbridge-firehose-s3/"
# }