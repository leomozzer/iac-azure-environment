resource "azurerm_resource_group" "rg_monitoring" {
  provider = azurerm.management
  name     = local.rg_defaul_monitoring
  location = var.principal_location
}

resource "azurerm_monitor_action_group" "azurerm_monitor_action_group" {
  provider            = azurerm.management
  short_name          = "group"
  resource_group_name = azurerm_resource_group.rg_monitoring.name
  name                = "Default Action Group"
  email_receiver {
    name          = "default"
    email_address = var.management_monitoring_email
  }
}
