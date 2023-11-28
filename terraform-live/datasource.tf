data "azurerm_client_config" "current" {}

data "azurerm_management_group" "management_group" {
  name = var.management_group
}

data "azurerm_resources" "storage_accounts" {
  type = "Microsoft.Storage/storageaccounts"
}
