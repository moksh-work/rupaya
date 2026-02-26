# Variables for Production Environment

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cost_center" {
  description = "Cost center for billing/allocation"
  type        = string
  default     = "engineering"
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15.4"
}

variable "rds_instance_class" {
  description = "RDS instance class for Aurora (larger than staging)"
  type        = string
  default     = "db.r6g.large"  # 2 vCPU, 16GB RAM
}

variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "7.0"
}

variable "redis_node_type" {
  description = "Redis node type for cluster mode"
  type        = string
  default     = "cache.r6g.xlarge"  # 13GB memory
}

variable "ecs_task_cpu" {
  description = "ECS task CPU (256-4096)"
  type        = number
  default     = 1024  # Higher for production
}

variable "ecs_task_memory" {
  description = "ECS task memory in MB"
  type        = number
  default     = 2048  # Higher for production
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 3  # Higher for HA
}

variable "ecs_min_count" {
  description = "Minimum number of ECS tasks for auto-scaling"
  type        = number
  default     = 3
}

variable "ecs_max_count" {
  description = "Maximum number of ECS tasks for auto-scaling"
  type        = number
  default     = 10  # Higher ceiling for spike handling
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
  default     = "rupaya_prod"
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

# Certificate (for HTTPS)
variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Production domain name"
  type        = string
  default     = "api.rupaya.com"
}

variable "environment_variables" {
  description = "Additional environment variables for application"
  type        = map(string)
  default = {
    NODE_ENV = "production"
    LOG_LEVEL = "warn"
  }
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Database backup retention period"
  type        = number
  default     = 30
}
