resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-sl-rg"
  location = var.location
}

resource "azurerm_storage_account" "sa" {
  name                     = "${var.project_name}slsa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "plan" {
  name                = "${var.project_name}-sl-plan"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "Y1"
}
