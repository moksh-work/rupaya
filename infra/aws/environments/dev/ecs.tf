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
          value = "postgres://${var.db_master_username}:${var.db_master_password}@${aws_db_instance.rupaya_postgres_dev.endpoint}/${var.db_name}?sslmode=require"
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
      command     = ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
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
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name = "rupaya-backend-dev-tg"
  }
}

resource "aws_lb_listener" "rupaya_backend_dev" {
  load_balancer_arn = aws_lb.rupaya_backend_dev.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rupaya_backend_dev.arn
  }
}

# ========== ECS SERVICE ==========
resource "aws_ecs_service" "rupaya_backend_dev" {
  name            = "rupaya-backend-dev"
  cluster         = aws_ecs_cluster.rupaya_dev.id
  task_definition = aws_ecs_task_definition.rupaya_backend_dev.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"
  network_mode    = "awsvpc"

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
  value       = aws_ecs_service.rupaya_backend_dev.arn
  description = "ECS service ARN"
}

output "target_group_arn" {
  value       = aws_lb_target_group.rupaya_backend_dev.arn
  description = "Target group ARN"
}
