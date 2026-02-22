# ========== ROUTE53 HOSTED ZONE ==========
resource "aws_route53_zone" "main" {
  name = var.route53_domain

  tags = {
    Name = "${var.project_name}-zone"
  }
}

# ========== PRODUCTION API RECORD ==========
# Main API endpoint: api.example.com → ALB
resource "aws_route53_record" "api_prod" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.${var.route53_domain}"
  type    = "A"

  alias {
    name                   = aws_lb.api.dns_name
    zone_id                = aws_lb.api.zone_id
    evaluate_target_health = true
  }

  depends_on = [module.certificates]
}

# ========== STAGING API RECORD ==========
# Staging endpoint: staging-api.example.com → ALB
resource "aws_route53_record" "api_staging" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "staging-api.${var.route53_domain}"
  type    = "A"

  alias {
    name                   = aws_lb.api.dns_name
    zone_id                = aws_lb.api.zone_id
    evaluate_target_health = true
  }

  depends_on = [module.certificates]
}

# ========== ROOT DOMAIN RECORD ==========
# Root domain: example.com → ALB (optional, for web traffic)
resource "aws_route53_record" "root" {
  count   = var.create_root_domain_record ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = var.route53_domain
  type    = "A"

  alias {
    name                   = aws_lb.api.dns_name
    zone_id                = aws_lb.api.zone_id
    evaluate_target_health = true
  }

}

# ========== WWW RECORD ==========
# WWW subdomain: www.example.com → ALB (optional, for web traffic)
resource "aws_route53_record" "www" {
  count   = var.create_www_record ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.route53_domain}"
  type    = "A"

  alias {
    name                   = aws_lb.api.dns_name
    zone_id                = aws_lb.api.zone_id
    evaluate_target_health = true
  }

}
