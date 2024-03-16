# Define a function to standardize Azure region names
#https://github.com/claranet/terraform-azurerm-regions/blob/master/REGIONS.md
#######################
#    Commom locals    #
#######################
locals {
  region_name_standardize = {
    "East US"           = "eus"
    "eastus"            = "eus"
    "east us"           = "eus"
    "West US"           = "wus"
    "North Central US"  = "ncus"
    "South Central US"  = "scus"
    "East US 2"         = "eus2"
    "West US 2"         = "wus2"
    "Central US"        = "cus"
    "West Central US"   = "wcus"
    "Canada East"       = "canadaeast"
    "Canada Central"    = "canadacentral"
    "West Europe"       = "weu"
    "westeurope"        = "weu"
    "west europe"       = "weu"
    "North Europe"      = "neu"
    "northeurope"       = "neu"
    "UK South"          = "uks"
    "UK West"           = "ukw"
    "France Central"    = "francecentral"
    "France South"      = "francesouth"
    "Germany North"     = "germanynorth"
    "Germany West"      = "germanywest"
    "Switzerland North" = "swnorth"
    "Switzerland West"  = "swwest"
    "Norway East"       = "noeast"
    "Norway West"       = "nowest"
    # Add more mappings as needed
  }

  sample_hub_address_spaces = [
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
    }
  ]

  sample_spoke_address_spaces = [
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

#########################
#    Resource naming    #
#########################

locals {
  rg_general_name                       = "rg-${var.environment_name}-${local.region_name_standardize[var.principal_location]}-general-01"
  kv_general_name                       = "kv-${var.environment_name}-${local.region_name_standardize[var.principal_location]}-general-01"
  kv_general_soft_delete_retention_days = 7
  kv_general_purge_protection_enabled   = false
  kv_general_sku_name                   = "standard"
  rg_defaul_monitoring                  = "rg-${var.environment_name}-${local.region_name_standardize[var.principal_location]}-monitoring-01"
  rg_law_operations_name                = "rg-${local.region_name_standardize[var.principal_location]}-operations-01"
  law_operations_name                   = "law-${local.region_name_standardize[var.principal_location]}-operations-01"
  law_operations_sku                    = "PerGB2018"
  law_operations_retention_in_days      = 30
}

##################
#    Vnet Hub    #
##################

locals {
  default_vnet_hub = length(var.default_vnet_hub_definition["hubs"]) > 0 ? flatten([
    for index, hub in var.default_vnet_hub_definition["hubs"] : {
      subscription_id         = var.default_vnet_hub_definition["subscription_id"] != "" ? var.default_vnet_hub_definition["subscription_id"] : var.management_subscription_id
      location                = hub["location"] != "" ? hub["location"] : var.principal_location
      location_short          = "${local.region_name_standardize[hub["location"] != "" ? hub["location"] : var.principal_location]}"
      hub_name                = "hub-${index > 9 ? "${index + 1}" : "0${index + 1}"}"
      hub_resource_group_name = "rg-vnet-${local.region_name_standardize[hub["location"] != "" ? hub["location"] : var.principal_location]}-hub-${index > 9 ? "${index + 1}" : "0${index + 1}"}"
      hub_vnet_name           = "vnet-${local.region_name_standardize[hub["location"] != "" ? hub["location"] : var.principal_location]}-hub-${index > 9 ? "${index + 1}" : "0${index + 1}"}"
      address_prefix          = length(hub["address_space"]) > 0 ? hub["address_space"] : local.sample_hub_address_spaces[index]["address_space"]
      subnets = flatten([
        for entry, subnet in var.default_vnet_hub_definition["hubs"]["${index}"]["subnets"] : {
          name         = "snet-hub-${entry > 9 ? "${entry + 1}" : "0${entry + 1}"}",
          subnet_range = subnet["address_prefix"]
        }
      ])
    }
    ]) : flatten([for index, value in local.sample_hub_address_spaces : {
      subscription_id         = var.default_vnet_hub_definition["subscription_id"] != "" ? var.default_vnet_hub_definition["subscription_id"] : var.management_subscription_id
      location                = var.principal_location
      location_short          = "${local.region_name_standardize[var.principal_location]}"
      hub_name                = "hub-${index > 9 ? "${index + 1}" : "0${index + 1}"}"
      hub_resource_group_name = "rg-vnet-${local.region_name_standardize[var.principal_location]}-hub-${index > 9 ? "${index + 1}" : "0${index + 1}"}"
      hub_vnet_name           = "vnet-${local.region_name_standardize[var.principal_location]}-hub-${index > 9 ? "${index + 1}" : "0${index + 1}"}"
      address_prefix          = local.sample_hub_address_spaces[index]["address_space"]
      subnets = flatten([
        for entry, subnet in local.sample_hub_address_spaces["${index}"]["subnets"] : {
          name         = "snet-hub-${entry > 9 ? "${entry + 1}" : "0${entry + 1}"}",
          subnet_range = subnet["subnet_range"]
        }
      ])
    }
  ])
}

###################
#   Vnet Spoke    #
###################

locals {
  default_vnet_spokes = length(var.default_vnet_spoke_definition[0]["spokes"]) > 0 ? flatten([
    for value, key in var.default_vnet_spoke_definition : [
      for index, spoke in lookup(key, "spokes", []) : {
        subscription_id           = key["subscription_id"] != "" ? key["subscription_id"] : var.management_subscription_id
        location                  = spoke["location"] != "" ? spoke["location"] : var.principal_location
        location_short            = "${local.region_name_standardize["${spoke["location"] != "" ? spoke["location"] : var.principal_location}"]}"
        spoke_name                = "spoke-${index > 9 ? "${index + 1}" : "0${index + 1}"}"
        spoke_resource_group_name = "rg-vnet-${local.region_name_standardize["${spoke["location"] != "" ? spoke["location"] : var.principal_location}"]}-spoke-${key["identifier"]}-${index > 9 ? "${index + 1}" : "0${index + 1}"}"
        spoke_vnet_name           = "vnet-${local.region_name_standardize["${spoke["location"] != "" ? spoke["location"] : var.principal_location}"]}-spoke-${key["identifier"]}-${index > 9 ? "${index + 1}" : "0${index + 1}"}"
        address_prefix            = spoke["address_space"]
        subnets = flatten([
          for entry, subnet in spoke["subnets"] : {
            name         = "snet-${var.default_vnet_spoke_definition[value]["identifier"]}-${entry > 9 ? "${entry + 1}" : "0${entry + 1}"}"
            subnet_range = subnet["address_prefix"]
          }
        ])
      }
    ]
    ]) : flatten([
    for index, value in local.sample_spoke_address_spaces : {
      subscription_id           = var.default_vnet_spoke_definition[index]["subscription_id"] != "" ? var.default_vnet_spoke_definition[index]["subscription_id"] : var.management_subscription_id
      location                  = var.principal_location
      location_short            = "${local.region_name_standardize[var.principal_location]}"
      spoke_name                = "spoke-${index > 9 ? "${index + 1}" : "0${index + 1}"}"
      spoke_resource_group_name = "rg-vnet-${local.region_name_standardize[var.principal_location]}-spoke-${var.default_vnet_spoke_definition[index]["identifier"]}-${index > 9 ? "${index + 1}" : "0${index + 1}"}"
      spoke_vnet_name           = "vnet-${local.region_name_standardize[var.principal_location]}-spoke-${var.default_vnet_spoke_definition[index]["identifier"]}-${index > 9 ? "${index + 1}" : "0${index + 1}"}"
      address_prefix            = local.sample_spoke_address_spaces[index]["address_space"]
      subnets = flatten([
        for entry, subnet in local.sample_spoke_address_spaces[index]["subnets"] : {
          name         = "snet-${var.default_vnet_spoke_definition[index]["identifier"]}-${entry > 9 ? "${entry + 1}" : "0${entry + 1}"}",
          subnet_range = subnet["subnet_range"]
        }
      ])
    }
  ])
}

################
#    Policy    #
################

locals {
  policy_definitions = [
    {
      name             = "deploy-keyvault-diagnostic-setting"
      skip_remediation = false
      file_name        = "deploy_keyvault_diagnostic_setting"
      display_name     = "Deploy Diagnostic Settings for KeyVaults to a Log Analytics workspace"
      location         = "eastus"
      category         = "Monitoring"
      type             = "initiative"
    },
    {
      name             = "deploy-vnet-diagnostic-setting"
      skip_remediation = false
      file_name        = "deploy_vnet_diagnostic_setting"
      display_name     = "Deploy Diagnostic Settings for Vnets to a Log Analytics workspace"
      location         = "eastus"
      category         = "Monitoring"
      type             = "initiative"
    }
  ]

  initiative_definitions = [
    {
      initiative_name         = "platform_diagnostics_initiative"
      initiative_display_name = "[Monitoring]: Diagnostics Settings Policy Initiatives",
      initiative_category     = "Monitoring",
      initiative_description  = "Collection of policies that deploy resource and activity log forwarders to logging core resources"
      merge_effects           = false
      definitions             = ["diagnostic-settings-key-vaults", "deploy_vnet_diagnostic_setting"]
      assignment_effect       = "DeployIfNotExists"
      skip_role_assignment    = false
      skip_remediation        = false
      re_evaluate_compliance  = true
    }
  ]
}


################
#    Backup    #
################

