# ECS Fargate backend service for sandbox

resource "aws_ecs_cluster" "backend" {
  name = "rupaya-sandbox-backend-cluster"
  tags = local.common_tags
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "rupaya-sandbox-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions    = jsonencode([
    {
      name      = "backend"
      image     = "445830509717.dkr.ecr.us-east-1.amazonaws.com/rupaya-backend:latest"
      essential = true
      portMappings = [{ containerPort = 3000, hostPort = 3000 }]
      environment = [
        { name = "DB_HOST", value = regex("^(.*):", module.db.db_instance_endpoint)[0] },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_NAME", value = module.db.db_instance_name },
        { name = "DB_USER", value = module.db.db_instance_username },
        { name = "DB_PASSWORD", value = var.db_password }
      ]
    }
  ])
  tags = local.common_tags
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "rupaya-sandbox-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
  tags = local.common_tags
}

data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "backend" {
  name            = "rupaya-sandbox-backend"
  cluster         = aws_ecs_cluster.backend.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = module.network.private_subnets
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 3000
  }
  tags = local.common_tags
  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_policy, aws_lb_listener.backend]
}
