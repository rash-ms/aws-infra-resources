locals {
  force_redeploy = "cppv2-release-v0.4"
}

################################################################  US  ################################################################
################################################################      ################################################################

data "aws_api_gateway_rest_api" "userplatform_cpp_rest_api_us" {
  provider = aws.us
  name     = "userplatform_cpp_rest_api_us"
}

resource "null_resource" "force_put_sqs_integration_us" {

  triggers = {
    redeploy = local.force_redeploy
  }

  provisioner "local-exec" {
    command     = <<-EOT
      echo "Retrying deployment until integration is ready (max 3 minutes)..."

      for i in {1..18}; do   # 18 retries × 10s = 180s (3 minutes)
        if aws apigateway create-deployment \
          --region ${local.route_configs["us"].region} \
          --rest-api-id ${data.aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id} \
          --stage-name ${var.stage_name} \
          --description "Auto-redeploy after updating integration to SQS"; then
          echo "Deployment succeeded"
          exit 0
        else
          echo "Deployment attempt $i failed (integration not ready yet). Retrying in 10s..."
          sleep 10
        fi
      done

      echo "Deployment failed after 2 minutes: integration was never ready."
      exit 1
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

}

################################################################  EMEA  ################################################################
################################################################      ################################################################

data "aws_api_gateway_rest_api" "userplatform_cpp_rest_api_eu" {
  provider = aws.eu
  name     = "userplatform_cpp_rest_api_eu"
}

resource "null_resource" "force_put_sqs_integration_eu" {

  triggers = {
    redeploy = local.force_redeploy
  }

  provisioner "local-exec" {
    command     = <<-EOT
      echo "Retrying deployment until integration is ready (max 3 minutes)..."

      for i in {1..18}; do   # 18 retries × 10s = 180s (3 minutes)
        if aws apigateway create-deployment \
          --region ${local.route_configs["eu"].region} \
          --rest-api-id ${data.aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id} \
          --stage-name ${var.stage_name} \
          --description "Auto-redeploy after updating integration to SQS"; then
          echo "Deployment succeeded"
          exit 0
        else
          echo "Deployment attempt $i failed (integration not ready yet). Retrying in 10s..."
          sleep 10
        fi
      done

      echo "Deployment failed after 2 minutes: integration was never ready."
      exit 1
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}


################################################################  APAC  ################################################################
################################################################      ################################################################

data "aws_api_gateway_rest_api" "userplatform_cpp_rest_api_ap" {
  provider = aws.ap
  name     = "userplatform_cpp_rest_api_ap"
}

resource "null_resource" "force_put_sqs_integration_ap" {

  triggers = {
    redeploy = local.force_redeploy
  }

  provisioner "local-exec" {
    command     = <<-EOT
      echo "Retrying deployment until integration is ready (max 3 minutes)..."

      for i in {1..18}; do   # 18 retries × 10s = 180s (3 minutes)
        if aws apigateway create-deployment \
          --region ${local.route_configs["ap"].region} \
          --rest-api-id ${data.aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id} \
          --stage-name ${var.stage_name} \
          --description "Auto-redeploy after updating integration to SQS"; then
          echo "Deployment succeeded"
          exit 0
        else
          echo "Deployment attempt $i failed (integration not ready yet). Retrying in 10s..."
          sleep 10
        fi
      done

      echo "Deployment failed after 2 minutes: integration was never ready."
      exit 1
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}
