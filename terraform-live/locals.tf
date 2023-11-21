# Define a function to standardize Azure region names
#https://github.com/claranet/terraform-azurerm-regions/blob/master/REGIONS.md
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
  rg_general_name        = "rg-${var.environment_name}-${local.region_name_standardize[var.principal_location]}-general"
  kv_general_name        = "kv-${var.environment_name}-${local.region_name_standardize[var.principal_location]}-general"
  rg_law_operations_name = "rg-operations-01"
  law_operations_name    = "law-operations-01"
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

# locals {
#   initiative_list = flatten([
#     for index, initiative in var.initiative_definitions : {
#       "initiative" : {
#         "definitions" : [for definition in var.policy_definitions : module.bulk_definition[definition.name].definition if contains(initiative.definitions, definition.name) == true]
#         "initiative_name" : initiative.initiative_name
#         "initiative_display_name" : initiative.initiative_display_name
#         "initiative_category" : initiative.initiative_category
#         "initiative_description" : initiative.initiative_description
#         "assignment_effect" : initiative.assignment_effect
#         "skip_role_assignment"   = initiative.skip_role_assignment
#         "skip_remediation"       = initiative.skip_remediation
#         "re_evaluate_compliance" = initiative.re_evaluate_compliance
#         "module_index"           = index
#       }
#     }
#   ])
# }

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
