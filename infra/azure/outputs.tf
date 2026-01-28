output "container_app_fqdn" {
  value       = azurerm_container_app.api.latest_revision_fqdn
  description = "Public URL for the API"
}

output "acr_login_server" {
  value       = azurerm_container_registry.acr.login_server
  description = "ACR login server"
}

output "postgres_fqdn" {
  value       = azurerm_postgresql_flexible_server.db.fqdn
  description = "Postgres FQDN"
}

output "redis_hostname" {
  value       = azurerm_redis_cache.cache.hostname
  description = "Redis hostname"
}
