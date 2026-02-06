# S3 bucket for app data
resource "aws_s3_bucket" "app_data" {
  bucket = "rupaya-sandbox-app-data"
  force_destroy = true
  tags = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

output "s3_app_data_bucket" {
  value = aws_s3_bucket.app_data.bucket
}
