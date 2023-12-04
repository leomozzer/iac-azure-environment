##########################
#  Configure Hub Vnets   #
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

##################################
# Configure Peering hub <> Spoke #
##################################

module "peering_hub_spoke" {
  source          = "../terraform-modules/azapi/peering-hub-spoke"
  count           = length(local.default_vnet_spokes)
  vnet_hub_name   = module.default_hubs[0].vnet.name
  vnet_hub_id     = module.default_hubs[0].vnet.id
  vnet_spoke_name = module.default_spokes[count.index].vnet.name
  vnet_spoke_id   = module.default_spokes[count.index].vnet.id
}
