resource "azapi_resource" "rg" {
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
  parent_id = "/subscriptions/${var.subscription_id}"
  name      = var.spoke_resource_group_name
  location  = var.location
}

resource "azapi_resource" "vnet" {
  depends_on = [azapi_resource.rg]
  type       = "Microsoft.Network/virtualNetworks@2021-08-01"
  parent_id  = "/subscriptions/${var.subscription_id}/resourceGroups/${azapi_resource.rg.name}"
  name       = var.spoke_vnet_name
  location   = var.location
  body       = var.vnet_body
  lifecycle {
    ignore_changes = [body]
  }
}

resource "azapi_resource" "default_subnet" {
  depends_on = [azapi_resource.vnet]
  type       = "Microsoft.Network/virtualNetworks/subnets@2022-07-01"
  parent_id  = azapi_resource.vnet.id
  name       = var.default_subnet_name
  body       = var.default_subnet_body
  lifecycle {
    ignore_changes = [body]
  }
}

resource "azapi_resource" "spoke_to_hub" {
  for_each = {
    for value, key in local.hubs : value => key
  }
  depends_on = [azapi_resource.vnet]
  type       = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01"
  parent_id  = azapi_resource.vnet.id
  name       = "${azapi_resource.vnet.name}-to-${each.value.hub_vnet_name}"
  body = jsonencode({
    properties = {
      remoteVirtualNetwork = {
        id = "/subscriptions/${each.value.subscription_id}/resourceGroups/${each.value.hub_resource_group_name}/providers/Microsoft.Network/virtualNetworks/${each.value.hub_vnet_name}"
      }
      useRemoteGateways     = false
      allowForwardedTraffic = true
    }
  })
}

resource "azapi_resource" "hub_to_spoke" {
  for_each = {
    for value, key in local.hubs : value => key
  }
  depends_on = [azapi_resource.vnet]
  type       = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01"
  parent_id  = "/subscriptions/${each.value.subscription_id}/resourceGroups/${each.value.hub_resource_group_name}/providers/Microsoft.Network/virtualNetworks/${each.value.hub_vnet_name}"
  name       = "${each.value.hub_vnet_name}-to-${azapi_resource.vnet.name}"
  body = jsonencode({
    properties = {
      remoteVirtualNetwork = {
        id = azapi_resource.vnet.id
      }
      useRemoteGateways     = false
      allowForwardedTraffic = true
    }
  })
}
