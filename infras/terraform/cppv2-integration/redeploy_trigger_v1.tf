################################################################  US  ################################################################
################################################################      ################################################################

# resource "null_resource" "force_put_sqs_integration_us" {
#   depends_on = [
#     aws_api_gateway_stage.userplatform_cpp_api_stage_us,
#     aws_api_gateway_deployment.userplatform_cpp_api_deployment_us
#   ]
#
#   triggers = {
#     redeploy = local.force_redeploy_us
#   }
#
#   provisioner "local-exec" {
#     command     = <<-EOT
#       # Base Integration
#       aws apigateway put-integration \
#         --region ${local.route_configs["us"].region} \
#         --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id} \
#         --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_us.id} \
#         --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_us.http_method} \
#         --type ${aws_api_gateway_integration.userplatform_cpp_api_integration_us.type} \
#         --integration-http-method ${aws_api_gateway_integration.userplatform_cpp_api_integration_us.integration_http_method} \
#         --uri arn:aws:apigateway:${local.route_configs["eu"].region}:sqs:path/${var.account_id}/${data.aws_sqs_queue.userplatform_cppv2_sqs_us.name} \
#         --credentials ${aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.arn} \
#         --passthrough-behavior ${aws_api_gateway_integration.userplatform_cpp_api_integration_us.passthrough_behavior} \
#         --request-parameters '{"integration.request.header.Content-Type":"'\''application/x-www-form-urlencoded'\''"}' \
#         --request-templates '{"application/json":"Action=SendMessage&MessageBody=$input.body"}'
#
#       # Loop through response configs
#       %{for code, cfg in local.sqs_integration_responses~}
#       aws apigateway put-integration-response \
#         --region ${local.route_configs["us"].region} \
#         --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id} \
#         --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_us.id} \
#         --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_us.http_method} \
#         --status-code ${code} \
#         %{if cfg.selection_pattern != null}--selection-pattern "${cfg.selection_pattern}" \ %{endif}
#         --response-templates '${cfg.template}'
#
#       aws apigateway put-method-response \
#         --region ${local.route_configs["us"].region} \
#         --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id} \
#         --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_us.id} \
#         --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_us.http_method} \
#         --status-code ${code} \
#         --response-models '{"application/json":"Empty"}'
#       %{endfor~}
#     EOT
#     interpreter = ["/bin/bash", "-c"]
#   }
# }

################################################################  EMEA  ################################################################
################################################################      ################################################################


# resource "null_resource" "force_put_sqs_integration_eu" {
#   depends_on = [
#     aws_api_gateway_stage.userplatform_cpp_api_stage_eu,
#     aws_api_gateway_deployment.userplatform_cpp_api_deployment_eu
#   ]
#
#   triggers = {
#     redeploy = local.force_redeploy_eu
#   }
#
#   provisioner "local-exec" {
#     command     = <<-EOT
#       # Base Integration
#       aws apigateway put-integration \
#         --region ${local.route_configs["eu"].region} \
#         --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id} \
#         --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_eu.id} \
#         --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_eu.http_method} \
#         --type ${aws_api_gateway_integration.userplatform_cpp_api_integration_eu.type} \
#         --integration-http-method ${aws_api_gateway_integration.userplatform_cpp_api_integration_eu.integration_http_method} \
#         --uri arn:aws:apigateway:${local.route_configs["eu"].region}:sqs:path/${var.account_id}/${data.aws_sqs_queue.userplatform_cppv2_sqs_eu.name} \
#         --credentials ${aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.arn} \
#         --passthrough-behavior ${aws_api_gateway_integration.userplatform_cpp_api_integration_eu.passthrough_behavior} \
#         --request-parameters '{"integration.request.header.Content-Type":"'\''application/x-www-form-urlencoded'\''"}' \
#         --request-templates '{"application/json":"Action=SendMessage&MessageBody=$input.body"}'
#
#       # Loop through response configs
#       %{for code, cfg in local.sqs_integration_responses~}
#       aws apigateway put-integration-response \
#         --region ${local.route_configs["eu"].region} \
#         --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id} \
#         --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_eu.id} \
#         --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_eu.http_method} \
#         --status-code ${code} \
#         %{if cfg.selection_pattern != null}--selection-pattern "${cfg.selection_pattern}" \ %{endif}
#         --response-templates '${cfg.template}'
#
#       aws apigateway put-method-response \
#         --region ${local.route_configs["eu"].region} \
#         --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id} \
#         --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_eu.id} \
#         --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_eu.http_method} \
#         --status-code ${code} \
#         --response-models '{"application/json":"Empty"}'
#       %{endfor~}
#     EOT
#     interpreter = ["/bin/bash", "-c"]
#   }
# }


################################################################  APAC  ################################################################
################################################################      ################################################################

resource "null_resource" "force_put_sqs_integration_ap" {
  depends_on = [
    aws_api_gateway_stage.userplatform_cpp_api_stage_ap,
    aws_api_gateway_deployment.userplatform_cpp_api_deployment_ap
  ]

  triggers = {
    redeploy = local.force_redeploy_ap
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Base Integration
      aws apigateway put-integration \
        --region ${local.route_configs["ap"].region} \
        --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id} \
        --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_ap.id} \
        --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_ap.http_method} \
        --type ${aws_api_gateway_integration.userplatform_cpp_api_integration_ap.type} \
        --integration-http-method ${aws_api_gateway_integration.userplatform_cpp_api_integration_ap.integration_http_method} \
        --uri arn:aws:apigateway:${local.route_configs["ap"].region}:sqs:path/${var.account_id}/${data.aws_sqs_queue.userplatform_cppv2_sqs_ap.name} \
        --credentials ${aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.arn} \
        --passthrough-behavior ${aws_api_gateway_integration.userplatform_cpp_api_integration_ap.passthrough_behavior} \
        --request-parameters '{"integration.request.header.Content-Type":"application/x-www-form-urlencoded"}' \
        --request-templates '{"application/json":"Action=SendMessage&MessageBody=$input.body"}'
    EOT
  }
}

# # Loop through response configs
#   %{for code, cfg in local.sqs_integration_responses~}
#   aws apigateway put-integration-response \
#     --region ${local.route_configs["ap"].region} \
#     --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id} \
#     --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_ap.id} \
#     --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_ap.http_method} \
#     --status-code ${code} \
#     %{if try(cfg.selection_pattern, null) != null}--selection-pattern "${cfg.selection_pattern}" %{endif} \
#     --response-templates '${jsonencode({ "application/json" = cfg.template })}'
#
#
#   aws apigateway put-method-response \
#     --region ${local.route_configs["ap"].region} \
#     --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id} \
#     --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_ap.id} \
#     --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_ap.http_method} \
#     --status-code ${code} \
#     --response-models '{"application/json":"Empty"}'
#   %{endfor~}