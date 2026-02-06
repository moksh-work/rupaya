resource "aws_cloudwatch_log_group" "redis" {
  name              = "/aws/elasticache/${var.project_name}-redis"
  retention_in_days = 14
  tags              = { Name = "${var.project_name}-redis-log" }
}

resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/rds/${var.project_name}-postgres"
  retention_in_days = 14
  tags              = { Name = "${var.project_name}-rds-log" }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-api"
  retention_in_days = 14
  tags              = { Name = "${var.project_name}-lambda-log" }
}
