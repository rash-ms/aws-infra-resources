locals {
  route_configs = {
    us = {
      region     = "us-east-1",
      route_path = var.route_path["us"],
      bucket     = var.userplatform_s3_bucket["us"],
      # event_bus  = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_us.arn

    },
    eu = {
      region     = "eu-central-1",
      route_path = var.route_path["eu"],
      bucket     = var.userplatform_s3_bucket["eu"],
      # event_bus  = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_eu.arn
    },
    ap = {
      region     = "ap-northeast-1",
      route_path = var.route_path["ap"],
      bucket     = var.userplatform_s3_bucket["ap"],
      # event_bus  = aws_cloudwatch_event_bus.userplatform_cpp_event_bus_ap.arn
    }
  }
}



locals {
  sqs_integration_responses = {
    "200" = {
      selection_pattern = null # "2\\d{2}"
      # success → no selection_pattern
      template = <<EOF
#set($r = $util.parseJson($input.body))
{
  "status": "success",
  "integration_type": "SQS",
  "messageId": "$util.escapeJavaScript($r.SendMessageResponse.SendMessageResult.MessageId)",
  "RequestId": "$util.escapeJavaScript($r.SendMessageResponse.ResponseMetadata.RequestId)",

}
EOF
    }
    "400" = {
      selection_pattern = "4\\d{2}"
      template          = <<EOF
{
  "status": "error",
  "error_type": "bad_request",
  "integration_type": "SQS",
  "details":"$util.escapeJavaScript($r.Error.Message)",
  "RequestId": "$util.escapeJavaScript($r.RequestId)"
}
EOF
    }
    "500" = {
      selection_pattern = "5\\d{2}"
      template          = <<EOF
{
  "status": "error",
  "error_type": "internal_failure",
  "integration_type": "SQS",
  "details":"$util.escapeJavaScript($r.Error.Message)",
  "RequestId": "$util.escapeJavaScript($r.RequestId)"
}
EOF
    }
  }
}

# "$util.escapeJavaScript($input.body)"

# locals {
#   # Shared Velocity macro
#   vtl_macros = <<VTL
# ## --- Macros ---
# #macro(setIds $r $mode)
#   #set($apiReqId = $context.requestId)
#   #if($mode == "success")
#     #set($sqsReqId = $r.SendMessageResponse.ResponseMetadata.RequestId)
#   #else
#     #set($sqsReqId = $r.RequestId)
#   #end
#   #if($util.isBlank($sqsReqId))
#     #set($sqsReqId = "N/A")
#     #set($reqId = $apiReqId)
#   #else
#     #set($reqId = $sqsReqId)
#   #end
# #end
# ## --- End Macros ---
# VTL
#
#   sqs_integration_responses = {
#     "200" = {
#       selection_pattern = null
#       template          = <<EOF
# ${local.vtl_macros}
# #set($r = $util.parseJson($input.body))
# #setIds($r "success")
#
# set($msgId = $r.SendMessageResponse.SendMessageResult.MessageId)
# if(!$msgId) #set($msgId = "Unknown messageId") #end

# {
#   "status": "success",
#   "integration_type": "SQS",
#   "messageId": "$util.escapeJavaScript($msgId)",
#   "requestId": "$util.escapeJavaScript($reqId)",
#   "sqsRequestId": "$util.escapeJavaScript($sqsReqId)"
# }
# EOF
#     }
#
#     "400" = {
#       selection_pattern = "4\\d{2}"
#       template          = <<EOF
# ${local.vtl_macros}
# #set($r = $util.parseJson($input.body))
# #setIds($r "error")
#
# #set($errMsg = $r.Error.Message)
# #if(!$errMsg) #set($errMsg = "Unknown error") #end
#
# {
#   "status": "error",
#   "error_type": "bad_request",
#   "integration_type": "SQS",
#   "requestId": "$util.escapeJavaScript($reqId)",
#   "sqsRequestId": "$util.escapeJavaScript($sqsReqId)",
#   "message": "$util.escapeJavaScript($errMsg)"
# }
# EOF
#     }
#
#     "500" = {
#       selection_pattern = "5\\d{2}"
#       template          = <<EOF
# ${local.vtl_macros}
# #set($r = $util.parseJson($input.body))
# #setIds($r "error")
#
# #set($errMsg = $r.Error.Message)
# #if(!$errMsg) #set($errMsg = "Internal service error") #end
#
# {
#   "status": "error",
#   "error_type": "internal_failure",
#   "integration_type": "SQS",
#   "requestId": "$util.escapeJavaScript($reqId)",
#   "sqsRequestId": "$util.escapeJavaScript($sqsReqId)",
#   "message": "$util.escapeJavaScript($errMsg)"
# }
# EOF
#     }
#   }
# }
#
