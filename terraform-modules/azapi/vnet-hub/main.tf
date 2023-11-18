resource "azapi_resource" "rg" {
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
  parent_id = "/subscriptions/${var.subscription_id}"
  name      = var.hub_resource_group_name
  location  = var.location
}

resource "azapi_resource" "vnet" {
  depends_on = [azapi_resource.rg]
  type       = "Microsoft.Network/virtualNetworks@2021-08-01"
  parent_id  = "/subscriptions/${var.subscription_id}/resourceGroups/${azapi_resource.rg.name}"
  name       = var.hub_vnet_name
  location   = var.location
  body       = var.vnet_body
  lifecycle {
    ignore_changes = [body]
  }
}
