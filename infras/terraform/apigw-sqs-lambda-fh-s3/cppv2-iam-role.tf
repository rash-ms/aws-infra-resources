## --------------------------------------------------
## IAM ROLES & POLICIES
## --------------------------------------------------
## This section provisions IAM components such as:
## - Execution roles for API Gateway, EventBridge, and Firehose
## - Policies granting PutEvents, PutRecord, and other actions
## - Cross-region access roles
## - Trust relationships for service integrations
## --------------------------------------------------

resource "aws_iam_role" "cpp_integration_apigw_evtbridge_firehose_logs_role" {
  name = "cpp_integration_apigw_evtbridge_firehose_logs_role"
  # permissions_boundary = "arn:aws:iam::${var.account_id}:policy/tenant-${var.tenant_name}-boundary"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "apigateway.amazonaws.com",
            "events.amazonaws.com",
            "firehose.amazonaws.com",
            "chatbot.amazonaws.com",
            "lambda.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cpp_integration_apigw_evtbridge_firehose_logs_policy" {
  name = "cpp_integration_apigw_evtbridge_firehose_logs_policy"
  role = aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # EventBridge PutEvents (for API Gateway)
      {
        Effect = "Allow",
        Action = [
          "events:PutEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage"
        ],
        Resource = "*"
      },
      {
        Effect : "Allow",
        Action : [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ],
        Resource = "*"
      },
      # Firehose PutRecord from EventBridge
      {
        Effect = "Allow",
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ],
        # Resource = "*"
        Resource = [
          aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_us.arn,
          # aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_eu.arn,
          # aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_ap.arn
        ]
      },

      # Firehose Access to S3
      {
        Effect = "Allow",
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = [
          "arn:aws:s3:::${local.route_configs["us"].bucket}",
          "arn:aws:s3:::${local.route_configs["us"].bucket}/*",
          "arn:aws:s3:::${local.route_configs["eu"].bucket}",
          "arn:aws:s3:::${local.route_configs["eu"].bucket}/*",
          "arn:aws:s3:::${local.route_configs["ap"].bucket}",
          "arn:aws:s3:::${local.route_configs["ap"].bucket}/*"

        ]
      },

      # CloudWatch Logs from API-Gateway, EventBridge Rule, Firehose
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
        # Resource = [
        #   "${aws_cloudwatch_log_group.userplatform_cpp_api_gateway_logs_us.arn}:*",
        #   "${aws_cloudwatch_log_group.userplatform_cpp_api_gateway_logs_eu.arn}:*",
        #   "${aws_cloudwatch_log_group.userplatform_cpp_api_gateway_logs_ap.arn}:*",
        #   "${aws_cloudwatch_log_group.userplatform_cpp_event_bus_logs_us.arn}:*",
        #   "${aws_cloudwatch_log_group.userplatform_cpp_event_bus_logs_eu.arn}:*",
        #   "${aws_cloudwatch_log_group.userplatform_cpp_event_bus_logs_ap.arn}:*",
        #   "${aws_cloudwatch_log_group.userplatform_cpp_firehose_to_s3_us.arn}:*",
        #   "${aws_cloudwatch_log_group.userplatform_cpp_firehose_to_s3_eu.arn}:*",
        #   "${aws_cloudwatch_log_group.userplatform_cpp_firehose_to_s3_ap.arn}:*"
        # ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "userplatform_cpp_chatbot_attach" {
  role       = aws_iam_role.cpp_integration_apigw_evtbridge_firehose_logs_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role" "userplatform_cpp_api_gateway_cloudwatch_logging_role" {
  name = "userplatform_cpp_api_gateway_cloudwatch_logging_role"
  # permissions_boundary = "arn:aws:iam::${var.account_id}:policy/tenant-${var.tenant_name}-boundary"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy" "userplatform_cpp_api_gateway_cloudwatch_logging_policy" {
  name = "userplatform_cpp_api_gateway_cloudwatch_logging_policy"
  role = aws_iam_role.userplatform_cpp_api_gateway_cloudwatch_logging_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:GetLogEvents",
        "logs:FilterLogEvents"
      ],
      Resource = "*"
    }]
  })
}




resource "aws_iam_role" "cppv2_integration_sqs_lambda_firehose_role" {
  name = "cppv2_integration_sqs_lambda_firehose_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# CloudWatch Logs
resource "aws_iam_role_policy_attachment" "cppv2_lambda_basic_logging" {
  role       = aws_iam_role.cppv2_integration_sqs_lambda_firehose_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# SQS permissions
resource "aws_iam_role_policy" "cppv2_lambda_sqs_permissions" {
  name = "cppv2_lambda_sqs_permissions"
  role = aws_iam_role.cppv2_integration_sqs_lambda_firehose_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility",
          "sqs:GetQueueUrl",
          "sqs:ListDeadLetterSourceQueues",
          "sqs:SendMessageBatch",
          "sqs:PurgeQueue",
          "sqs:SendMessage",
          "sqs:CreateQueue",
          "sqs:ListQueueTags",
          "sqs:ChangeMessageVisibilityBatch",
          "sqs:SetQueueAttributes"
        ],
        Resource = [
          aws_sqs_queue.userplatform_cppv2_sqs_us.arn,
          # aws_sqs_queue.userplatform_cppv2_sqs_eu.arn,
          # aws_sqs_queue.userplatform_cppv2_sqs_ap.arn,
          aws_sqs_queue.userplatform_cppv2_sqs_dlq_us.arn,
          # aws_sqs_queue.userplatform_cppv2_sqs_dlq_eu.arn,
          # aws_sqs_queue.userplatform_cppv2_sqs_dlq_ap.arn
        ]
      },

      # Firehose permissions (Lambda code pushes to Firehose)
      {
        Effect = "Allow",
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ],
        Resource = [
          aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_us.arn,
          # data.aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_eu.arn,
          # data.aws_kinesis_firehose_delivery_stream.userplatform_cpp_firehose_delivery_stream_ap.arn
        ]
      },

      # KMS permissions
      {
        "Effect" : "Allow",
        Action : [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = "*"
      },
    ]
  })
}
