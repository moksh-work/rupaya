# ALB security group for backend load balancer
resource "aws_security_group" "alb" {
  name        = "rupaya-sandbox-alb-sg"
  description = "Allow HTTP from anywhere"
  vpc_id      = module.network.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}
# ECS security group for backend tasks
resource "aws_security_group" "ecs" {
  name        = "rupaya-sandbox-ecs-sg"
  description = "Allow ALB to access ECS backend"
  vpc_id      = module.network.vpc_id

  ingress {
    description      = "From ALB"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}
# Security group for RDS instance in the same VPC
resource "aws_security_group" "rds" {
  name        = "rupaya-sandbox-db-sg"
  description = "Allow database access from VPC"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}
# Main entrypoint for environment-specific resources


provider "aws" {
  region = var.aws_region
}

# Example: Tag all resources with environment
locals {
  common_tags = {
    Environment = var.env_name
    Project     = "Rupaya"
  }
}


# Minimal infrastructure for sandbox environment

module "network" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "rupaya-sandbox-vpc"
  cidr = "10.10.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
  public_subnets  = ["10.10.101.0/24", "10.10.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  tags = local.common_tags
}

module "db" {
    create_db_subnet_group = true
  source  = "terraform-aws-modules/rds/aws"
  version = "6.3.0"

  identifier = "rupaya-sandbox-db"
  engine     = "postgres"
  engine_version = "18.1"
  family = "postgres18"
  parameter_group_name = aws_db_parameter_group.rupaya_sandbox_pg.name
  instance_class = "db.t4g.micro"
  allocated_storage = 20
  db_name           = "rupaya"
  username          = "rupaya"
  password          = var.db_password
  port              = 5432
  vpc_security_group_ids = [aws_security_group.rds.id]
  subnet_ids             = module.network.private_subnets
  publicly_accessible    = false
  skip_final_snapshot    = true
  tags = local.common_tags
}

resource "aws_db_parameter_group" "rupaya_sandbox_pg" {
  name        = "rupaya-sandbox-pg"
  family      = "postgres18"
  description = "Custom parameter group for Rupaya sandbox RDS"
  # No parameters set to avoid AWS errors
}
