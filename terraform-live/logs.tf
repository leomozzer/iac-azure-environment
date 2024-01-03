resource "azurerm_resource_group" "rg_laws_operations" {
  provider = azurerm.management
  name     = local.rg_law_operations_name
  location = var.principal_location
}

resource "azurerm_log_analytics_workspace" "laws_operations" {
  provider            = azurerm.management
  name                = local.law_operations_name
  location            = azurerm_resource_group.rg_laws_operations.location
  resource_group_name = azurerm_resource_group.rg_laws_operations.name
  sku                 = local.law_operations_sku
  retention_in_days   = local.law_operations_retention_in_days
}
