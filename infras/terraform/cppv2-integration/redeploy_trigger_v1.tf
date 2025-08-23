# ################################################################  US  ################################################################
# ################################################################      ################################################################
#
# resource "null_resource" "force_put_sqs_integration_us" {
#   depends_on = [
#     aws_api_gateway_stage.userplatform_cpp_api_stage_us,
#     aws_api_gateway_deployment.userplatform_cpp_api_deployment_us
#   ]
#   # depends_on = [
#   #   aws_api_gateway_stage.userplatform_cpp_api_stage_us
#   # ]
#   triggers = {
#     redeploy = local.force_redeploy_us
#   }
#
#   provisioner "local-exec" {
#     command     = <<-EOT
#       aws apigateway put-integration \
#         --region ${local.route_configs["us"].region} \
#         --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id} \
#         --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_us.id} \
#         --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_us.http_method} \
#         --type ${aws_api_gateway_integration.userplatform_cpp_api_integration_us.type} \
#         --integration-http-method ${aws_api_gateway_integration.userplatform_cpp_api_integration_us.integration_http_method} \
#         --uri arn:aws:apigateway:${local.route_configs["us"].region}:sqs:path/${var.account_id}/${data.aws_sqs_queue.userplatform_cppv2_sqs_us.name} \
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
#         --response-parameters '{"method.response.header.x-amz-request-id":"integration.response.header.x-amz-request-id","method.response.header.etag":"integration.response.header.ETag"}' \
#         --response-templates '{"application/json":""}' \
#         %{if try(cfg.selection_pattern, null) != null}--selection-pattern "${cfg.selection_pattern}" %{endif} \
#         --response-templates '${jsonencode({ "application/json" = cfg.template })}'
#
#       # Upsert Method Responses
#       echo "Ensuring MethodResponse for status ${code}..."
#       if aws apigateway get-method-response \
#         --region ${local.route_configs["us"].region} \
#         --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id} \
#         --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_us.id} \
#         --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_us.http_method} \
#         --status-code ${code} >/dev/null 2>&1; then
#
#         echo "Updating MethodResponse ${code}"
#         aws apigateway update-method-response \
#           --region ${local.route_configs["us"].region} \
#           --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id} \
#           --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_us.id} \
#           --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_us.http_method} \
#           --status-code ${code} \
#           --patch-operations op=replace,path=/responseModels/application~1json,value=Empty
#       else
#         echo "Creating MethodResponse ${code}"
#         aws apigateway put-method-response \
#           --region ${local.route_configs["us"].region} \
#           --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id} \
#           --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_us.id} \
#           --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_us.http_method} \
#           --status-code ${code} \
#           --response-models '{"application/json":"Empty"}'
#       fi
#
#       # Force new deployment to stage
#       aws apigateway create-deployment \
#         --region ${local.route_configs["us"].region} \
#         --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id} \
#         --stage-name ${aws_api_gateway_stage.userplatform_cpp_api_stage_us.stage_name} \
#         --description "Auto-redeploy after updating integration to SQS"
#
#
#       %{endfor~}
#     EOT
#     interpreter = ["/bin/bash", "-c"]
#   }
# }
#
# ################################################################  EMEA  ################################################################
# ################################################################      ################################################################
#
#
# resource "null_resource" "force_put_sqs_integration_eu" {
#   depends_on = [
#     aws_api_gateway_stage.userplatform_cpp_api_stage_eu,
#     aws_api_gateway_deployment.userplatform_cpp_api_deployment_eu
#   ]
#
#   # depends_on = [
#   #   aws_api_gateway_stage.userplatform_cpp_api_stage_eu
#   # ]
#
#   triggers = {
#     redeploy = local.force_redeploy_eu
#   }
#
#   provisioner "local-exec" {
#     command     = <<-EOT
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
#         --response-parameters '{"method.response.header.x-amz-request-id":"integration.response.header.x-amz-request-id","method.response.header.etag":"integration.response.header.ETag"}' \
#         --response-templates '{"application/json":""}' \
#         %{if try(cfg.selection_pattern, null) != null}--selection-pattern "${cfg.selection_pattern}" %{endif} \
#         --response-templates '${jsonencode({ "application/json" = cfg.template })}'
#
#       # Upsert Method Responses
#       echo "Ensuring MethodResponse for status ${code}..."
#       if aws apigateway get-method-response \
#         --region ${local.route_configs["eu"].region} \
#         --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id} \
#         --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_eu.id} \
#         --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_eu.http_method} \
#         --status-code ${code} >/dev/null 2>&1; then
#
#         echo "Updating MethodResponse ${code}"
#         aws apigateway update-method-response \
#           --region ${local.route_configs["eu"].region} \
#           --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id} \
#           --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_eu.id} \
#           --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_eu.http_method} \
#           --status-code ${code} \
#           --patch-operations op=replace,path=/responseModels/application~1json,value=Empty
#       else
#         echo "Creating MethodResponse ${code}"
#         aws apigateway put-method-response \
#           --region ${local.route_configs["eu"].region} \
#           --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id} \
#           --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_eu.id} \
#           --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_eu.http_method} \
#           --status-code ${code} \
#           --response-models '{"application/json":"Empty"}'
#       fi
#
#       # Force new deployment to stage
#       aws apigateway create-deployment \
#         --region ${local.route_configs["eu"].region} \
#         --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id} \
#         --stage-name ${aws_api_gateway_stage.userplatform_cpp_api_stage_eu.stage_name} \
#         --description "Auto-redeploy after updating integration to SQS"
#
#       %{endfor~}
#     EOT
#     interpreter = ["/bin/bash", "-c"]
#   }
# }
#
#
# ################################################################  APAC  ################################################################
# ################################################################      ################################################################
#
# resource "null_resource" "force_put_sqs_integration_ap" {
#   depends_on = [
#     aws_api_gateway_stage.userplatform_cpp_api_stage_ap,
#     aws_api_gateway_deployment.userplatform_cpp_api_deployment_ap
#   ]
#
#   # depends_on = [
#   #   aws_api_gateway_stage.userplatform_cpp_api_stage_ap
#   # ]
#
#   triggers = {
#     redeploy = local.force_redeploy_ap
#   }
#
#   provisioner "local-exec" {
#     command     = <<-EOT
#       aws apigateway put-integration \
#         --region ${local.route_configs["ap"].region} \
#         --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id} \
#         --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_ap.id} \
#         --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_ap.http_method} \
#         --type ${aws_api_gateway_integration.userplatform_cpp_api_integration_ap.type} \
#         --integration-http-method ${aws_api_gateway_integration.userplatform_cpp_api_integration_ap.integration_http_method} \
#         --uri arn:aws:apigateway:${local.route_configs["ap"].region}:sqs:path/${var.account_id}/${data.aws_sqs_queue.userplatform_cppv2_sqs_ap.name} \
#         --credentials ${aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.arn} \
#         --passthrough-behavior ${aws_api_gateway_integration.userplatform_cpp_api_integration_ap.passthrough_behavior} \
#         --request-parameters '{"integration.request.header.Content-Type":"'\''application/x-www-form-urlencoded'\''"}' \
#         --request-templates '{"application/json":"Action=SendMessage&MessageBody=$input.body"}'
#
#       # Loop through response configs
#       %{for code, cfg in local.sqs_integration_responses~}
#       aws apigateway put-integration-response \
#         --region ${local.route_configs["ap"].region} \
#         --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id} \
#         --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_ap.id} \
#         --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_ap.http_method} \
#         --status-code ${code} \
#         --response-parameters '{"method.response.header.x-amz-request-id":"integration.response.header.x-amz-request-id","method.response.header.etag":"integration.response.header.ETag"}' \
#         --response-templates '{"application/json":""}' \
#         %{if try(cfg.selection_pattern, null) != null}--selection-pattern "${cfg.selection_pattern}" %{endif} \
#         --response-templates '${jsonencode({ "application/json" = cfg.template })}'
#
#       # Upsert Method Responses
#       echo "Ensuring MethodResponse for status ${code}..."
#       if aws apigateway get-method-response \
#         --region ${local.route_configs["ap"].region} \
#         --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id} \
#         --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_ap.id} \
#         --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_ap.http_method} \
#         --status-code ${code} >/dev/null 2>&1; then
#
#         echo "Updating MethodResponse ${code}"
#         aws apigateway update-method-response \
#           --region ${local.route_configs["ap"].region} \
#           --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id} \
#           --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_ap.id} \
#           --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_ap.http_method} \
#           --status-code ${code} \
#           --patch-operations op=replace,path=/responseModels/application~1json,value=Empty
#       else
#         echo "Creating MethodResponse ${code}"
#         aws apigateway put-method-response \
#           --region ${local.route_configs["ap"].region} \
#           --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id} \
#           --resource-id ${aws_api_gateway_resource.userplatform_cpp_api_resource_ap.id} \
#           --http-method ${aws_api_gateway_method.userplatform_cpp_api_method_ap.http_method} \
#           --status-code ${code} \
#           --response-models '{"application/json":"Empty"}'
#       fi
#
#       # Force new deployment to stage
#       aws apigateway create-deployment \
#         --region ${local.route_configs["ap"].region} \
#         --rest-api-id ${aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id} \
#         --stage-name ${aws_api_gateway_stage.userplatform_cpp_api_stage_ap.stage_name} \
#         --description "Auto-redeploy after updating integration to SQS"
#
#       %{endfor~}
#     EOT
#     interpreter = ["/bin/bash", "-c"]
#   }
# }
