resource "random_password" "db_password" {
  length  = 20
  special = true
}

resource "aws_db_subnet_group" "postgres" {
  name       = "${var.project_name}-eks-db-subnet"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "postgres" {
  identifier              = "${var.project_name}-eks-postgres"
  engine                  = "postgres"
  engine_version          = "15.5"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  db_name                 = var.project_name
  username                = var.project_name
  password                = random_password.db_password.result
  skip_final_snapshot     = true
  deletion_protection     = false
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.cluster.id]
  db_subnet_group_name    = aws_db_subnet_group.postgres.name
}
