output "alb_dns_name" { value = aws_lb.api.dns_name, description = "ALB DNS" }
output "ecr_repository_url" { value = aws_ecr_repository.backend.repository_url, description = "ECR URL" }
output "rds_endpoint" { value = aws_db_instance.postgres.address, description = "Postgres endpoint" }
output "redis_primary_endpoint" { value = aws_elasticache_replication_group.redis.primary_endpoint_address, description = "Redis endpoint" }
