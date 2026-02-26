# Variables for Staging Environment

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15.4"
}

variable "rds_instance_class" {
  description = "RDS instance class for Aurora"
  type        = string
  default     = "db.t3.small"
}

variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "7.0"
}

variable "redis_node_type" {
  description = "Redis node type"
  type        = string
  default     = "cache.t3.small"
}

variable "ecs_task_cpu" {
  description = "ECS task CPU (256-4096)"
  type        = number
  default     = 512
}

variable "ecs_task_memory" {
  description = "ECS task memory in MB"
  type        = number
  default     = 1024
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "ecs_min_count" {
  description = "Minimum number of ECS tasks for auto-scaling"
  type        = number
  default     = 2
}

variable "ecs_max_count" {
  description = "Maximum number of ECS tasks for auto-scaling"
  type        = number
  default     = 4
}

# Database variables
variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "rupaya_admin"
  sensitive   = true
}

variable "db_master_password" {
  description = "RDS master password (min 8 chars, must contain uppercase, lowercase, number, special char)"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "RDS database name"
  type        = string
  default     = "rupaya_staging"
}

# Redis variables
variable "redis_auth_token" {
  description = "Redis AUTH token for cluster mode (min 16 chars)"
  type        = string
  sensitive   = true
}

# Application secrets
variable "jwt_secret" {
  description = "JWT secret for token signing (min 32 chars)"
  type        = string
  sensitive   = true
}

variable "jwt_refresh_secret" {
  description = "JWT refresh secret (min 32 chars)"
  type        = string
  sensitive   = true
}

variable "environment_variables" {
  description = "Additional environment variables for application"
  type        = map(string)
  default = {
    NODE_ENV = "staging"
    LOG_LEVEL = "info"
  }
}
