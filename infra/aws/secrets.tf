resource "random_password" "db_password" {
  length           = 20
  special          = true
  override_characters = "!@#%^&*()-_=+"
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project_name}/db/password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-backend"
  retention_in_days = 14
}
