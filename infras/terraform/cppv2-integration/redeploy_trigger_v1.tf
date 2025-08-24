################################################################  US  ################################################################
################################################################      ################################################################

resource "null_resource" "force_put_sqs_integration_us" {
  depends_on = [
    aws_api_gateway_stage.userplatform_cpp_api_stage_us,
    aws_api_gateway_integration.userplatform_cpp_api_integration_us,
    aws_api_gateway_deployment.userplatform_cpp_api_deployment_us
  ]

  triggers = {
    redeploy = local.force_redeploy_us
  }

  provisioner "local-exec" {
    command     = <<-EOT
      sleep 10

      # Force new deployment to stage
      aws apigateway create-deployment \
        --region ${local.route_configs["us"].region} \
        --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id} \
        --stage-name ${aws_api_gateway_stage.userplatform_cpp_api_stage_us.stage_name} \
        --description "Auto-redeploy after updating integration to SQS"
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

################################################################  EMEA  ################################################################
################################################################      ################################################################


resource "null_resource" "force_put_sqs_integration_eu" {
  depends_on = [
    aws_api_gateway_stage.userplatform_cpp_api_stage_eu,
    aws_api_gateway_integration.userplatform_cpp_api_integration_eu,
    aws_api_gateway_deployment.userplatform_cpp_api_deployment_eu
  ]

  triggers = {
    redeploy = local.force_redeploy_eu
  }

  provisioner "local-exec" {
    command     = <<-EOT
      sleep 10

      # Force new deployment to stage
      aws apigateway create-deployment \
        --region ${local.route_configs["eu"].region} \
        --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id} \
        --stage-name ${aws_api_gateway_stage.userplatform_cpp_api_stage_eu.stage_name} \
        --description "Auto-redeploy after updating integration to SQS"
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}


################################################################  APAC  ################################################################
################################################################      ################################################################

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
#       sleep 10
#
#       # Force new deployment to stage
#       aws apigateway create-deployment \
#         --region ${local.route_configs["ap"].region} \
#         --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id} \
#         --stage-name ${aws_api_gateway_stage.userplatform_cpp_api_stage_ap.stage_name} \
#         --description "Auto-redeploy after updating integration to SQS"
#
#     EOT
#     interpreter = ["/bin/bash", "-c"]
#   }
# }
