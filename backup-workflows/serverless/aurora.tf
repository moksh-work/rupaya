resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project_name}-sl-aurora-subnet"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "${var.project_name}-aurora"
  engine                  = "aurora-postgresql"
  engine_version          = "15.3"
  database_name           = var.project_name
  master_username         = var.project_name
  master_password         = random_password.db_password.result
  db_subnet_group_name    = aws_db_subnet_group.aurora.name
  vpc_security_group_ids  = [aws_security_group.aurora.id]
  deletion_protection     = false
  enable_http_endpoint    = false
  storage_encrypted       = true
  apply_immediately       = true

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2
  }
}

resource "aws_rds_cluster_instance" "aurora_instances" {
  count               = 1
  identifier          = "${var.project_name}-aurora-instance-${count.index}"
  cluster_identifier  = aws_rds_cluster.aurora.id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.aurora.engine
  engine_version      = aws_rds_cluster.aurora.engine_version
}

resource "random_password" "db_password" {
  length  = 20
  special = true
}
