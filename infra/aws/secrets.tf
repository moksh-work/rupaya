resource "random_password" "db_password" {
  length  = 20
  special = true
}

resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

resource "random_password" "refresh_token_secret" {
  length  = 64
  special = false
}

resource "random_password" "encryption_key" {
  length  = 32
  special = false
}

# ============================================================================
# RDS Database Credentials Secret
# ============================================================================
# Stores complete RDS connection details including username, password, 
# host, port, and database name. This is retrieved by GitHub Actions 
# workflows at runtime instead of storing individual credentials in GitHub.

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project_name}/rds/credentials"
  description             = "RDS database credentials for ${var.project_name}"
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.project_name}-rds-credentials"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = aws_db_instance.postgres.username
    password = aws_secretsmanager_secret_version.db_password.secret_string
    engine   = aws_db_instance.postgres.engine
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    dbname   = aws_db_instance.postgres.db_name
  })
}

# ============================================================================
# Staging Environment - RDS Credentials
# ============================================================================

resource "aws_secretsmanager_secret" "db_credentials_staging" {
  name                    = "${var.project_name}/rds/staging"
  description             = "RDS staging database credentials for ${var.project_name}"
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.project_name}-rds-staging-credentials"
    Environment = "staging"
    ManagedBy   = "Terraform"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials_staging" {
  secret_id = aws_secretsmanager_secret.db_credentials_staging.id
  secret_string = jsonencode({
    username = aws_db_instance.postgres.username
    password = aws_secretsmanager_secret_version.db_password.secret_string
    engine   = aws_db_instance.postgres.engine
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    dbname   = "${aws_db_instance.postgres.db_name}_staging"
  })
}

# ============================================================================
# Production Environment - RDS Credentials
# ============================================================================

resource "aws_secretsmanager_secret" "db_credentials_prod" {
  name                    = "${var.project_name}/rds/production"
  description             = "RDS production database credentials for ${var.project_name}"
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.project_name}-rds-production-credentials"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials_prod" {
  secret_id = aws_secretsmanager_secret.db_credentials_prod.id
  secret_string = jsonencode({
    username = aws_db_instance.postgres.username
    password = aws_secretsmanager_secret_version.db_password.secret_string
    engine   = aws_db_instance.postgres.engine
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    dbname   = "${aws_db_instance.postgres.db_name}_production"
  })
}

# ============================================================================
# Automatic Secret Rotation
# ============================================================================

resource "aws_secretsmanager_secret_rotation" "db_credentials_rotation" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  rotation_rules {
    automatically_after_days = 30
  }

  # Note: Rotation Lambda function must be created separately
  # See: https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotation.html
}

# ============================================================================
# JWT & Application Secrets (Also in Secrets Manager for consistency)
# ============================================================================

resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project_name}/db/password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name = "${var.project_name}/jwt/secret"
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = random_password.jwt_secret.result
}

resource "aws_secretsmanager_secret" "refresh_token_secret" {
  name = "${var.project_name}/jwt/refresh-token-secret"
}

resource "aws_secretsmanager_secret_version" "refresh_token_secret" {
  secret_id     = aws_secretsmanager_secret.refresh_token_secret.id
  secret_string = random_password.refresh_token_secret.result
}

resource "aws_secretsmanager_secret" "encryption_key" {
  name = "${var.project_name}/encryption/key"
}

resource "aws_secretsmanager_secret_version" "encryption_key" {
  secret_id     = aws_secretsmanager_secret.encryption_key.id
  secret_string = random_password.encryption_key.result
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-backend"
  retention_in_days = 14
  tags              = { Name = "${var.project_name}-backend-log" }
}

resource "aws_cloudwatch_log_group" "redis_slow" {
  name              = "/aws/elasticache/${var.project_name}-redis-slow"
  retention_in_days = 14
  tags              = { Name = "${var.project_name}-redis-slow-log" }
}
