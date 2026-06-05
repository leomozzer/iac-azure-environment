module "operationalinsights" {
  source   = "../../modules/naming"
  purpose  = "monitoring"
  region   = var.region
  instance = var.instance
}

resource "azurerm_resource_group" "operationalinsights" {
  name     = module.operationalinsights.resource_group
  location = var.region
}

module "avm-res-operationalinsights-workspace" {
  source              = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version             = "0.5.1"
  resource_group_name = azurerm_resource_group.operationalinsights.name
  location            = var.region
  name                = module.operationalinsights.log_analytics_workspace
}

# ============================================================
# Hub-and-Spoke Landing Zone
# ============================================================

module "naming_hub" {
  source   = "../../modules/naming"
  purpose  = "hub"
  region   = var.region
  instance = var.instance
}

module "naming_application" {
  source   = "../../modules/naming"
  purpose  = "application"
  region   = var.region
  instance = var.instance
}

module "naming_avd" {
  source   = "../../modules/naming"
  purpose  = "avd"
  region   = var.region
  instance = var.instance
}

locals {
  hub_vnet_name = module.naming_hub.virtual_network
  # Extracts "eus-001" from "vnet-hub-eus-001" — used to build directional peering names
  hub_base = trimprefix(local.hub_vnet_name, "vnet-hub-")
}

# Resource Groups
resource "azurerm_resource_group" "hub" {
  provider = azurerm.subscription_hub
  name     = module.naming_hub.resource_group
  location = var.region
}

resource "azurerm_resource_group" "application" {
  provider = azurerm.subscription_application
  name     = module.naming_application.resource_group
  location = var.region
}

resource "azurerm_resource_group" "avd" {
  provider = azurerm.subscription_avd
  name     = module.naming_avd.resource_group
  location = var.region
}

# Hub VNet — Subscription A
module "vnet_hub" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  providers = {
    azurerm = azurerm.subscription_hub
    azapi   = azapi.subscription_hub
  }

  name          = module.naming_hub.virtual_network
  location      = var.region
  parent_id     = azurerm_resource_group.hub.id
  address_space = ["10.10.0.0/23"]
}

# Application Spoke VNet — Subscription B
module "vnet_application" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  providers = {
    azurerm = azurerm.subscription_application
    azapi   = azapi.subscription_application
  }

  name          = module.naming_application.virtual_network
  location      = var.region
  parent_id     = azurerm_resource_group.application.id
  address_space = ["10.10.2.0/24"]
}

# AVD Spoke VNet — Subscription C
module "vnet_avd" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  providers = {
    azurerm = azurerm.subscription_avd
    azapi   = azapi.subscription_avd
  }

  name          = module.naming_avd.virtual_network
  location      = var.region
  parent_id     = azurerm_resource_group.avd.id
  address_space = ["10.10.5.0/25"]
}

# VNet Peerings — cross-subscription, bidirectional
# Name format: peer-<source-vnet-name>-to-<dest-purpose-spoke-region-instance>

resource "azurerm_virtual_network_peering" "hub_to_application" {
  provider                  = azurerm.subscription_hub
  name                      = "peer-${local.hub_vnet_name}-to-application-spoke-${local.hub_base}"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = module.vnet_hub.name
  remote_virtual_network_id = module.vnet_application.resource_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
}

resource "azurerm_virtual_network_peering" "application_to_hub" {
  provider                  = azurerm.subscription_application
  name                      = "peer-application-spoke-${local.hub_base}-to-${local.hub_vnet_name}"
  resource_group_name       = azurerm_resource_group.application.name
  virtual_network_name      = module.vnet_application.name
  remote_virtual_network_id = module.vnet_hub.resource_id
  allow_forwarded_traffic   = true
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "hub_to_avd" {
  provider                  = azurerm.subscription_hub
  name                      = "peer-${local.hub_vnet_name}-to-avd-spoke-${local.hub_base}"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = module.vnet_hub.name
  remote_virtual_network_id = module.vnet_avd.resource_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
}

resource "azurerm_virtual_network_peering" "avd_to_hub" {
  provider                  = azurerm.subscription_avd
  name                      = "peer-avd-spoke-${local.hub_base}-to-${local.hub_vnet_name}"
  resource_group_name       = azurerm_resource_group.avd.name
  virtual_network_name      = module.vnet_avd.name
  remote_virtual_network_id = module.vnet_hub.resource_id
  allow_forwarded_traffic   = true
  use_remote_gateways       = false
}
