resource "azurerm_redis_cache" "cache" {
  name                = "${var.project_name}-sl-redis"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  capacity            = 1
  family              = "C"
  sku_name            = "Basic"
}
