# S3 Bucket (Logging Account) - stored AWS Config aggregated files
resource "aws_s3_bucket" "aws_config_aggregation" {
  count  = var.is_logging_account ? 1 : 0
  bucket = var.aws_config_central_bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "aws_config_aggregation" {
  count = var.is_logging_account ? 1 : 0

  bucket = aws_s3_bucket.aws_config_aggregation[count.index].id

  rule {
    id     = "config-lifecycle"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_policy" "aws_config_aggregation" {
  count  = var.is_logging_account ? 1 : 0
  bucket = aws_s3_bucket.aws_config_aggregation[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = ["s3:PutObject", "s3:GetBucketAcl", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.aws_config_aggregation[0].arn,
          "${aws_s3_bucket.aws_config_aggregation[0].arn}/*"
        ]
      }
    ]
  })
}
