# Staging Environment Infrastructure
# Similar to Dev but with higher resources and better reliability
# RDS: db.t3.small (2 vCPU, 2GB RAM, multi-AZ)
# Redis: cache.t3.small (1GB, encryption)
# ECS: 2-3 tasks, better auto-scaling

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "rupaya-terraform-state"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "rupaya-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "staging"
      Project     = "rupaya"
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}

# ========== VPC & NETWORKING ==========

data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ========== SECURITY GROUPS ==========

resource "aws_security_group" "ecs_staging" {
  name        = "rupaya-ecs-staging"
  description = "Security group for Staging ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/8"]
    description     = "ECS service port from VPC"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_staging.id]
    description = "From ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rupaya-ecs-staging"
  }
}

resource "aws_security_group" "rds_staging" {
  name        = "rupaya-rds-staging"
  description = "Security group for Staging RDS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_staging.id]
    description     = "PostgreSQL from ECS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rupaya-rds-staging"
  }
}

resource "aws_security_group" "redis_staging" {
  name        = "rupaya-redis-staging"
  description = "Security group for Staging Redis"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_staging.id]
    description     = "Redis from ECS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rupaya-redis-staging"
  }
}

resource "aws_security_group" "alb_staging" {
  name        = "rupaya-alb-staging"
  description = "Security group for Staging ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rupaya-alb-staging"
  }
}

# ========== RDS POSTGRESQL ==========

resource "aws_db_subnet_group" "staging" {
  name       = "rupaya-staging"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "rupaya-staging"
  }
}

resource "aws_rds_cluster" "staging" {
  cluster_identifier      = "rupaya-staging"
  engine                  = "aurora-postgresql"
  engine_version          = var.postgres_version
  master_username         = var.db_username
  master_password         = var.db_master_password
  database_name           = var.db_name
  db_subnet_group_name    = aws_db_subnet_group.staging.name
  vpc_security_group_ids  = [aws_security_group.rds_staging.id]
  
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.staging.arn
  backup_retention_period = 14
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"
  
  enabled_cloudwatch_logs_exports = ["postgresql"]
  publicly_accessible             = false
  skip_final_snapshot             = false
  final_snapshot_identifier       = "rupaya-staging-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  tags = {
    Name = "rupaya-staging"
  }
}

resource "aws_rds_cluster_instance" "staging" {
  count              = 2
  identifier         = "rupaya-staging-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.staging.id
  instance_class     = var.rds_instance_class
  engine             = aws_rds_cluster.staging.engine
  engine_version     = aws_rds_cluster.staging.engine_version
  
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  
  tags = {
    Name = "rupaya-staging-${count.index + 1}"
  }
}

# ========== ELASTICACHE REDIS ==========

resource "aws_elasticache_subnet_group" "staging" {
  name       = "rupaya-staging"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "rupaya-staging"
  }
}

resource "aws_elasticache_replication_group" "staging" {
  replication_group_description = "Staging Redis cluster for Rupaya"
  engine                        = "redis"
  engine_version                = var.redis_version
  node_type                     = var.redis_node_type
  num_cache_clusters            = 2
  parameter_group_name          = aws_elasticache_parameter_group.staging.name
  port                          = 6379
  subnet_group_name             = aws_elasticache_subnet_group.staging.name
  security_group_ids            = [aws_security_group.redis_staging.id]
  
  automatic_failover_enabled    = true
  multi_az_enabled              = true
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true
  auth_token_enabled            = true
  auth_token                    = var.redis_auth_token
  
  snapshot_retention_limit      = 7
  snapshot_window               = "03:00-05:00"
  maintenance_window            = "mon:04:00-mon:05:00"
  
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_staging_slow.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  depends_on = [aws_cloudwatch_log_group.redis_staging_slow]

  tags = {
    Name = "rupaya-staging"
  }
}

resource "aws_elasticache_parameter_group" "staging" {
  family      = "redis7"
  name        = "rupaya-staging"
  description = "Parameter group for Staging Redis"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  tags = {
    Name = "rupaya-staging"
  }
}

# ========== ECR REPOSITORY ==========

resource "aws_ecr_repository" "staging" {
  name                 = "rupaya-backend-staging"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "rupaya-backend-staging"
  }
}

resource "aws_ecr_lifecycle_policy" "staging" {
  repository = aws_ecr_repository.staging.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ========== CLOUDWATCH LOG GROUP ==========

resource "aws_cloudwatch_log_group" "ecs_staging" {
  name              = "/ecs/rupaya-backend-staging"
  retention_in_days = 14

  tags = {
    Name = "rupaya-backend-staging"
  }
}

resource "aws_cloudwatch_log_group" "redis_staging_slow" {
  name              = "/aws/elasticache/rupaya-staging/slow-log"
  retention_in_days = 7

  tags = {
    Name = "rupaya-staging-redis-slow-log"
  }
}

# ========== ECS CLUSTER ==========

resource "aws_ecs_cluster" "staging" {
  name = "rupaya-staging"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "rupaya-staging"
  }
}

resource "aws_ecs_cluster_capacity_providers" "staging" {
  cluster_name = aws_ecs_cluster.staging.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# ========== IAM ROLES ==========

resource "aws_iam_role" "ecs_task_execution_role_staging" {
  name = "rupaya-ecs-task-execution-role-staging"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_staging" {
  role       = aws_iam_role.ecs_task_execution_role_staging.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_logging_staging" {
  name = "rupaya-ecs-task-execution-logging-staging"
  role = aws_iam_role.ecs_task_execution_role_staging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ecs_staging.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = aws_ecr_repository.staging.arn
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_role_staging" {
  name = "rupaya-ecs-task-role-staging"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "ecs_task_policy_staging" {
  name = "rupaya-ecs-task-policy-staging"
  role = aws_iam_role.ecs_task_role_staging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ecs_staging.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role" "rds_monitoring" {
  name = "rupaya-rds-monitoring-staging"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ========== KMS KEY FOR ENCRYPTION ==========

resource "aws_kms_key" "staging" {
  description             = "KMS key for Staging environment encryption"
  multi_region            = false
  enable_key_rotation     = true
  rotation_period_in_days = 90
}

resource "aws_kms_alias" "staging" {
  name          = "alias/rupaya-staging"
  target_key_id = aws_kms_key.staging.key_id
}

# ========== OUTPUTS ==========

output "rds_endpoint" {
  description = "RDS Aurora cluster endpoint"
  value       = aws_rds_cluster.staging.endpoint
}

output "redis_endpoint" {
  description = "Redis replication group endpoint"
  value       = aws_elasticache_replication_group.staging.primary_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = 6379
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.staging.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.staging.name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.staging.arn
}

output "iam_ecs_task_execution_role_arn" {
  description = "IAM role ARN for ECS task execution"
  value       = aws_iam_role.ecs_task_execution_role_staging.arn
}

output "iam_ecs_task_role_arn" {
  description = "IAM role ARN for ECS task"
  value       = aws_iam_role.ecs_task_role_staging.arn
}

output "security_group_ecs_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_staging.id
}

output "security_group_rds_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds_staging.id
}

output "security_group_redis_id" {
  description = "Security group ID for Redis"
  value       = aws_security_group.redis_staging.id
}

output "security_group_alb_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb_staging.id
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for ECS"
  value       = aws_cloudwatch_log_group.ecs_staging.name
}
