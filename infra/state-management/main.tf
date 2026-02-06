# ============================================================================
# Terraform State Management Infrastructure (Enterprise Pattern)
# 
# This creates the S3 bucket and DynamoDB table for managing Terraform state
# across dev, staging, and production environments.
#
# Usage: Deploy this FIRST in a separate AWS account or root account
# Then configure backends to point to these resources.
# ============================================================================

terraform {
  required_version = ">= 1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ============================================================================
# S3 Bucket for Terraform State
# ============================================================================

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}-terraform-state"
    Environment = "shared"
    Purpose     = "Terraform State Backend"
  }
}

# Enable versioning (disaster recovery)
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled" # Set to "Enabled" + require MFA for production
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
    bucket_key_enabled = true
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable access logging
resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.terraform_state_logs.id
  target_prefix = "access-logs/"
}

# Logging bucket
resource "aws_s3_bucket" "terraform_state_logs" {
  bucket = "${var.project_name}-terraform-state-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "${var.project_name}-terraform-state-logs"
    Purpose = "Access logs for terraform state bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable lifecycle rules (cleanup old versions after 90 days)
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }
  }

  rule {
    id     = "cleanup-logs"
    status = "Enabled"

    filter {
      prefix = "access-logs/"
    }

    expiration {
      days = 180
    }
  }
}

# ============================================================================
# KMS Key for Encryption
# ============================================================================

resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-terraform-state-key"
  }
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/${var.project_name}-terraform-state"
  target_key_id = aws_kms_key.terraform_state.key_id
}

# ============================================================================
# DynamoDB Table for State Locking
# ============================================================================

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "${var.project_name}-terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-terraform-state-lock"
    Environment = "shared"
    Purpose     = "Terraform State Locking"
  }
}

# ============================================================================
# IAM Policy for Terraform Backend Access
# ============================================================================

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "terraform_backend" {
  name        = "${var.project_name}-terraform-backend-access"
  description = "Policy for accessing Terraform state S3 and DynamoDB lock"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3StateAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetBucketVersioningConfiguration"
        ]
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Sid    = "S3StateObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      },
      {
        Sid    = "DynamoDBLocking"
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.terraform_state_lock.arn
      },
      {
        Sid    = "KMSEncryption"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.terraform_state.arn
      }
    ]
  })
}

# ============================================================================
# IAM Role for CI/CD (GitHub Actions, GitLab CI, etc.)
# ============================================================================

resource "aws_iam_role" "terraform_cicd" {
  name               = "${var.project_name}-terraform-cicd"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.cicd_external_id
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-terraform-cicd"
  }
}

resource "aws_iam_role_policy_attachment" "terraform_cicd_backend" {
  role       = aws_iam_role.terraform_cicd.name
  policy_arn = aws_iam_policy.terraform_backend.arn
}

# ============================================================================
# CloudWatch Monitoring
# ============================================================================

resource "aws_cloudwatch_log_group" "terraform_state" {
  name              = "/aws/terraform/${var.project_name}/state"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-terraform-logs"
  }
}

# Alert if state file is accessed from unexpected IP
resource "aws_cloudtrail" "terraform_state" {
  name                          = "${var.project_name}-terraform-state-trail"
  s3_bucket_name                = aws_s3_bucket.terraform_state.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.terraform_state_cloudtrail]

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.terraform_state.arn}/*"]
    }
  }
}

resource "aws_s3_bucket_policy" "terraform_state_cloudtrail" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
