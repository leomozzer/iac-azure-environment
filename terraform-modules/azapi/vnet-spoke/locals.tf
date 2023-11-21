locals {
  region_name_standardize = {
    "East US"          = "eus",
    "eastus"           = "eus"
    "east us"          = "eus"
    "West US"          = "wus",
    "North Central US" = "ncus",
    "South Central US" = "scus",
    "East US 2"        = "eastus2",
    "West US 2"        = "westus2",
    "Central US"       = "cus",
    "West Central US"  = "wcus",
    "Canada East"      = "canadaeast",
    "Canada Central"   = "canadacentral",
    "West Europe"      = "euw"
    "westeurope"       = "euw"
    # Add more mappings as needed
  }
}

locals {
  peerings = flatten([
    for value, key in var.peerings : {
      key = "${key}"
    }
  ])
}

locals {
  hubs = flatten([
    for value, key in var.hubs : {
      key                     = key
      hub_name                = "${key.hub_name}"
      subscription_id         = "${key.subscription_id}"
      hub_resource_group_name = "rg-vnet-${local.region_name_standardize[key["location"]]}-${key.hub_name}"
      hub_vnet_name           = "vnet-${local.region_name_standardize[key["location"]]}-${key.hub_name}"
    }
  ])
}
