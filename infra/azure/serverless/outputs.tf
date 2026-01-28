output "function_app_url" {
  value       = azurerm_function_app.api.default_hostname
  description = "Function App base URL"
}
output "postgres_fqdn" {
  value       = azurerm_postgresql_flexible_server.db.fqdn
  description = "Postgres FQDN"
}
output "redis_hostname" {
  value       = azurerm_redis_cache.cache.hostname
  description = "Redis hostname"
}
