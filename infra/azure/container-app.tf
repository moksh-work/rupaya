resource "azurerm_user_assigned_identity" "app_identity" {
  name                = "${var.project_name}-identity"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_key_vault_access_policy" "app_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app_identity.principal_id

  secret_permissions = ["Get", "List"]
}

resource "azurerm_container_app" "api" {
  name                         = "${var.project_name}-api"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_identity.id]
  }

  template {
    container {
      name   = "${var.project_name}-backend"
      image  = "${azurerm_container_registry.acr.login_server}/${var.project_name}-backend:${var.image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "PORT"
        value = tostring(var.container_port)
      }
      env { name = "NODE_ENV" value = "production" }
      env { name = "FRONTEND_URL" value = var.frontend_url }
      env { name = "DB_HOST" value = azurerm_postgresql_flexible_server.db.fqdn }
      env { name = "DB_NAME" value = var.project_name }
      env { name = "DB_USER" value = var.db_admin_username }
      env { name = "REDIS_URL" value = "redis://${azurerm_redis_cache.cache.hostname}:6379" }

      secret {
        name                 = "db-password"
        key_vault_secret_id  = azurerm_key_vault_secret.db_password.id
      }
      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }
    }

    scale {
      min_replicas = 1
      max_replicas = 3
    }
  }

  ingress {
    external_enabled = true
    target_port      = var.container_port
  }
}
