module "hub" {
  for_each = {
    for index, hub in local.vnet_hub : index => hub
  }
  source                  = "../terraform-modules/azapi/vnet-hub"
  location                = each.value.location
  subscription_id         = each.value.subscription_id
  hub_resource_group_name = each.value.hub_resource_group_name
  hub_vnet_name           = each.value.hub_vnet_name
  vnet_body               = each.value.azapi_vnet_body
  subnets                 = each.value.subnets
}
module "spoke" {
  source     = "../terraform-modules/azapi/vnet-spoke"
  depends_on = [module.hub]
  for_each = {
    for index, hub in local.vnet_spoke : index => hub
  }
  location                  = each.value.location
  subscription_id           = each.value.subscription_id
  spoke_resource_group_name = each.value.spoke_resource_group_name
  spoke_vnet_name           = each.value.spoke_vnet_name
  vnet_body                 = each.value.azapi_vnet_body
  hubs                      = each.value.hubs
  peerings                  = each.value.peerings
  default_subnet_name       = each.value.default_subnet_name
  default_subnet_body       = each.value.azapi_subnet_body
}
