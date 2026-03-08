# ========================================
# Frontend S3 Bucket (CloudFront OAC 経由のみ)
# ========================================

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend"

  tags = {
    Name = "${var.project_name}-frontend"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.project_name}-frontend-oac"
  description                       = "OAC for ${var.project_name} frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_cloudfront_distribution.frontend]
}

# ========================================
# CodeDeploy Artifacts S3 Bucket
# ========================================

resource "aws_s3_bucket" "codedeploy_artifacts" {
  bucket = "${var.project_name}-codedeploy-artifacts"

  tags = {
    Name = "${var.project_name}-codedeploy-artifacts"
  }
}

resource "aws_s3_bucket_public_access_block" "codedeploy_artifacts" {
  bucket = aws_s3_bucket.codedeploy_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "codedeploy_artifacts" {
  bucket = aws_s3_bucket.codedeploy_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "codedeploy_artifacts" {
  bucket = aws_s3_bucket.codedeploy_artifacts.id

  rule {
    id     = "expire-old-artifacts"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}
