output "cluster_endpoint" { value = aws_eks_cluster.main.endpoint, description = "EKS cluster endpoint" }
output "cluster_name" { value = aws_eks_cluster.main.name, description = "EKS cluster name" }
output "ecr_repository_url" { value = aws_ecr_repository.backend.repository_url, description = "ECR URL" }
output "rds_endpoint" { value = aws_db_instance.postgres.address, description = "Postgres endpoint" }
output "redis_primary_endpoint" { value = aws_elasticache_replication_group.redis.primary_endpoint_address, description = "Redis endpoint" }
