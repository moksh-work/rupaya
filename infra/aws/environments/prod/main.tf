# Production Environment Infrastructure
# High-availability, multi-AZ with enhanced security
# RDS: db.r6g.large (2 vCPU, 16GB RAM, multi-AZ, read replicas)
# Redis: cache.r6g.xlarge (13GB, multi-AZ, cluster mode)
# ECS: 3-5 tasks, aggressive auto-scaling

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
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "rupaya-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      Project     = "rupaya"
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
      CostCenter  = var.cost_center
    }
  }
}

# ========== VPC & NETWORKING (Multi-AZ) ==========

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

resource "aws_security_group" "ecs_prod" {
  name        = "rupaya-ecs-prod"
  description = "Security group for Production ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_prod.id]
    description = "From ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rupaya-ecs-prod"
  }
}

resource "aws_security_group" "rds_prod" {
  name        = "rupaya-rds-prod"
  description = "Security group for Production RDS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_prod.id]
    description     = "PostgreSQL from ECS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rupaya-rds-prod"
  }
}

resource "aws_security_group" "redis_prod" {
  name        = "rupaya-redis-prod"
  description = "Security group for Production Redis"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_prod.id]
    description     = "Redis from ECS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rupaya-redis-prod"
  }
}

resource "aws_security_group" "alb_prod" {
  name        = "rupaya-alb-prod"
  description = "Security group for Production ALB"
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
    Name = "rupaya-alb-prod"
  }
}

# ========== RDS POSTGRESQL (Aurora Multi-AZ) ==========

resource "aws_db_subnet_group" "prod" {
  name       = "rupaya-prod"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "rupaya-prod"
  }
}

resource "aws_rds_cluster" "prod" {
  cluster_identifier      = "rupaya-prod"
  engine                  = "aurora-postgresql"
  engine_version          = var.postgres_version
  master_username         = var.db_username
  master_password         = var.db_master_password
  database_name           = var.db_name
  db_subnet_group_name    = aws_db_subnet_group.prod.name
  vpc_security_group_ids  = [aws_security_group.rds_prod.id]
  
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.prod.arn
  backup_retention_period = 30  # 30 day retention for production
  preferred_backup_window = "02:00-03:00"
  preferred_maintenance_window = "sun:03:00-sun:04:00"
  
  enabled_cloudwatch_logs_exports = ["postgresql"]
  publicly_accessible             = false
  skip_final_snapshot             = false
  final_snapshot_identifier       = "rupaya-prod-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  enable_http_endpoint = true  # Enable Data API for serverless access
  
  # Enhanced monitoring
  enable_cloudwatch_logs_exports = ["postgresql"]
  
  tags = {
    Name = "rupaya-prod"
  }
}

# Multiple read replicas for read scaling
resource "aws_rds_cluster_instance" "prod_primary" {
  identifier         = "rupaya-prod-primary"
  cluster_identifier = aws_rds_cluster.prod.id
  instance_class     = var.rds_instance_class
  engine             = aws_rds_cluster.prod.engine
  engine_version     = aws_rds_cluster.prod.engine_version
  
  publicly_accessible = false
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  
  performance_insights_enabled    = true
  performance_insights_retention_period = 31
  performance_insights_kms_key_id = aws_kms_key.prod.arn
  
  tags = {
    Name = "rupaya-prod-primary"
  }
}

resource "aws_rds_cluster_instance" "prod_replicas" {
  count              = 2
  identifier         = "rupaya-prod-replica-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.prod.id
  instance_class     = var.rds_instance_class
  engine             = aws_rds_cluster.prod.engine
  engine_version     = aws_rds_cluster.prod.engine_version
  
  publicly_accessible = false
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  
  performance_insights_enabled    = true
  performance_insights_retention_period = 31
  performance_insights_kms_key_id = aws_kms_key.prod.arn
  
  tags = {
    Name = "rupaya-prod-replica-${count.index + 1}"
  }
}

# ========== ELASTICACHE REDIS (Cluster Mode) ==========

