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
