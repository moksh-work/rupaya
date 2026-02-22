data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service", identifiers = ["ec2.amazonaws.com"] }
  }
}

resource "aws_iam_role" "instance_role" {
  name               = "${var.project_name}-ec2-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.instance_role.name
}

locals {
  user_data = <<-EOF
              #!/bin/bash
              set -eux
              apt-get update -y || yum update -y || true
              command -v docker >/dev/null || (curl -fsSL https://get.docker.com | sh)
              systemctl enable docker || true
              systemctl start docker || true
              REGION=${REGION:-us-east-1}
              REPO_URL=${REPO_URL}
              aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REPO_URL"
              docker pull "$REPO_URL:${IMAGE_TAG}"
              docker run -d --name rupaya -p ${PORT}:${PORT} \
                -e PORT=${PORT} -e NODE_ENV=production -e FRONTEND_URL=${FRONTEND_URL} \
                -e DB_HOST=${DB_HOST} -e DB_NAME=${DB_NAME} -e DB_USER=${DB_USER} -e DB_PASSWORD=${DB_PASSWORD} \
                -e REDIS_URL=${REDIS_URL} "$REPO_URL:${IMAGE_TAG}"
              EOF
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-ec2-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  iam_instance_profile { name = aws_iam_instance_profile.profile.name }
  vpc_security_group_ids = [aws_security_group.ec2.id]
  user_data = base64encode(local.user_data)
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter { name = "name", values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"] }
}

resource "aws_autoscaling_group" "app" {
  name                      = "${var.project_name}-ec2-asg"
  desired_capacity          = var.desired_capacity
  max_size                  = var.desired_capacity + 1
  min_size                  = 1
  vpc_zone_identifier       = aws_subnet.private[*].id
  health_check_type         = "EC2"
  health_check_grace_period = 120

  launch_template { id = aws_launch_template.app.id, version = "$Latest" }

  tag { key = "Name", value = "${var.project_name}-ec2", propagate_at_launch = true }
}

resource "aws_lb" "api" {
  name               = "${var.project_name}-ec2-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "api_tg" {
  name        = "${var.project_name}-ec2-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
  health_check { path = "/health", matcher = "200" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"
  default_action { type = "forward", target_group_arn = aws_lb_target_group.api_tg.arn }
}

resource "aws_autoscaling_attachment" "alb_tg" {
  autoscaling_group_name = aws_autoscaling_group.app.name
  alb_target_group_arn   = aws_lb_target_group.api_tg.arn
}
