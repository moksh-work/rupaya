resource "azurerm_function_app" "api" {
  name                       = "${var.project_name}-api"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  version                    = "~4"
  os_type                    = "linux"
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "node"
    WEBSITE_RUN_FROM_PACKAGE = "1"
    PORT                     = tostring(var.container_port)
    NODE_ENV                 = "production"
    FRONTEND_URL             = var.frontend_url
    DB_HOST                  = azurerm_postgresql_flexible_server.db.fqdn
    DB_NAME                  = var.project_name
    DB_USER                  = var.db_admin_username
    DB_PASSWORD              = random_password.db_password.result
    REDIS_URL                = "redis://${azurerm_redis_cache.cache.hostname}:6379"
  }
}