resource "aws_elasticache_subnet_group" "prod" {
  name       = "rupaya-prod"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "rupaya-prod"
  }
}

resource "aws_elasticache_replication_group" "prod" {
  replication_group_description = "Production Redis cluster for Rupaya (cluster mode)"
  engine                        = "redis"
  engine_version                = var.redis_version
  node_type                     = var.redis_node_type
  num_cache_clusters            = 3
  parameter_group_name          = aws_elasticache_parameter_group.prod.name
  port                          = 6379
  subnet_group_name             = aws_elasticache_subnet_group.prod.name
  security_group_ids            = [aws_security_group.redis_prod.id]
  
  automatic_failover_enabled    = true
  multi_az_enabled              = true
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true
  auth_token_enabled            = true
  auth_token                    = var.redis_auth_token
  
  snapshot_retention_limit      = 30
  snapshot_window               = "02:00-04:00"
  maintenance_window            = "sun:04:00-sun:05:00"
  
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_prod_slow.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_prod_engine.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  depends_on = [
    aws_cloudwatch_log_group.redis_prod_slow,
    aws_cloudwatch_log_group.redis_prod_engine
  ]

  tags = {
    Name = "rupaya-prod"
  }
}

resource "aws_elasticache_parameter_group" "prod" {
  family      = "redis7"
  name        = "rupaya-prod"
  description = "Parameter group for Production Redis"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  parameter {
    name  = "tcp-keepalive"
    value = "300"
  }

  tags = {
    Name = "rupaya-prod"
  }
}

# ========== ECR REPOSITORY ==========

resource "aws_ecr_repository" "prod" {
  name                 = "rupaya-backend-prod"
  image_tag_mutability = "IMMUTABLE"  # Immutable tags in production
  
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.prod.arn
  }

  tags = {
    Name = "rupaya-backend-prod"
  }
}

resource "aws_ecr_lifecycle_policy" "prod" {
  repository = aws_ecr_repository.prod.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 50 production images tagged"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "prod"]
          countType     = "imageCountMoreThan"
          countNumber   = 50
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ========== CLOUDWATCH LOG GROUPS ==========

resource "aws_cloudwatch_log_group" "ecs_prod" {
  name              = "/ecs/rupaya-backend-prod"
  retention_in_days = 30  # 30 day retention for production

  tags = {
    Name = "rupaya-backend-prod"
  }
}

resource "aws_cloudwatch_log_group" "redis_prod_slow" {
  name              = "/aws/elasticache/rupaya-prod/slow-log"
  retention_in_days = 30

  tags = {
    Name = "rupaya-prod-redis-slow-log"
  }
}

resource "aws_cloudwatch_log_group" "redis_prod_engine" {
  name              = "/aws/elasticache/rupaya-prod/engine-log"
  retention_in_days = 30

  tags = {
    Name = "rupaya-prod-redis-engine-log"
  }
}

# ========== ECS CLUSTER ==========

resource "aws_ecs_cluster" "prod" {
  name = "rupaya-prod"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "rupaya-prod"
  }
}

resource "aws_ecs_cluster_capacity_providers" "prod" {
  cluster_name = aws_ecs_cluster.prod.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 2  # Always use FARGATE for stability
    weight            = 75
    capacity_provider = "FARGATE"
  }

  default_capacity_provider_strategy {
    weight            = 25
    capacity_provider = "FARGATE_SPOT"
  }
}

# ========== IAM ROLES ==========

resource "aws_iam_role" "ecs_task_execution_role_prod" {
  name = "rupaya-ecs-task-execution-role-prod"

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

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_prod" {
  role       = aws_iam_role.ecs_task_execution_role_prod.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_logging_prod" {
  name = "rupaya-ecs-task-execution-logging-prod"
  role = aws_iam_role.ecs_task_execution_role_prod.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ecs_prod.arn}:*"
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
        Resource = aws_ecr_repository.prod.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.db_password_prod.arn,
          aws_secretsmanager_secret.redis_password_prod.arn,
          aws_secretsmanager_secret.jwt_secret_prod.arn,
          aws_secretsmanager_secret.jwt_refresh_secret_prod.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_role_prod" {
  name = "rupaya-ecs-task-role-prod"

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

