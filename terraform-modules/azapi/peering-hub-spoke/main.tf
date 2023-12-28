resource "azapi_resource" "hub_to_spoke" {
  type      = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01"
  parent_id = var.vnet_hub_id
  name      = "${var.vnet_hub_name}-to-${var.vnet_spoke_name}"
  body = jsonencode({
    properties = {
      remoteVirtualNetwork = {
        id = var.vnet_spoke_id
      }
      useRemoteGateways     = false
      allowForwardedTraffic = true
    }
  })
}

resource "azapi_resource" "spoke_to_hub" {
  type      = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01"
  parent_id = var.vnet_spoke_id
  name      = "${var.vnet_spoke_name}-to-${var.vnet_hub_name}"
  body = jsonencode({
    properties = {
      remoteVirtualNetwork = {
        id = var.vnet_hub_id
      }
      useRemoteGateways     = false
      allowForwardedTraffic = true
    }
  })
}
