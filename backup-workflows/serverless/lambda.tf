data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.project_name}-sl-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "vpc_access" {
  name = "${var.project_name}-sl-lambda-vpc"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["ec2:CreateNetworkInterface","ec2:DescribeNetworkInterfaces","ec2:DeleteNetworkInterface"], Resource = "*" }
    ]
  })
}

resource "aws_lambda_function" "api" {
  function_name = "${var.project_name}-api"
  role          = aws_iam_role.lambda_exec.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.backend.repository_url}:${var.image_tag}"

  timeout = 15
  memory_size = 512

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      PORT          = tostring(var.container_port)
      NODE_ENV      = "production"
      FRONTEND_URL  = var.frontend_url
      DB_HOST       = aws_rds_cluster.aurora.endpoint
      DB_NAME       = var.project_name
      DB_USER       = var.project_name
      REDIS_URL     = "redis://${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"
      # For Lambda Web Adapter, uncomment if your image uses it
      # AWS_LAMBDA_EXEC_WRAPPER = "/opt/bootstrap"
      LOG_GROUP     = aws_cloudwatch_log_group.lambda.name
    }
  }
  depends_on = [aws_cloudwatch_log_group.lambda]
}
