# ECS Service, Task Definition, and ALB for Staging Environment

# ========== APPLICATION LOAD BALANCER ==========

resource "aws_lb" "staging" {
  name               = "rupaya-staging-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_staging.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = true
  enable_http2               = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "rupaya-staging-alb"
  }
}

resource "aws_lb_target_group" "staging" {
  name        = "rupaya-staging-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name = "rupaya-staging-tg"
  }
}

resource "aws_lb_listener" "staging" {
  load_balancer_arn = aws_lb.staging.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.staging.arn
  }
}

# ========== ECS TASK DEFINITION ==========

resource "aws_ecs_task_definition" "staging" {
  family                   = "rupaya-backend-staging"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role_staging.arn
  task_role_arn            = aws_iam_role.ecs_task_role_staging.arn

  container_definitions = jsonencode([{
    name      = "rupaya-backend"
    image     = "${aws_ecr_repository.staging.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "NODE_ENV"
        value = "staging"
      },
      {
        name  = "LOG_LEVEL"
        value = "info"
      },
      {
        name  = "PORT"
        value = "3000"
      },
      {
        name  = "DB_HOST"
        value = aws_rds_cluster.staging.endpoint
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
        value = aws_elasticache_replication_group.staging.primary_endpoint_address
      },
      {
        name  = "REDIS_PORT"
        value = "6379"
      }
    ]

    secrets = [
      {
        name      = "DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.db_password_staging.arn}:password::"
      },
      {
        name      = "REDIS_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.redis_password_staging.arn}:password::"
      },
      {
        name      = "JWT_SECRET"
        valueFrom = "${aws_secretsmanager_secret.jwt_secret_staging.arn}:password::"
      },
      {
        name      = "JWT_REFRESH_SECRET"
        valueFrom = "${aws_secretsmanager_secret.jwt_refresh_secret_staging.arn}:password::"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_staging.name
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
    Name = "rupaya-backend-staging"
  }
}

# ========== ECS SERVICE ==========

resource "aws_ecs_service" "staging" {
  name            = "rupaya-backend-staging"
  cluster         = aws_ecs_cluster.staging.id
  task_definition = aws_ecs_task_definition.staging.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_staging.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.staging.arn
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

  service_registries {
    registry_arn = aws_service_discovery_service.staging.arn
  }

  depends_on = [
    aws_lb_listener.staging,
    aws_iam_role_policy.ecs_task_execution_logging_staging
  ]

  tags = {
    Name = "rupaya-backend-staging"
  }
}

# ========== SERVICE DISCOVERY ==========

resource "aws_service_discovery_private_dns_namespace" "staging" {
  name = "rupaya-staging.local"
  vpc  = data.aws_vpc.default.id

  tags = {
    Name = "rupaya-staging"
  }
}

resource "aws_service_discovery_service" "staging" {
  name = "backend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.staging.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = {
    Name = "rupaya-backend-staging"
  }
}

# ========== AUTO SCALING ==========

resource "aws_appautoscaling_target" "staging" {
  max_capacity       = var.ecs_max_count
  min_capacity       = var.ecs_min_count
  resource_id        = "service/${aws_ecs_cluster.staging.name}/${aws_ecs_service.staging.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "staging_cpu" {
  name               = "rupaya-staging-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.staging.resource_id
  scalable_dimension = aws_appautoscaling_target.staging.scalable_dimension
  service_namespace  = aws_appautoscaling_target.staging.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_policy" "staging_memory" {
  name               = "rupaya-staging-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.staging.resource_id
  scalable_dimension = aws_appautoscaling_target.staging.scalable_dimension
  service_namespace  = aws_appautoscaling_target.staging.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}

# ========== SECRETS MANAGER FOR CREDENTIALS ==========

resource "aws_secretsmanager_secret" "db_password_staging" {
  name                    = "rupaya/staging/db-password"
  recovery_window_in_days = 7

  tags = {
    Name = "rupaya-staging-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password_staging" {
  secret_id     = aws_secretsmanager_secret.db_password_staging.id
  secret_string = jsonencode({
    password = var.db_master_password
  })
}

resource "aws_secretsmanager_secret" "redis_password_staging" {
  name                    = "rupaya/staging/redis-password"
  recovery_window_in_days = 7

  tags = {
    Name = "rupaya-staging-redis-password"
  }
}

resource "aws_secretsmanager_secret_version" "redis_password_staging" {
  secret_id     = aws_secretsmanager_secret.redis_password_staging.id
  secret_string = jsonencode({
    password = var.redis_auth_token
  })
}

resource "aws_secretsmanager_secret" "jwt_secret_staging" {
  name                    = "rupaya/staging/jwt-secret"
  recovery_window_in_days = 7

  tags = {
    Name = "rupaya-staging-jwt-secret"
  }
}

resource "aws_secretsmanager_secret_version" "jwt_secret_staging" {
  secret_id     = aws_secretsmanager_secret.jwt_secret_staging.id
  secret_string = jsonencode({
    password = var.jwt_secret
  })
}

resource "aws_secretsmanager_secret" "jwt_refresh_secret_staging" {
  name                    = "rupaya/staging/jwt-refresh-secret"
  recovery_window_in_days = 7

  tags = {
    Name = "rupaya-staging-jwt-refresh-secret"
  }
}

resource "aws_secretsmanager_secret_version" "jwt_refresh_secret_staging" {
  secret_id     = aws_secretsmanager_secret.jwt_refresh_secret_staging.id
  secret_string = jsonencode({
    password = var.jwt_refresh_secret
  })
}

# ========== OUTPUTS ==========

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.staging.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.staging.arn
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.staging.name
}

output "ecs_service_arn" {
  description = "ECS service ARN"
  value       = aws_ecs_service.staging.arn
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.staging.arn
}
