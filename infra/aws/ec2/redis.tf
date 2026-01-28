resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-ec2-redis-subnet"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "${var.project_name}-ec2-redis"
  replication_group_description = "Redis for ${var.project_name} EC2"
  engine                        = "redis"
  engine_version                = "7.1"
  node_type                     = "cache.t4g.micro"
  number_cache_clusters         = 2
  automatic_failover_enabled    = true
  multi_az_enabled              = true
  port                          = 6379
  security_group_ids            = [aws_security_group.redis.id]
  subnet_group_name             = aws_elasticache_subnet_group.redis.name
}
