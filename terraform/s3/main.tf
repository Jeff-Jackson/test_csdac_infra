provider "aws" {
  region  = var.region
}

variable "region" {
  type = string
  default = "us-west-1"
}

data "aws_canonical_user_id" "current" {}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.charts-storage.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.s3chartstorageCOA.iam_arn]
    }
  }
}

locals {
  s3_origin_id = "s3ChartStorage"
}

resource "aws_s3_bucket" "charts-storage" {
  bucket = "csdac-helm-chart"

  tags = {
    Name        = "CSDAC Charts"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "charts-storage-acl" {
  bucket = aws_s3_bucket.charts-storage.id
  acl    = "private"
}

  resource "aws_s3_bucket_versioning" "versioning-charts-storage" {
    bucket = aws_s3_bucket.charts-storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_cloudfront_origin_access_identity" "s3chartstorageCOA" {
  comment = "COA for s3 helm storage bucket"
}

resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.charts-storage.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_cloudfront_distribution" "s3_chart_distribution" {
  origin {
    domain_name = aws_s3_bucket.charts-storage.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3chartstorageCOA.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CF for s3 helm storage"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 600
    max_ttl                = 600
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

output "bucket_arn" {
  value = aws_s3_bucket.charts-storage.arn
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_chart_distribution.domain_name
}
