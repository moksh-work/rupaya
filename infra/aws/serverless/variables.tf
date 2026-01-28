variable "region" { type = string, default = "us-east-1" }
variable "project_name" { type = string, default = "rupaya" }
variable "vpc_cidr" { type = string, default = "10.30.0.0/16" }
variable "az_count" { type = number, default = 2 }
variable "image_tag" { type = string, default = "latest" }
variable "container_port" { type = number, default = 3000 }
variable "frontend_url" { type = string, default = "*" }
