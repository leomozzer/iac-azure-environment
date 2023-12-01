resource "azapi_resource" "rg" {
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
  parent_id = "/subscriptions/${var.subscription_id}"
  name      = var.resource_group_name
  location  = var.location
}

resource "azapi_resource" "vnet" {
  depends_on = [azapi_resource.rg]
  type       = "Microsoft.Network/virtualNetworks@2021-08-01"
  parent_id  = "/subscriptions/${var.subscription_id}/resourceGroups/${azapi_resource.rg.name}"
  name       = var.vnet_name
  location   = var.location
  body = jsonencode({
    properties = merge({
      addressSpace = {
        addressPrefixes = var.vnet_address_prefix
      }
    })
  })
  lifecycle {
    ignore_changes = [body]
  }
}

resource "azapi_resource" "subnets" {
  for_each = {
    for subnet, value in var.subnets : subnet => value
  }
  depends_on = [azapi_resource.vnet]
  type       = "Microsoft.Network/virtualNetworks/subnets@2022-07-01"
  parent_id  = azapi_resource.vnet.id
  name       = each.value["name"]
  body = jsonencode({
    properties = {
      addressPrefix = each.value["subnet_range"]
    }
  })
  lifecycle {
    ignore_changes = [body]
  }
}
