// Terraform config for EC2-based deployment

resource "aws_instance" "app" {
  ami           = var.ec2_ami
  instance_type = var.ec2_instance_type
  subnet_id     = var.ec2_subnet_id
  vpc_security_group_ids = var.ec2_security_group_ids

  tags = {
    Name = "rupaya-app-server"
  }
}

resource "aws_security_group" "app_sg" {
  name        = "rupaya-app-sg"
  description = "Allow web and SSH access"
  vpc_id      = var.ec2_vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}
