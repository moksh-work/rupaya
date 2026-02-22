# ========== CERTIFICATES MODULE ==========
# This module manages SSL/TLS certificates independently
# Can be deployed separately using: terraform apply -target=module.certificates

# ========== PRODUCTION CERTIFICATE ==========
resource "aws_acm_certificate" "production" {
  domain_name = var.route53_domain

  validation_method = "DNS"

  subject_alternative_names = [
    "api.${var.route53_domain}",
    "www.${var.route53_domain}",
    "*.${var.route53_domain}",
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-cert-prod"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# ========== STAGING CERTIFICATE ==========
resource "aws_acm_certificate" "staging" {
  domain_name = "staging-api.${var.route53_domain}"

  validation_method = "DNS"

  subject_alternative_names = [
    "staging.${var.route53_domain}",
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-cert-staging"
    Environment = "staging"
    ManagedBy   = "terraform"
  }
}

# ========== DNS VALIDATION RECORDS - PRODUCTION ==========
resource "aws_route53_record" "acm_validation_production" {
  for_each = {
    for dvo in aws_acm_certificate.production.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id

  depends_on = [aws_acm_certificate.production]
}

# ========== DNS VALIDATION RECORDS - STAGING ==========
resource "aws_route53_record" "acm_validation_staging" {
  for_each = {
    for dvo in aws_acm_certificate.staging.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id

  depends_on = [aws_acm_certificate.staging]
}

# ========== CERTIFICATE VALIDATION - PRODUCTION ==========
# This waits for the certificate to be ISSUED
# Uses extended timeout to allow DNS propagation
resource "aws_acm_certificate_validation" "production" {
  certificate_arn = aws_acm_certificate.production.arn

  timeouts {
    create = var.certificate_validation_timeout
  }

  depends_on = [
    aws_route53_record.acm_validation_production,
    aws_route53_record.acm_validation_staging,
  ]
}

# ========== CERTIFICATE VALIDATION - STAGING ==========
resource "aws_acm_certificate_validation" "staging" {
  certificate_arn = aws_acm_certificate.staging.arn

  timeouts {
    create = var.certificate_validation_timeout
  }

  depends_on = [aws_route53_record.acm_validation_staging]
}

# ========== SNS TOPIC FOR CERTIFICATE EXPIRATION ALERTS ==========
resource "aws_sns_topic" "certificate_expiration" {
  name              = "${var.project_name}-cert-expiration-alerts"
  display_name      = "Certificate Expiration Alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name        = "${var.project_name}-cert-alerts"
    Environment = "shared"
  }
}

# ========== SNS TOPIC POLICY ==========
resource "aws_sns_topic_policy" "certificate_expiration" {
  arn = aws_sns_topic.certificate_expiration.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.certificate_expiration.arn
      }
    ]
  })
}

# ========== SNS EMAIL SUBSCRIPTION ==========
resource "aws_sns_topic_subscription" "certificate_expiration_email" {
  topic_arn = aws_sns_topic.certificate_expiration.arn
  protocol  = "email"
  endpoint  = var.certificate_alert_email
}

# ========== CLOUDWATCH EVENT RULE FOR EXPIRATION MONITORING ==========
resource "aws_cloudwatch_event_rule" "acm_expiration" {
  name           = "${var.project_name}-cert-expiration-check"
  description    = "Monitor ACM certificates 30 days before expiration"
  event_bus_name = "default"

  # EventBridge rule to check certificate expiration
  event_pattern = jsonencode({
    source      = ["aws.acm"]
    detail-type = ["ACM Certificate Approaching Expiration"]
    detail = {
      DaysToExpiry = [{ numeric = ["<=", 30] }]
    }
  })

  tags = {
    Name = "${var.project_name}-cert-expiration-rule"
  }
}

# ========== CLOUDWATCH EVENT TARGET ==========
resource "aws_cloudwatch_event_target" "acm_expiration_sns" {
  rule     = aws_cloudwatch_event_rule.acm_expiration.name
  arn      = aws_sns_topic.certificate_expiration.arn
  role_arn = aws_iam_role.eventbridge_sns_role.arn

  input_transformer {
    input_paths = {
      arn         = "$.detail.arn"
      certificate = "$.detail.certificate"
      days_to_exp = "$.detail.DaysToExpiry"
    }
    input_template = "\"Certificate expiring in <days_to_exp> days: <certificate> (ARN: <arn>)\""
  }
}

# ========== IAM ROLE FOR EVENTBRIDGE ==========
resource "aws_iam_role" "eventbridge_sns_role" {
  name = "${var.project_name}-eventbridge-sns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ========== IAM ROLE POLICY ==========
resource "aws_iam_role_policy" "eventbridge_sns_policy" {
  name = "${var.project_name}-eventbridge-sns-policy"
  role = aws_iam_role.eventbridge_sns_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.certificate_expiration.arn
      }
    ]
  })
}
