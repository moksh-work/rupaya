# ALB DNS output
output "alb_dns_name" {
  value = aws_lb.backend.dns_name
}
# RDS password output for automation (sensitive)
output "rds_password" {
  value     = var.db_password
  sensitive = true
}
# Example outputs for environment

output "environment_name" {
  value = var.env_name
}

output "app_domain" {
  value = var.app_domain
}

# RDS outputs for automation
output "rds_endpoint" {
  value = module.db.db_instance_endpoint
}

output "rds_username" {
  value     = module.db.db_instance_username
  sensitive = true
}

output "rds_db_name" {
  value = module.db.db_instance_name
}
