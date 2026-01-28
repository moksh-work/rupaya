variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "rupaya-project"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "rupaya"
}

variable "container_port" {
  description = "Container port for backend"
  type        = number
  default     = 3000
}

variable "db_tier" {
  description = "Cloud SQL machine tier"
  type        = string
  default     = "db-f1-micro"
}

variable "db_version" {
  description = "Postgres version"
  type        = string
  default     = "POSTGRES_15"
}

variable "redis_size_gb" {
  description = "Redis size"
  type        = number
  default     = 1
}

variable "image_tag" {
  description = "Container image tag to deploy"
  type        = string
  default     = "latest"
}

variable "frontend_url" {
  description = "Allowed CORS origin"
  type        = string
  default     = "*"
}
