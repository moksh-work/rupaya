# Application Load Balancer for ECS backend

resource "aws_lb" "backend" {
  name               = "rupaya-sandbox-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.network.public_subnets
  tags               = local.common_tags
}

resource "aws_lb_target_group" "backend" {
  name     = "rupaya-sandbox-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id
  target_type = "ip"
  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = local.common_tags
}

resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.backend.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

