# S3 Bucket (Logging Account)
resource "aws_s3_bucket" "central" {
  count  = var.is_logging_account ? 1 : 0
  bucket = local.central_bucket_name

  lifecycle_rule {
    id      = "config-lifecycle"
    enabled = true

    noncurrent_version_expiration {
      days = 30
    }
  }

  tags = var.tags
}

resource "aws_s3_bucket_policy" "central" {
  count  = var.is_logging_account ? 1 : 0
  bucket = aws_s3_bucket.central[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = ["s3:PutObject", "s3:GetBucketAcl", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.central[0].arn,
          "${aws_s3_bucket.central[0].arn}/*"
        ]
      }
    ]
  })
}
