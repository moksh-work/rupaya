terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "tf_state" {
  bucket = var.state_bucket_name
  force_destroy = true
  tags = {
    Name        = var.state_bucket_name
    Environment = var.env_name
    Project     = "Rupaya"
  }
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name        = var.lock_table_name
    Environment = var.env_name
    Project     = "Rupaya"
  }
}
