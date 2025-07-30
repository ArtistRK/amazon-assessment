resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.public.json
}

data "aws_iam_policy_document" "public" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.bucket_name}-logs"
  acl    = "log-delivery-write"
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.site.website_endpoint
    origin_id   = "s3-site-origin"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "s3-site-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  logging_config {
    bucket = aws_s3_bucket.logs.bucket_domain_name
    prefix = "cloudfront-logs/"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = var.tags
}

resource "aws_s3_object" "site_files" {
  for_each = fileset("${var.build_dir}", "**")

  bucket = aws_s3_bucket.site.id
  key    = each.value
  source = "${var.build_dir}/${each.value}"
  etag   = filemd5("${var.build_dir}/${each.value}")
  content_type = lookup(var.mime_types, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

variable "mime_types" {
  default = {
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    json = "application/json"
    png  = "image/png"
    jpg  = "image/jpeg"
    svg  = "image/svg+xml"
  }
}
