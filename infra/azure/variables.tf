variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "rupaya"
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 3000
}

variable "db_admin_username" {
  description = "DB admin username"
  type        = string
  default     = "rupaya"
}

variable "db_version" {
  description = "Postgres version"
  type        = string
  default     = "15"
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

variable "frontend_url" {
  description = "Allowed CORS origin"
  type        = string
  default     = "*"
}