resource "aws_iam_role_policy" "ecs_task_policy_prod" {
  name = "rupaya-ecs-task-policy-prod"
  role = aws_iam_role.ecs_task_role_prod.id

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
        Resource = "${aws_cloudwatch_log_group.ecs_prod.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::rupaya-prod-backups/*"
      }
    ]
  })
}

resource "aws_iam_role" "rds_monitoring" {
  name = "rupaya-rds-monitoring-prod"

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

resource "aws_kms_key" "prod" {
  description             = "KMS key for Production environment encryption"
  multi_region            = true  # Multi-region replication for disaster recovery
  enable_key_rotation     = true
  rotation_period_in_days = 90
}

resource "aws_kms_alias" "prod" {
  name          = "alias/rupaya-prod"
  target_key_id = aws_kms_key.prod.key_id
}

# ========== SECRETS MANAGER ==========

resource "aws_secretsmanager_secret" "db_password_prod" {
  name                    = "rupaya/prod/db-password"
  recovery_window_in_days = 14  # Longer recovery for production

  tags = {
    Name = "rupaya-prod-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password_prod" {
  secret_id     = aws_secretsmanager_secret.db_password_prod.id
  secret_string = jsonencode({
    password = var.db_master_password
  })
}

resource "aws_secretsmanager_secret" "redis_password_prod" {
  name                    = "rupaya/prod/redis-password"
  recovery_window_in_days = 14

  tags = {
    Name = "rupaya-prod-redis-password"
  }
}

resource "aws_secretsmanager_secret_version" "redis_password_prod" {
  secret_id     = aws_secretsmanager_secret.redis_password_prod.id
  secret_string = jsonencode({
    password = var.redis_auth_token
  })
}

resource "aws_secretsmanager_secret" "jwt_secret_prod" {
  name                    = "rupaya/prod/jwt-secret"
  recovery_window_in_days = 14

  tags = {
    Name = "rupaya-prod-jwt-secret"
  }
}

resource "aws_secretsmanager_secret_version" "jwt_secret_prod" {
  secret_id     = aws_secretsmanager_secret.jwt_secret_prod.id
  secret_string = jsonencode({
    password = var.jwt_secret
  })
}

resource "aws_secretsmanager_secret" "jwt_refresh_secret_prod" {
  name                    = "rupaya/prod/jwt-refresh-secret"
  recovery_window_in_days = 14

  tags = {
    Name = "rupaya-prod-jwt-refresh-secret"
  }
}

resource "aws_secretsmanager_secret_version" "jwt_refresh_secret_prod" {
  secret_id     = aws_secretsmanager_secret.jwt_refresh_secret_prod.id
  secret_string = jsonencode({
    password = var.jwt_refresh_secret
  })
}

# ========== OUTPUTS ==========

output "rds_endpoint" {
  description = "RDS Aurora cluster endpoint (write)"
  value       = aws_rds_cluster.prod.endpoint
}

output "rds_reader_endpoint" {
  description = "RDS Aurora reader endpoint (read-only)"
  value       = aws_rds_cluster.prod.reader_endpoint
}

output "redis_endpoint" {
  description = "Redis replication group endpoint"
  value       = aws_elasticache_replication_group.prod.primary_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = 6379
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.prod.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.prod.name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.prod.arn
}

output "iam_ecs_task_execution_role_arn" {
  description = "IAM role ARN for ECS task execution"
  value       = aws_iam_role.ecs_task_execution_role_prod.arn
}

output "iam_ecs_task_role_arn" {
  description = "IAM role ARN for ECS task"
  value       = aws_iam_role.ecs_task_role_prod.arn
}

output "kms_key_id" {
  description = "KMS key ID for production encryption"
  value       = aws_kms_key.prod.key_id
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for ECS"
  value       = aws_cloudwatch_log_group.ecs_prod.name
}
