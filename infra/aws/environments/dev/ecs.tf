# ========== ECS TASK DEFINITION ==========
resource "aws_ecs_task_definition" "rupaya_backend_dev" {
  family                   = "rupaya-backend-dev"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "rupaya-backend"
    image     = var.container_image != "" ? var.container_image : "${aws_ecr_repository.rupaya_backend.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
      protocol      = "tcp"
    }]

    environment = concat(
      [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "DATABASE_URL"
          value = "postgres://${var.db_master_username}:${local.effective_db_master_password}@${aws_db_instance.rupaya_postgres_dev.endpoint}/${var.db_name}?sslmode=require"
        },
        {
          name  = "REDIS_URL"
          value = "redis://${aws_elasticache_cluster.rupaya_redis_dev.cache_nodes[0].address}:${aws_elasticache_cluster.rupaya_redis_dev.port}"
        },
        {
          name  = "PORT"
          value = tostring(var.container_port)
        }
      ],
      [
        for key, value in var.environment_variables : {
          name  = key
          value = value
        }
      ]
    )

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_dev.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:3000/healthz || exit 1"]
      interval    = 30
      timeout     = 10
      retries     = 5
      startPeriod = 180
    }
  }])

  tags = {
    Name = "rupaya-backend-dev"
  }
}

# ========== APPLICATION LOAD BALANCER ==========
resource "aws_lb" "rupaya_backend_dev" {
  name               = "rupaya-backend-dev-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_dev.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = false

  tags = {
    Name = "rupaya-backend-dev-alb"
  }
}

resource "aws_lb_target_group" "rupaya_backend_dev" {
  name        = "rupaya-backend-dev-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    path                = "/healthz"
    matcher             = "200"
  }

  tags = {
    Name = "rupaya-backend-dev-tg"
  }
}

locals {
  create_route53_zone_for_dev = var.create_route53_zone && var.domain_name != ""
  effective_route53_zone_id = var.route53_zone_id != "" ? var.route53_zone_id : (
    local.create_route53_zone_for_dev ? aws_route53_zone.rupaya_dev[0].zone_id : ""
  )
  create_route53_alias_records_for_dev = var.domain_name != "" && (var.route53_zone_id != "" || var.create_route53_zone)
  # ACM creation depends only on input variables (not on Route53 zone_id) to avoid circular dependency
  create_acm_for_dev = var.create_acm_certificate && var.domain_name != ""
  # Determine if HTTPS should be enabled based on input variables, not on validation status
  # This avoids circular dependency: HTTPS listener is created regardless of ACM validation state
  https_enabled = var.acm_certificate_arn != "" || local.create_acm_for_dev
  # Effective ARN is used for the listener after apply (once cert is validated)
  effective_acm_certificate_arn = var.acm_certificate_arn != "" ? var.acm_certificate_arn : (
    local.create_acm_for_dev ? aws_acm_certificate.rupaya_dev[0].arn : ""
  )
}

resource "aws_route53_zone" "rupaya_dev" {
  count = local.create_route53_zone_for_dev ? 1 : 0
  name  = var.domain_name

  tags = {
    Name = "rupaya-dev-zone"
  }
}

resource "aws_acm_certificate" "rupaya_dev" {
  count                     = local.create_acm_for_dev ? 1 : 0
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "rupaya-backend-dev-acm"
  }
}

resource "aws_route53_record" "rupaya_dev_cert_validation" {
  for_each = local.create_acm_for_dev ? {
    for dvo in aws_acm_certificate.rupaya_dev[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  zone_id         = local.effective_route53_zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]

  # Explicit dependency: ensure Route53 zone is created before validation records
  depends_on = [aws_route53_zone.rupaya_dev]
}

resource "aws_acm_certificate_validation" "rupaya_dev" {
  count                   = local.create_acm_for_dev ? 1 : 0
  certificate_arn         = aws_acm_certificate.rupaya_dev[0].arn
  validation_record_fqdns = [for record in aws_route53_record.rupaya_dev_cert_validation : record.fqdn]
}

resource "aws_route53_record" "rupaya_dev_apex_alias" {
  count   = local.create_route53_alias_records_for_dev ? 1 : 0
  zone_id = local.effective_route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.rupaya_backend_dev.dns_name
    zone_id                = aws_lb.rupaya_backend_dev.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "rupaya_dev_wildcard_alias" {
  count   = local.create_route53_alias_records_for_dev ? 1 : 0
  zone_id = local.effective_route53_zone_id
  name    = "*.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.rupaya_backend_dev.dns_name
    zone_id                = aws_lb.rupaya_backend_dev.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb_listener" "rupaya_backend_dev" {
  load_balancer_arn = aws_lb.rupaya_backend_dev.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = local.https_enabled ? [1] : []
    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = local.https_enabled ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.rupaya_backend_dev.arn
    }
  }
}

resource "aws_lb_listener" "rupaya_backend_dev_https" {
  count             = local.https_enabled ? 1 : 0
  load_balancer_arn = aws_lb.rupaya_backend_dev.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = local.effective_acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rupaya_backend_dev.arn
  }

  # Wait for ACM cert validation if creating a new cert
  depends_on = [aws_acm_certificate_validation.rupaya_dev]
}

# ========== ECS SERVICE ==========
resource "aws_ecs_service" "rupaya_backend_dev" {
  name                               = "rupaya-backend-dev"
  cluster                            = aws_ecs_cluster.rupaya_dev.id
  task_definition                    = aws_ecs_task_definition.rupaya_backend_dev.arn
  desired_count                      = var.ecs_desired_count
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 120
  wait_for_steady_state              = true
  launch_type                        = "FARGATE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_dev.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.rupaya_backend_dev.arn
    container_name   = "rupaya-backend"
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.rupaya_backend_dev,
    aws_lb_listener.rupaya_backend_dev_https,
    aws_iam_role_policy.ecs_task_execution_logs_policy
  ]

  tags = {
    Name = "rupaya-backend-dev"
  }
}

# ========== AUTO SCALING ==========
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.ecs_max_count
  min_capacity       = var.ecs_min_count
  resource_id        = "service/${aws_ecs_cluster.rupaya_dev.name}/${aws_ecs_service.rupaya_backend_dev.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "rupaya-backend-dev-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "rupaya-backend-dev-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}

# ========== OUTPUTS ==========
output "alb_dns_name" {
  value       = aws_lb.rupaya_backend_dev.dns_name
  description = "ALB DNS name"
}

output "alb_arn" {
  value       = aws_lb.rupaya_backend_dev.arn
  description = "ALB ARN"
}

output "ecs_service_name" {
  value       = aws_ecs_service.rupaya_backend_dev.name
  description = "ECS service name"
}

output "ecs_service_arn" {
  value       = aws_ecs_service.rupaya_backend_dev.id
  description = "ECS service ARN"
}

output "target_group_arn" {
  value       = aws_lb_target_group.rupaya_backend_dev.arn
  description = "Target group ARN"
}

output "acm_certificate_arn_effective" {
  value       = local.effective_acm_certificate_arn
  description = "Effective ACM certificate ARN used by HTTPS listener"
}

output "api_base_url" {
  value       = local.https_enabled ? "https://${aws_lb.rupaya_backend_dev.dns_name}" : "http://${aws_lb.rupaya_backend_dev.dns_name}"
  description = "Base URL for API access"
}

output "route53_name_servers" {
  value       = local.create_route53_zone_for_dev ? aws_route53_zone.rupaya_dev[0].name_servers : []
  description = "Name servers to configure at your domain registrar when create_route53_zone is enabled"
}
