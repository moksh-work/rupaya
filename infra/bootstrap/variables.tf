variable "aws_region" {
  description = "AWS region to deploy resources in."
  type        = string
}

variable "env_name" {
  description = "Environment name (e.g., sandbox, prod)."
  type        = string
}

variable "state_bucket_name" {
  description = "Name for the S3 bucket to store Terraform state."
  type        = string
}

variable "lock_table_name" {
  description = "Name for the DynamoDB table to use for state locking."
  type        = string
}
