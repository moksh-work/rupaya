variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
}

variable "route53_domain" {
  description = "Root domain for Route53 zone (e.g. example.com)"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for certificate validation records"
  type        = string
}

variable "certificate_alert_email" {
  description = "Email address for certificate expiration alerts"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.certificate_alert_email))
    error_message = "Must be a valid email address"
  }
}

variable "certificate_validation_timeout" {
  description = "Timeout for certificate validation (allow DNS propagation)"
  type        = string
  default     = "15m"
}

variable "enable_staging_certificate" {
  description = "Create staging certificate (set to false if not needed)"
  type        = bool
  default     = true
}
