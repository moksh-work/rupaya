# ECS Service, Task Definition, ALB, and Advanced Features for Production

# ========== APPLICATION LOAD BALANCER (Multi-AZ) ==========

resource "aws_lb" "prod" {
  name               = "rupaya-prod-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_prod.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = true
  enable_http2               = true
  enable_http_draining       = true
  idle_timeout               = 60
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    enabled = true
  }

  tags = {
    Name = "rupaya-prod-alb"
  }
}

# S3 bucket for ALB logs
resource "aws_s3_bucket" "alb_logs" {
  bucket = "rupaya-prod-alb-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "rupaya-prod-alb-logs"
  }
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_caller_identity" "current" {}

# ALB target group with health checks
resource "aws_lb_target_group" "prod" {
  name        = "rupaya-prod-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15  # More frequent in production
    path                = "/health"
    matcher             = "200"
  }

  deregistration_delay = 30

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }

  tags = {
    Name = "rupaya-prod-tg"
  }
}

# HTTP listener that redirects to HTTPS
resource "aws_lb_listener" "prod_http" {
  load_balancer_arn = aws_lb.prod.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS listener (requires certificate)
resource "aws_lb_listener" "prod_https" {
  load_balancer_arn = aws_lb.prod.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod.arn
  }
}

# ========== ECS TASK DEFINITION ==========

resource "aws_ecs_task_definition" "prod" {
  family                   = "rupaya-backend-prod"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role_prod.arn
  task_role_arn            = aws_iam_role.ecs_task_role_prod.arn

  container_definitions = jsonencode([{
    name      = "rupaya-backend"
    image     = "${aws_ecr_repository.prod.repository_url}:latest"
    essential = true
    
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "NODE_ENV"
        value = "production"
      },
      {
        name  = "LOG_LEVEL"
        value = "warn"
      },
      {
        name  = "PORT"
        value = "3000"
      },
      {
        name  = "DB_HOST"
        value = aws_rds_cluster.prod.endpoint
      },
      {
        name  = "DB_PORT"
        value = "5432"
      },
      {
        name  = "DB_NAME"
        value = var.db_name
      },
      {
        name  = "DB_USER"
        value = var.db_username
      },
      {
        name  = "REDIS_HOST"
        value = aws_elasticache_replication_group.prod.primary_endpoint_address
      },
      {
        name  = "REDIS_PORT"
        value = "6379"
      }
    ]

    secrets = [
      {
        name      = "DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.db_password_prod.arn}:password::"
      },
      {
        name      = "REDIS_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.redis_password_prod.arn}:password::"
      },
      {
        name      = "JWT_SECRET"
        valueFrom = "${aws_secretsmanager_secret.jwt_secret_prod.arn}:password::"
      },
      {
        name      = "JWT_REFRESH_SECRET"
        valueFrom = "${aws_secretsmanager_secret.jwt_refresh_secret_prod.arn}:password::"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_prod.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = {
    Name = "rupaya-backend-prod"
  }
}

# ========== ECS SERVICE WITH CANARY DEPLOYMENT ==========

resource "aws_ecs_service" "prod" {
  name            = "rupaya-backend-prod"
  cluster         = aws_ecs_cluster.prod.id
  task_definition = aws_ecs_task_definition.prod.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_prod.id]
    assign_public_ip = false  # No public IP in production
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.prod.arn
    container_name   = "rupaya-backend"
    container_port   = 3000
  }

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
    deployment_circuit_breaker {
      enable   = true
      rollback = true
    }
  }

  # Enable ECS Exec for debugging
  enable_execute_command = true

  depends_on = [
    aws_lb_listener.prod_https,
    aws_iam_role_policy.ecs_task_execution_logging_prod
  ]

  tags = {
    Name = "rupaya-backend-prod"
  }
}

# ========== SERVICE DISCOVERY ==========

resource "aws_service_discovery_private_dns_namespace" "prod" {
  name = "rupaya-prod.local"
  vpc  = data.aws_vpc.default.id

  tags = {
    Name = "rupaya-prod"
  }
}

resource "aws_service_discovery_service" "prod" {
  name = "backend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.prod.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = {
    Name = "rupaya-backend-prod"
  }
}

# ========== AUTO SCALING (Advanced) ==========

resource "aws_appautoscaling_target" "prod" {
  max_capacity       = var.ecs_max_count
  min_capacity       = var.ecs_min_count
  resource_id        = "service/${aws_ecs_cluster.prod.name}/${aws_ecs_service.prod.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "prod_cpu" {
  name               = "rupaya-prod-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.prod.resource_id
  scalable_dimension = aws_appautoscaling_target.prod.scalable_dimension
  service_namespace  = aws_appautoscaling_target.prod.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 65.0  # More aggressive in production
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "prod_memory" {
  name               = "rupaya-prod-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.prod.resource_id
  scalable_dimension = aws_appautoscaling_target.prod.scalable_dimension
  service_namespace  = aws_appautoscaling_target.prod.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 75.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# ========== CLOUDWATCH ALARMS ==========

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "rupaya-prod-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when ECS CPU is high"
  
  dimensions = {
    ClusterName = aws_ecs_cluster.prod.name
    ServiceName = aws_ecs_service.prod.name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "rupaya-prod-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "Alert when RDS CPU is high"
  
  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.prod.id
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "rupaya-prod-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alert when ALB has unhealthy targets"
  
  dimensions = {
    TargetGroup  = aws_lb_target_group.prod.arn_suffix
    LoadBalancer = aws_lb.prod.arn_suffix
  }
}

# ========== OUTPUTS ==========

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.prod.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.prod.arn
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.prod.name
}

output "ecs_service_arn" {
  description = "ECS service ARN"
  value       = aws_ecs_service.prod.arn
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.prod.arn
}

output "security_group_ecs_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_prod.id
}

output "security_group_rds_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds_prod.id
}

output "security_group_redis_id" {
  description = "Security group ID for Redis"
  value       = aws_security_group.redis_prod.id
}

output "security_group_alb_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb_prod.id
}
