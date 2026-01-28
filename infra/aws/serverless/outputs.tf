output "http_api_endpoint" {
  value       = aws_apigatewayv2_api.http.api_endpoint
  description = "Public HTTP API endpoint"
}

output "aurora_endpoint" {
  value       = aws_rds_cluster.aurora.endpoint
  description = "Aurora Postgres endpoint"
}

output "redis_primary_endpoint" {
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  description = "Redis primary endpoint"
}
