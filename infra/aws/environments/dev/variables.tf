variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "rupaya"
}

# ========== RDS CONFIGURATION ==========
variable "postgres_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "rupaya_dev"
  sensitive   = true
}

variable "db_master_username" {
  description = "Master username for RDS"
  type        = string
  default     = "rupaya_admin"
  sensitive   = true
}

variable "db_master_password" {
  description = "Master password for RDS"
  type        = string
  default     = ""
  sensitive   = true
}

# ========== REDIS CONFIGURATION ==========
variable "redis_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_node_type" {
  description = "Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

# ========== ECS CONFIGURATION ==========
variable "ecs_task_cpu" {
  description = "CPU units for ECS task (256, 512, 1024, 2048)"
  type        = string
  default     = "512"
}

variable "ecs_task_memory" {
  description = "Memory in MB for ECS task (512, 1024, 2048, 3072, 4096)"
  type        = string
  default     = "1024"
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "ecs_max_count" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 2
}

variable "ecs_min_count" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 1
}

variable "container_image" {
  description = "Docker image URI for ECS"
  type        = string
  default     = ""
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 3000
}

# ========== ENVIRONMENT VARIABLES ==========
variable "environment_variables" {
  description = "Environment variables for ECS task"
  type        = map(string)
  default = {
    NODE_ENV = "development"
  }
}

variable "secrets" {
  description = "Secrets to be passed to ECS task (from Secrets Manager)"
  type        = map(string)
  default     = {}
  sensitive   = true
}
