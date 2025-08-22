# Gather all IDs into lists (empty-safe with try())
locals {
  resource_ids    = try(sort([for r in aws_api_gateway_resource.this    : r.id]), [])
  method_ids      = try(sort([for m in aws_api_gateway_method.this      : m.id]), [])
  integration_ids = try(sort([for i in aws_api_gateway_integration.this : i.id]), [])

  # Fingerprint changes whenever any resource/method/integration changes
  deployment_fingerprint = sha1(jsonencode({
    resources    = local.resource_ids
    methods      = local.method_ids
    integrations = local.integration_ids
  }))
}

# Single deployment resource, replaced whenever fingerprint changes
resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeploy = local.deployment_fingerprint
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_resource.this,
    aws_api_gateway_method.this,
    aws_api_gateway_integration.this,
  ]
}

# Stage always points to this deployment
resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deploy.id
}
