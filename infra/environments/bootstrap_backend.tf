# Bootstrap resources for Terraform backend (S3 + DynamoDB)
# Apply this file manually before using remote backend


resource "aws_s3_bucket" "tf_state" {
  bucket = "rupaya-terraform-state"
  force_destroy = true

}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

}

resource "aws_dynamodb_table" "tf_locks" {
  name         = "rupaya-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "rupaya-terraform-locks"
    Environment = "bootstrap"
  }
}
