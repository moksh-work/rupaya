resource "random_password" "db_password" {
  length  = 20
  special = true
}

resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "${var.project_name}-sl-pg"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = var.location
  version                = var.db_version
  administrator_login    = var.db_admin_username
  administrator_password = random_password.db_password.result
  storage_mb             = 32768
  sku_name               = "B1ms"
  zone                   = 1

  authentication {
    active_directory_auth_enabled = false
    password_auth_enabled         = true
  }

  backup {
    retention_days = 7
  }
}

resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = var.project_name
  server_id = azurerm_postgresql_flexible_server.db.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}
