variable "location" { type = string, default = "eastus" }
variable "project_name" { type = string, default = "rupaya" }
variable "db_admin_username" { type = string, default = "rupaya" }
variable "db_version" { type = string, default = "15" }
variable "container_port" { type = number, default = 3000 }
variable "image_tag" { type = string, default = "latest" }
variable "frontend_url" { type = string, default = "*" }
