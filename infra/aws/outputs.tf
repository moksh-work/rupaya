output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.api.dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.backend.repository_url
}

output "rds_endpoint" {
  description = "Postgres endpoint"
  value       = aws_db_instance.postgres.address
}

output "redis_primary_endpoint" {
  description = "Redis primary endpoint"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}
# ========== SSL/TLS CERTIFICATE OUTPUTS (from module) ==========

output "certificate_production_arn" {
  description = "ARN of production SSL certificate"
  value       = module.certificates.certificate_production_arn
}

output "certificate_production_domain_validation_options" {
  description = "Production certificate domain validation options"
  value = {
    domains = module.certificates.certificate_production_domains
    status  = module.certificates.certificate_production_status
  }
}

output "certificate_staging_arn" {
  description = "ARN of staging SSL certificate"
  value       = module.certificates.certificate_staging_arn
}

output "certificate_staging_domain_validation_options" {
  description = "Staging certificate domain validation options"
  value = {
    domains = module.certificates.certificate_staging_domains
    status  = module.certificates.certificate_staging_status
  }
}

# ========== ROUTE53 ENDPOINTS ==========

output "api_production_endpoint" {
  description = "Production API endpoint"
  value       = "https://api.${var.route53_domain}"
}

output "api_staging_endpoint" {
  description = "Staging API endpoint"
  value       = "https://staging-api.${var.route53_domain}"
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "route53_zone_nameservers" {
  description = "Route53 nameservers (add to domain registrar)"
  value       = aws_route53_zone.main.name_servers
}

# ========== SNS NOTIFICATIONS (from module) ==========

output "certificate_alert_topic_arn" {
  description = "SNS topic ARN for certificate expiration alerts"
  value       = module.certificates.certificate_alert_topic_arn
}

output "certificate_alert_note" {
  description = "Important: Check your email to confirm SNS subscription"
  value       = module.certificates.certificate_alert_note
}