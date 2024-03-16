terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "1.9.0"
    }
  }
}

provider "azapi" {

}

data "azurerm_subscriptions" "active" {
}

locals {
  default_backup_configuration = flatten([
    for index, subscription in data.azurerm_subscriptions.active.subscriptions : {
      id           = subscription["id"]
      display_name = subscription["display_name"]
    }
  ])
}

resource "azapi_resource" "rg" {
  for_each = {
    for index, value in local.default_backup_configuration : index => value
  }
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
  parent_id = each.value["id"]
  name      = "rg-bkp-vault"
  location  = var.principal_location
}

resource "azapi_resource" "recovery_service_vault" {
  for_each = {
    for index, value in local.default_backup_configuration : index => value
  }
  depends_on = [azapi_resource.rg]
  type       = "Microsoft.RecoveryServices/vaults@2023-01-01"
  parent_id  = "${each.value["id"]}/resourceGroups/rg-bkp-vault"
  name       = "rg-bkp-vault"
  location   = var.principal_location
  body = jsonencode({
    identity = {
      type                   = "None"
      userAssignedIdentities = null
    }
    properties = {
      publicNetworkAccess = "Enabled"
    }
    sku = {
      name = "Standard"
    }
  })
}
