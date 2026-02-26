terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  # Uncomment when ready to use remote state
  # backend "s3" {
  #   bucket         = "rupaya-terraform-state"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "development"
      ManagedBy   = "terraform"
      Project     = "rupaya"
      CreatedAt   = timestamp()
    }
  }
}

resource "random_password" "db_master_password" {
  length  = 24
  special = false
}

locals {
  effective_db_master_password = var.db_master_password != "" ? var.db_master_password : random_password.db_master_password.result
}

# ========== DATA SOURCES ==========
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ========== SECURITY GROUPS ==========
resource "aws_security_group" "ecs_dev" {
  name        = "rupaya-backend-dev-sg"
  description = "Security group for Rupaya backend development environment"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from ALB"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "rupaya-backend-dev-sg"
  }
}

resource "aws_security_group" "rds_dev" {
  name        = "rupaya-postgres-dev-sg"
  description = "Security group for Rupaya PostgreSQL development"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_dev.id]
    description     = "Allow PostgreSQL from ECS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rupaya-postgres-dev-sg"
  }
}

resource "aws_security_group" "redis_dev" {
  name        = "rupaya-redis-dev-sg"
  description = "Security group for Rupaya Redis development"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_dev.id]
    description     = "Allow Redis from ECS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rupaya-redis-dev-sg"
  }
}

# ========== RDS POSTGRES ==========
resource "aws_db_subnet_group" "rupaya_dev" {
  name       = "rupaya-dev"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "rupaya-dev"
  }
}

resource "aws_db_instance" "rupaya_postgres_dev" {
  identifier     = "rupaya-postgres-dev"
  engine         = "postgres"
  engine_version = var.postgres_version
  instance_class = var.rds_instance_class

  allocated_storage     = var.allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  deletion_protection   = false
  skip_final_snapshot   = true # For dev only; use snapshots in prod

  db_name  = var.db_name
  username = var.db_master_username
  password = local.effective_db_master_password

  vpc_security_group_ids = [aws_security_group.rds_dev.id]
  db_subnet_group_name   = aws_db_subnet_group.rupaya_dev.name
  publicly_accessible    = true # Only for dev; keep private in prod

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  enabled_cloudwatch_logs_exports = ["postgresql"]

  multi_az = false # Single AZ for cost savings in dev

  tags = {
    Name = "rupaya-postgres-dev"
  }
}

# ========== ELASTICACHE REDIS ==========
resource "aws_elasticache_subnet_group" "rupaya_dev" {
  name       = "rupaya-dev"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "rupaya-dev"
  }
}

resource "aws_elasticache_cluster" "rupaya_redis_dev" {
  cluster_id           = "rupaya-redis-dev"
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = var.redis_version
  port                 = 6379

  subnet_group_name          = aws_elasticache_subnet_group.rupaya_dev.name
  security_group_ids         = [aws_security_group.redis_dev.id]
  transit_encryption_enabled = false # Can enable if client supports

  maintenance_window = "mon:03:00-mon:04:00"

  notification_topic_arn = null # Optional: SNS for notifications

  tags = {
    Name = "rupaya-redis-dev"
  }
}

# ========== ECR REPOSITORY ==========
resource "aws_ecr_repository" "rupaya_backend" {
  name                 = "rupaya-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "rupaya-backend"
  }
}

resource "aws_ecr_lifecycle_policy" "rupaya_backend" {
  repository = aws_ecr_repository.rupaya_backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 20 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 20
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep dev-tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ========== CLOUDWATCH LOGS ==========
resource "aws_cloudwatch_log_group" "ecs_dev" {
  name              = "/ecs/rupaya-backend-dev"
  retention_in_days = 7 # Change to 30+ for production

  tags = {
    Name = "rupaya-backend-dev"
  }
}

# ========== ECS CLUSTER ==========
resource "aws_ecs_cluster" "rupaya_dev" {
  name = "rupaya-dev"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "rupaya-dev"
  }
}

resource "aws_ecs_cluster_capacity_providers" "rupaya_dev" {
  cluster_name = aws_ecs_cluster.rupaya_dev.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }

  default_capacity_provider_strategy {
    weight            = 0
    capacity_provider = "FARGATE_SPOT"
  }
}

# ========== IAM for ECS Task Execution ==========
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "rupaya-ecs-task-execution-role-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "rupaya-ecs-task-execution-role-dev"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_logs_policy" {
  name = "ecs-task-execution-logs-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ecs_dev.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_execution_ecr_policy" {
  name = "ecs-task-execution-ecr-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      }
    ]
  })
}

# ========== IAM for ECS Task (Application) ==========
resource "aws_iam_role" "ecs_task_role" {
  name = "rupaya-ecs-task-role-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "rupaya-ecs-task-role-dev"
  }
}

# ========== OUTPUTS ==========
output "rds_endpoint" {
  value       = aws_db_instance.rupaya_postgres_dev.endpoint
  description = "RDS PostgreSQL endpoint"
}

output "redis_endpoint" {
  value       = "${aws_elasticache_cluster.rupaya_redis_dev.cache_nodes[0].address}:${aws_elasticache_cluster.rupaya_redis_dev.port}"
  description = "Redis endpoint"
}

output "ecr_repository_uri" {
  value       = aws_ecr_repository.rupaya_backend.repository_url
  description = "ECR repository URI"
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.rupaya_dev.name
  description = "ECS cluster name"
}

output "ecs_cluster_arn" {
  value       = aws_ecs_cluster.rupaya_dev.arn
  description = "ECS cluster ARN"
}

output "ecs_task_execution_role_arn" {
  value       = aws_iam_role.ecs_task_execution_role.arn
  description = "ECS task execution role ARN"
}

output "ecs_task_role_arn" {
  value       = aws_iam_role.ecs_task_role.arn
  description = "ECS task role ARN"
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.ecs_dev.name
  description = "CloudWatch log group name"
}

output "security_group_ecs_id" {
  value       = aws_security_group.ecs_dev.id
  description = "ECS security group ID"
}
