variable "aws_region" {
  description = "AWS region for state management infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name (used in S3 bucket and DynamoDB table names)"
  type        = string
  default     = "rupaya"
}

variable "cicd_external_id" {
  description = "External ID for CI/CD role assumption (for security)"
  type        = string
  sensitive   = true
}
