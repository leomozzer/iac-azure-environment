# Define a function to standardize Azure region names
#https://github.com/claranet/terraform-azurerm-regions/blob/master/REGIONS.md
##########################
#     Commom locals      #
##########################
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

  sample_address_spaces = [
    {
      address_space = ["10.0.0.0/20"]
      subnets = [
        {
          subnet_range = "10.0.0.0/24"
        },
        {
          subnet_range = "10.0.1.0/24"
        },
        {
          subnet_range = "10.0.2.0/24"
        },
        {
          subnet_range = "10.0.3.0/24"
        }
      ]
    },
    {
      address_space = ["10.0.16.0/20"]
      subnets = [
        {
          subnet_range = "10.0.16.0/24"
        },
        {
          subnet_range = "10.0.17.0/24"
        },
        {
          subnet_range = "10.0.18.0/24"
        },
        {
          subnet_range = "10.0.19.0/24"
        },
      ]
    }
  ]
}
##########################
#  Resource naming local #
##########################
locals {
  rg_general_name        = "rg-${var.environment_name}-${local.region_name_standardize[var.principal_location]}-general"
  kv_general_name        = "kv-${var.environment_name}-${local.region_name_standardize[var.principal_location]}-general"
  rg_defaul_monitoring   = "rg-${var.environment_name}-${local.region_name_standardize[var.principal_location]}-monitoring"
  rg_law_operations_name = "rg-operations-01"
  law_operations_name    = "law-operations-01"
}

##########################
#    Vnet Hub Local      #
##########################

locals {
  default_vnet_hub = flatten([
    for index, hub in var.default_vnet_hub_definition["hubs"] : {
      subscription_id         = var.default_vnet_hub_definition["subscription_id"] != "" ? var.default_vnet_hub_definition["subscription_id"] : var.management_subscription_id
      location                = hub["location"] != "" ? hub["location"] : var.principal_location
      location_short          = "${local.region_name_standardize[hub["location"] != "" ? hub["location"] : var.principal_location]}"
      hub_name                = "hub-${index > 9 ? index : "0${index + 1}"}"
      hub_resource_group_name = "rg-vnet-${local.region_name_standardize[hub["location"] != "" ? hub["location"] : var.principal_location]}-hub-${index > 9 ? index : "0${index + 1}"}"
      hub_vnet_name           = "vnet-${local.region_name_standardize[hub["location"] != "" ? hub["location"] : var.principal_location]}-hub-${index > 9 ? index : "0${index + 1}"}"
      azapi_vnet_body = jsonencode({
        properties = merge({
          addressSpace = {
            addressPrefixes = length(hub["address_space"]) > 0 ? hub["address_space"] : local.sample_address_spaces[index]["address_space"]
          }
        })
      })
    }
  ])
}

locals {
  vnet_hub = flatten([
    for value, key in var.vnet_definitions : [
      for hub_name, hub_definition in lookup(key, "vnet_hub_definitions", {}) :
      {
        subscription_id         = "${key["subscription_source_id"]}"
        location                = "${key["location"]}"
        location_short          = "${local.region_name_standardize[key["location"]]}"
        hub_name                = "${hub_name}"
        hub_resource_group_name = "rg-vnet-${local.region_name_standardize[key["location"]]}-${hub_name}"
        hub_vnet_name           = "vnet-${local.region_name_standardize[key["location"]]}-${hub_name}"
        azapi_vnet_body = jsonencode({
          properties = merge(
            {
              addressSpace = {
                addressPrefixes = "${hub_definition["address_space"]}"
              }
            }
          )
        })
        subnets = hub_definition["subnets"]
      }
    ]
  ])
}

##########################
#    Vnet Spoke Local    #
##########################

locals {
  vnet_spoke = flatten([
    for value, key in var.vnet_definitions : [
      for spoke_name, spoke_definition in lookup(key, "vnet_spoke_definitions", {}) : {
        subscription_id           = "${key["subscription_source_id"]}"
        location                  = "${key["location"]}"
        location_short            = "${local.region_name_standardize[key["location"]]}"
        spoke_name                = "${spoke_name}"
        spoke_resource_group_name = "rg-vnet-${local.region_name_standardize[key["location"]]}-spoke-${spoke_name}"
        spoke_vnet_name           = "vnet-${local.region_name_standardize[key["location"]]}-spoke-${spoke_name}"
        default_subnet_name       = "vnet-${spoke_name}"
        hubs                      = spoke_definition["hubs"]
        peerings                  = spoke_definition["peerings"]
        azapi_vnet_body = jsonencode({
          properties = merge(
            {
              addressSpace = {
                addressPrefixes = "${spoke_definition["address_space"]}"
              }
            }
          )
        })
        azapi_subnet_body = jsonencode({
          properties = {
            addressPrefix = spoke_definition["default_subnet_address_prefix"]
          }
        })
        # subnets = spoke_definition["subnets"]
      }
    ]
  ])
}

##########################
#    Monitoring Local    #
##########################
locals {
  default_alerts = {
    "storage_account_avaliability" : {
      "name" : "Storage Account Avaliability",
      "description" : "Storage Account Avaliability",
      type : "storageaccounts",
      "metrics" : {
        metric_name          = "Availability"
        enabled              = true
        evaluation_frequency = "PT5M"
        severity             = 1
        window_size          = "PT15M"
        availability = {
          threshold              = 90
          operator               = "LessThan"
          time_aggregation       = "Average"
          skip_metric_validation = false
        }
      }
    }
  }
}

locals {
  filtered_storaged_accounts = [for res, config in data.azurerm_resources.storage_accounts.resources : {
    name                = config.name
    resource_group_name = config.resource_group_name
    id                  = config.id
    tags                = config.tags
    #alerts              = [for alert, index in loclocal.storage_accounts_alerts : alert]
  } if(config.resource_group_name != "rg-exclude-from-search-dev-we")]
}

