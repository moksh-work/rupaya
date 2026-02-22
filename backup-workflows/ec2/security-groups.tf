resource "aws_security_group" "alb" {
  name   = "${var.project_name}-ec2-alb-sg"
  vpc_id = aws_vpc.main.id
  ingress { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
  egress  { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "ec2" {
  name   = "${var.project_name}-ec2-app-sg"
  vpc_id = aws_vpc.main.id
  ingress { from_port = var.container_port, to_port = var.container_port, protocol = "tcp", security_groups = [aws_security_group.alb.id] }
  egress  { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "rds" {
  name   = "${var.project_name}-ec2-rds-sg"
  vpc_id = aws_vpc.main.id
  ingress { from_port = 5432, to_port = 5432, protocol = "tcp", security_groups = [aws_security_group.ec2.id] }
  egress  { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "redis" {
  name   = "${var.project_name}-ec2-redis-sg"
  vpc_id = aws_vpc.main.id
  ingress { from_port = 6379, to_port = 6379, protocol = "tcp", security_groups = [aws_security_group.ec2.id] }
  egress  { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
}
