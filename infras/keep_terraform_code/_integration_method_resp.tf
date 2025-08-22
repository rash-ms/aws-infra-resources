## **************************  US  **************************
## Method responses: declare allowed status codes
resource "aws_api_gateway_method_response" "userplatform_cpp_api_sqs_mthd_resp_us" {
  provider = aws.us

  for_each    = local.responses
  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
  resource_id = aws_api_gateway_resource.userplatform_cpp_api_resource_us.id
  http_method = aws_api_gateway_method.userplatform_cpp_api_method_us.http_method
  status_code = each.key

  response_parameters = {
    "method.response.header.x-amz-request-id" = true,
    "method.response.header.etag"             = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

## Integration responses: map SQS → client
resource "aws_api_gateway_integration_response" "userplatform_cpp_api_sqs_integration_resp_us" {
  provider = aws.us

  for_each          = local.responses
  rest_api_id       = aws_api_gateway_rest_api.userplatform_cpp_rest_api_us.id
  resource_id       = aws_api_gateway_resource.userplatform_cpp_api_resource_us.id
  http_method       = aws_api_gateway_method.userplatform_cpp_api_method_us.http_method
  status_code       = aws_api_gateway_method_response.userplatform_cpp_api_sqs_mthd_resp_us[each.key].status_code
  selection_pattern = try(each.value.selection_pattern, null)

  depends_on = [
    aws_api_gateway_integration.userplatform_cpp_api_integration_us,
    aws_api_gateway_method_response.userplatform_cpp_api_sqs_mthd_resp_us
  ]

  response_parameters = {
    "method.response.header.x-amz-request-id" = "integration.response.header.x-amz-request-id",
    "method.response.header.etag"             = "integration.response.header.ETag"
  }

  response_templates = {
    "application/json" = each.value.template
  }
}


## **************************  EU  **************************
## Method responses: declare allowed status codes
resource "aws_api_gateway_method_response" "userplatform_cpp_api_sqs_mthd_resp_eu" {
  provider = aws.eu

  for_each    = local.responses
  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id
  resource_id = aws_api_gateway_resource.userplatform_cpp_api_resource_eu.id
  http_method = aws_api_gateway_method.userplatform_cpp_api_method_eu.http_method
  status_code = each.key

  response_parameters = {
    "method.response.header.x-amz-request-id" = true,
    "method.response.header.etag"             = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

## Integration responses: map SQS → client
resource "aws_api_gateway_integration_response" "userplatform_cpp_api_sqs_integration_resp_eu" {
  provider = aws.eu

  for_each          = local.responses
  rest_api_id       = aws_api_gateway_rest_api.userplatform_cpp_rest_api_eu.id
  resource_id       = aws_api_gateway_resource.userplatform_cpp_api_resource_eu.id
  http_method       = aws_api_gateway_method.userplatform_cpp_api_method_eu.http_method
  status_code       = aws_api_gateway_method_response.userplatform_cpp_api_sqs_mthd_resp_eu[each.key].status_code
  selection_pattern = try(each.value.selection_pattern, null)

  depends_on = [
    aws_api_gateway_integration.userplatform_cpp_api_integration_eu,
    aws_api_gateway_method_response.userplatform_cpp_api_sqs_mthd_resp_eu
  ]

  response_parameters = {
    "method.response.header.x-amz-request-id" = "integration.response.header.x-amz-request-id",
    "method.response.header.etag"             = "integration.response.header.ETag"
  }

  response_templates = {
    "application/json" = each.value.template
  }
}

## **************************  AP  **************************
## Method responses: declare allowed status codes
resource "aws_api_gateway_method_response" "userplatform_cpp_api_sqs_mthd_resp_ap" {
  provider = aws.ap

  for_each    = local.responses
  rest_api_id = aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id
  resource_id = aws_api_gateway_resource.userplatform_cpp_api_resource_ap.id
  http_method = aws_api_gateway_method.userplatform_cpp_api_method_ap.http_method
  status_code = each.key

  response_parameters = {
    "method.response.header.x-amz-request-id" = true,
    "method.response.header.etag"             = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

## Integration responses: map SQS → client
resource "aws_api_gateway_integration_response" "userplatform_cpp_api_sqs_integration_resp_ap" {
  provider = aws.ap

  for_each          = local.responses
  rest_api_id       = aws_api_gateway_rest_api.userplatform_cpp_rest_api_ap.id
  resource_id       = aws_api_gateway_resource.userplatform_cpp_api_resource_ap.id
  http_method       = aws_api_gateway_method.userplatform_cpp_api_method_ap.http_method
  status_code       = aws_api_gateway_method_response.userplatform_cpp_api_sqs_mthd_resp_ap[each.key].status_code
  selection_pattern = try(each.value.selection_pattern, null)

  depends_on = [
    aws_api_gateway_integration.userplatform_cpp_api_integration_ap,
    aws_api_gateway_method_response.userplatform_cpp_api_sqs_mthd_resp_ap
  ]

  response_parameters = {
    "method.response.header.x-amz-request-id" = "integration.response.header.x-amz-request-id",
    "method.response.header.etag"             = "integration.response.header.ETag"
  }

  response_templates = {
    "application/json" = each.value.template
  }
}