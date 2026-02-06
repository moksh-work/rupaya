# Database password for RDS instance
variable "db_password" {
  description = "Database password for RDS instance."
  type        = string
  sensitive   = true
}
# Shared variables for all environments

variable "aws_region" {
  description = "AWS region to deploy resources in."
  type        = string
}

variable "env_name" {
  description = "Environment name (development, sandbox, staging, production)."
  type        = string
}

variable "app_domain" {
  description = "Primary domain for the environment."
  type        = string
}
