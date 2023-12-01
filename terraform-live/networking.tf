##########################
#   Configure Hub Vnets  #
##########################

module "default_hubs" {
  source = "../terraform-modules/azapi/vnet"
  for_each = {
    for index, hub in local.default_vnet_hub : index => hub
  }
  location            = each.value.location
  subscription_id     = each.value.subscription_id
  resource_group_name = each.value.hub_resource_group_name
  vnet_name           = each.value.hub_vnet_name
  vnet_address_prefix = each.value.address_prefix
  subnets             = each.value.subnets
}

##########################
# Configure Spoke Vnets  #
##########################

module "default_spokes" {
  source = "../terraform-modules/azapi/vnet"
  for_each = {
    for index, hub in local.default_vnet_spokes : index => hub
  }
  location            = each.value.location
  subscription_id     = each.value.subscription_id
  resource_group_name = each.value.spoke_resource_group_name
  vnet_name           = each.value.spoke_vnet_name
  vnet_address_prefix = each.value.address_prefix
  subnets             = each.value.subnets
}
