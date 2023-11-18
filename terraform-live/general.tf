resource "azurerm_resource_group" "rg_general" {
  provider = azurerm.management
  name     = local.rg_general_name
  location = var.principal_location
}

resource "azurerm_key_vault" "kv_general" {
  provider            = azurerm.management
  name                = local.kv_general_name
  resource_group_name = azurerm_resource_group.rg_general.name
  location            = azurerm_resource_group.rg_general.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}


