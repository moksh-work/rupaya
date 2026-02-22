# ========== CERTIFICATES MODULE ==========
# Deploy certificates separately before ALB/services
# Usage: terraform apply -target=module.certificates
#
# This module creates:
# - ACM certificates for production and staging
# - Route53 DNS validation records
# - SNS topic for expiration alerts
# - CloudWatch monitoring
#
# Typical deployment:
# 1. terraform apply -target=module.certificates (wait for validation)
# 2. terraform apply (deploy everything else)

module "certificates" {
  source = "./modules/certificates"

  project_name                   = var.project_name
  route53_domain                 = var.route53_domain
  route53_zone_id                = aws_route53_zone.main.zone_id
  certificate_alert_email        = var.certificate_alert_email
  certificate_validation_timeout = var.certificate_validation_timeout
  enable_staging_certificate     = var.enable_staging_certificate
}
