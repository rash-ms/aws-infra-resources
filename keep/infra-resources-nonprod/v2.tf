# resource "aws_kinesis_firehose_delivery_stream" "cpp" {
#   for_each   = toset(var.regions)
#   name       = "${each.key}-delivery-stream"
#   destination = "s3"

#   s3_configuration {
#     role_arn           = aws_iam_role.eventbridge_to_firehose.arn
#     bucket_arn         = "arn:aws:s3:::${var.bucket_names[each.key]}"
#     prefix             = "${each.key}/"
#     buffer_size        = 5
#     buffer_interval    = 300
#     compression_format = "UNCOMPRESSED"

#     cloudwatch_logging_options {
#       enabled         = true
#       log_group_name  = "/aws/kinesisfirehose/${each.key}-delivery-stream"
#       log_stream_name = "S3Delivery"
#     }

#     data_format_conversion_configuration {
#       enabled = true

#       input_format_configuration {
#         deserializer {
#           json_ser_de {}
#         }
#       }

#       output_format_configuration {
#         serializer {
#           json_ser_de {
#             record_delimiter = "\n"
#           }
#         }
#       }

#       schema_configuration {
#         role_arn = aws_iam_role.eventbridge_to_firehose.arn
#         # If not using AWS Glue schema registry, omit or leave empty
#         database_name = ""
#         table_name    = ""
#         region        = var.region
#       }
#     }
#   }

#   failure_s3_configuration {
#     role_arn   = aws_iam_role.eventbridge_to_firehose.arn
#     bucket_arn = "arn:aws:s3:::${var.bucket_names[each.key]}"
#     prefix     = "failures/"
#   }

#   tags = {
#     Environment = "production"
#   }
# }