# # Output API keys for reference
# output "userplatform_cpp_api_keys" {
#   value = {
#     for k, v in aws_api_gateway_api_key.userplatform_cpp_api_key :
#     k => v.value
#   }
#   sensitive = true
# }
