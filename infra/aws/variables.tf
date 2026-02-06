variable "route53_domain" {
  description = "Root domain for Route53 zone (e.g. example.com)"
  type        = string
}

variable "route53_subdomain" {
  description = "Subdomain for ALB record (e.g. api.example.com)"
  type        = string
}
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "rupaya"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of AZs to use"
  type        = number
  default     = 2
}

variable "container_port" {
  description = "Container port for backend"
  type        = number
  default     = 3000
}

variable "desired_count" {
  description = "Desired task count for ECS service"
  type        = number
  default     = 1
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS storage (GB)"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "Postgres engine version"
  type        = string
  default     = "15.5"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "rupaya"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "rupaya"
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.micro"
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
# ========== SSL/TLS CERTIFICATE VARIABLES ==========

variable "certificate_alert_email" {
  description = "Email address for certificate expiration alerts"
  type        = string
  default     = "ops@example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.certificate_alert_email))
    error_message = "Must be a valid email address"
  }
}

variable "certificate_validation_timeout" {
  description = "Timeout for ACM certificate validation (allow DNS propagation)"
  type        = string
  default     = "15m"
}

variable "enable_staging_certificate" {
  description = "Create staging certificate (set to false if not needed)"
  type        = bool
  default     = true
}

variable "enable_staging_listener" {
  description = "Enable separate HTTPS listener for staging on port 8443"
  type        = bool
  default     = false

  # Set to true if you want staging on separate port, false if both on same ALB
  # Note: Production and staging both use port 443 with Host-based routing
}

variable "create_root_domain_record" {
  description = "Create Route53 record for root domain (example.com)"
  type        = bool
  default     = false

  # Set to true if you have a web application on root domain
}

variable "create_www_record" {
  description = "Create Route53 record for www subdomain"
  type        = bool
  default     = false

  # Set to true if you want www.example.com to point to ALB
}

variable "ssl_policy" {
  description = "SSL/TLS policy for ALB listeners"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"

  # Options:
  # - ELBSecurityPolicy-TLS-1-2-2017-01: TLS 1.2+ (recommended)
  # - ELBSecurityPolicy-TLS-1-2-Ext-2018-06: TLS 1.2+ with more ciphers
  # - ELBSecurityPolicy-FS-1-2-Res-2019-08: TLS 1.2+ with forward secrecy (most secure)
}