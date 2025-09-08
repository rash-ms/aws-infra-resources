moved {
  from = aws_s3_bucket.lambda_bucket
  to   = aws_s3_bucket.lambda_bucket_us
}


resource "aws_s3_bucket" "lambda_bucket_us" {
  provider = aws.us
  bucket   = local.bkt_configs["us"].bucket
}

resource "aws_s3_bucket" "lambda_bucket_eu" {
  provider = aws.eu
  bucket   = local.bkt_configs["eu"].bucket
}

resource "aws_s3_bucket" "lambda_bucket_ap" {
  provider = aws.ap
  bucket   = local.bkt_configs["ap"].bucket
}