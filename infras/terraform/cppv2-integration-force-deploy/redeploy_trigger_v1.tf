locals {
  force_redeploy = "cppv2-release-v0.2"
}

data "aws_api_gateway_rest_api" "userplatform_cpp_rest_api_us" {
  provider = aws.us
  name     = "userplatform_cpp_rest_api_us"
}


data "aws_api_gateway_rest_api" "userplatform_cpp_rest_api_eu" {
  provider = aws.eu
  name     = "userplatform_cpp_rest_api_eu"
}


data "aws_api_gateway_rest_api" "userplatform_cpp_rest_api_ap" {
  provider = aws.ap
  name     = "userplatform_cpp_rest_api_ap"
}

################################################################  US  ################################################################
################################################################      ################################################################

resource "null_resource" "force_put_sqs_integration_us" {

  triggers = {
    redeploy = local.force_redeploy
  }

  provisioner "local-exec" {
    command     = <<-EOT
      sleep 10

      # Force new deployment to stage
      aws apigateway create-deployment \
        --region ${local.route_configs["us"].region} \
        --rest-api-id ${data.aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id} \
        --stage-name ${var.stage_name} \
        --description "Auto-redeploy after updating integration to SQS"
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

################################################################  EMEA  ################################################################
################################################################      ################################################################


resource "null_resource" "force_put_sqs_integration_eu" {

  triggers = {
    redeploy = local.force_redeploy
  }

  provisioner "local-exec" {
    command     = <<-EOT
      sleep 10

      # Force new deployment to stage
      aws apigateway create-deployment \
        --region ${local.route_configs["eu"].region} \
        --rest-api-id ${data.aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id} \
        --stage-name ${var.stage_name} \
        --description "Auto-redeploy after updating integration to SQS"
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}


################################################################  APAC  ################################################################
################################################################      ################################################################

resource "null_resource" "force_put_sqs_integration_ap" {

  triggers = {
    redeploy = local.force_redeploy
  }

  provisioner "local-exec" {
    command     = <<-EOT

      sleep 10

      # Force new deployment to stage
      aws apigateway create-deployment \
        --region ${local.route_configs["ap"].region} \
        --rest-api-id ${data.aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id} \
        --stage-name ${var.stage_name} \
        --description "Auto-redeploy after updating integration to SQS"

    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

# resource "null_resource" "force_put_sqs_integration_ap" {
#   depends_on = [
#     aws_api_gateway_stage.userplatform_cpp_api_stage_ap,
#     aws_api_gateway_integration.userplatform_cpp_api_integration_ap,
#     aws_api_gateway_deployment.userplatform_cpp_api_deployment_ap
#   ]
#
#   triggers = {
#     redeploy = local.force_redeploy_ap
#   }
#
#   provisioner "local-exec" {
#     command     = <<-EOT
#       set -euo pipefail
#
#       REGION="${local.route_configs["ap"].region}"
#       API_ID="${aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id}"
#       RES_ID="${aws_api_gateway_resource.userplatform_cpp_api_resource_ap.id}"
#       METHOD="${aws_api_gateway_method.userplatform_cpp_api_method_ap.http_method}"
#       STAGE="${aws_api_gateway_stage.userplatform_cpp_api_stage_ap.stage_name}"
#
#       echo "Waiting for integration to be ready (max 2 min)..."
#
#       for i in $(seq 1 24); do   # 24 * 5s = 120s
#         OUT=$(aws apigateway get-integration \
#           --region "$REGION" \
#           --rest-api-id "$API_ID" \
#           --resource-id "$RES_ID" \
#           --http-method "$METHOD" 2>/dev/null || true)
#
#         if echo "$OUT" | grep -q '"type": "AWS"' && echo "$OUT" | grep -q ':sqs:path/'; then
#           echo "Integration is ready with SQS URI"
#           break
#         fi
#
#         echo "Integration not ready yet... retrying in 5s"
#         sleep 5
#       done
#
#       echo "Creating deployment to force stage update..."
#       aws apigateway create-deployment \
#         --region "$REGION" \
#         --rest-api-id "$API_ID" \
#         --stage-name "$STAGE" \
#         --description "Auto-redeploy after updating integration to SQS"
#     EOT
#     interpreter = ["/bin/bash", "-c"]
#   }
# }
