resource "aws_lb" "api" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = { Name = "${var.project_name}-alb" }
}

resource "aws_lb_target_group" "api_tg" {
  name        = "${var.project_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    path                = "/health"
    matcher             = "200"
  }
}

# ========== HTTP LISTENER (Port 80) ==========
# Redirect all HTTP traffic to HTTPS for security
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301" # Permanent redirect
    }
  }
}

# ========== HTTPS LISTENER (Port 443) - PRODUCTION ==========
# Main HTTPS listener for production traffic
# Uses production certificate from ACM
resource "aws_lb_listener" "https_prod" {
  load_balancer_arn = aws_lb.api.arn
  port              = 443
  protocol          = "HTTPS"

  # Use production certificate (auto-renewed by AWS)
  certificate_arn = module.certificates.certificate_production_arn
  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01" # TLS 1.2 minimum

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }

  # Ensure certificate is validated before creating listener
  depends_on = [module.certificates]

  tags = {
    Name        = "${var.project_name}-listener-https-prod"
    Environment = "production"
  }
}

# Optional: HTTPS listener for staging domain
# Useful if you need separate staging infrastructure
resource "aws_lb_listener" "https_staging" {
  count             = var.enable_staging_listener ? 1 : 0
  load_balancer_arn = aws_lb.api.arn
  port              = 8443 # Alternative HTTPS port for staging
  protocol          = "HTTPS"

  # Use staging certificate
  certificate_arn = module.certificates.certificate_staging_arn
  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }

  depends_on = [module.certificates]

  tags = {
    Name        = "${var.project_name}-listener-https-staging"
    Environment = "staging"
  }
}
