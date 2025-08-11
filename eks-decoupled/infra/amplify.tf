# S3 bucket for static assets (images, etc.)
resource "aws_s3_bucket" "static_assets" {
  bucket = "${var.project_name}-static-assets-${random_id.bucket_suffix.hex}"
  tags   = var.tags
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_assets.arn}/*"
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.static_assets]
}

# CloudFront distribution for static assets
resource "aws_cloudfront_distribution" "static_assets" {
  origin {
    domain_name = aws_s3_bucket.static_assets.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.static_assets.bucket}"
  }

  enabled = true

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.static_assets.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

# Amplify App for Frontend
resource "aws_amplify_app" "retail_frontend" {
  name       = "${var.project_name}-retail-frontend"
  repository = "https://github.com/shyamkulkarni/aws-eks-infra"

  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - cd eks-decoupled/frontend
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: eks-decoupled/frontend/build
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  environment_variables = {
    REACT_APP_API_URL    = "https://${aws_lb.retail_api.dns_name}"
    REACT_APP_ASSETS_URL = "https://${aws_cloudfront_distribution.static_assets.domain_name}"
  }

  tags = var.tags
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.retail_frontend.id
  branch_name = "main"

  framework = "React"
  stage     = "PRODUCTION"

  environment_variables = {
    REACT_APP_API_URL    = "https://${aws_lb.retail_api.dns_name}"
    REACT_APP_ASSETS_URL = "https://${aws_cloudfront_distribution.static_assets.domain_name}"
  }
}

resource "aws_amplify_domain_association" "retail_frontend" {
  count       = var.domain_name != "example.com" ? 1 : 0
  app_id      = aws_amplify_app.retail_frontend.id
  domain_name = var.domain_name

  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = "retail"
  }
}