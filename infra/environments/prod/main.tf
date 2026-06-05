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

# Network Security Groups (one per VNet, associated with workload subnets)
resource "azurerm_network_security_group" "hub" {
  provider            = azurerm.subscription_hub
  name                = module.naming_hub.network_security_group
  location            = var.region
  resource_group_name = azurerm_resource_group.hub.name
}

resource "azurerm_network_security_group" "application" {
  provider            = azurerm.subscription_application
  name                = module.naming_application.network_security_group
  location            = var.region
  resource_group_name = azurerm_resource_group.application.name
}

resource "azurerm_network_security_group" "avd" {
  provider            = azurerm.subscription_avd
  name                = module.naming_avd.network_security_group
  location            = var.region
  resource_group_name = azurerm_resource_group.avd.name
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

  subnets = {
    workload = {
      name             = module.naming_hub.subnet
      address_prefixes = ["10.10.0.0/24"]
      network_security_group = {
        id = azurerm_network_security_group.hub.id
      }
    }
  }
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

  subnets = {
    workload = {
      name             = module.naming_application.subnet
      address_prefixes = ["10.10.2.0/24"]
      network_security_group = {
        id = azurerm_network_security_group.application.id
      }
    }
  }
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

  subnets = {
    workload = {
      name             = module.naming_avd.subnet
      address_prefixes = ["10.10.5.0/25"]
      network_security_group = {
        id = azurerm_network_security_group.avd.id
      }
    }
  }
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

# ============================================================
# VNet Flow Logs
# NSG flow logs deprecated July 30, 2025 — VNet-scoped (version=2) is current approach.
# ============================================================

module "naming_flow_hub" {
  source   = "../../modules/naming"
  purpose  = "flow-hub"
  region   = var.region
  instance = var.instance
}

module "naming_flow_app" {
  source   = "../../modules/naming"
  purpose  = "flow-app"
  region   = var.region
  instance = var.instance
}

module "naming_flow_avd" {
  source   = "../../modules/naming"
  purpose  = "flow-avd"
  region   = var.region
  instance = var.instance
}

resource "azurerm_storage_account" "flow_logs_hub" {
  provider                        = azurerm.subscription_hub
  name                            = module.naming_flow_hub.storage_account
  resource_group_name             = azurerm_resource_group.hub.name
  location                        = var.region
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_account" "flow_logs_application" {
  provider                        = azurerm.subscription_application
  name                            = module.naming_flow_app.storage_account
  resource_group_name             = azurerm_resource_group.application.name
  location                        = var.region
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_account" "flow_logs_avd" {
  provider                        = azurerm.subscription_avd
  name                            = module.naming_flow_avd.storage_account
  resource_group_name             = azurerm_resource_group.avd.name
  location                        = var.region
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

# Network Watcher data sources (Azure auto-creates per region per subscription)
data "azurerm_network_watcher" "hub" {
  provider            = azurerm.subscription_hub
  name                = "NetworkWatcher_${var.region}"
  resource_group_name = "NetworkWatcherRG"
}

data "azurerm_network_watcher" "application" {
  provider            = azurerm.subscription_application
  name                = "NetworkWatcher_${var.region}"
  resource_group_name = "NetworkWatcherRG"
}

data "azurerm_network_watcher" "avd" {
  provider            = azurerm.subscription_avd
  name                = "NetworkWatcher_${var.region}"
  resource_group_name = "NetworkWatcherRG"
}

resource "azurerm_network_watcher_flow_log" "hub" {
  provider                  = azurerm.subscription_hub
  name                      = module.naming_hub.network_watcher_flow_log
  network_watcher_name      = data.azurerm_network_watcher.hub.name
  resource_group_name       = data.azurerm_network_watcher.hub.resource_group_name
  location                  = var.region
  storage_account_id        = azurerm_storage_account.flow_logs_hub.id
  enabled                   = true
  version                   = 2
  network_security_group_id = azurerm_network_security_group.hub.id

  retention_policy {
    enabled = true
    days    = 90
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = module.avm-res-operationalinsights-workspace.resource.workspace_id
    workspace_region      = var.region
    workspace_resource_id = module.avm-res-operationalinsights-workspace.resource_id
    interval_in_minutes   = 10
  }
}

resource "azurerm_network_watcher_flow_log" "application" {
  provider                  = azurerm.subscription_application
  name                      = module.naming_application.network_watcher_flow_log
  network_watcher_name      = data.azurerm_network_watcher.application.name
  resource_group_name       = data.azurerm_network_watcher.application.resource_group_name
  location                  = var.region
  storage_account_id        = azurerm_storage_account.flow_logs_application.id
  enabled                   = true
  version                   = 2
  network_security_group_id = azurerm_network_security_group.application.id
  retention_policy {
    enabled = true
    days    = 90
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = module.avm-res-operationalinsights-workspace.resource.workspace_id
    workspace_region      = var.region
    workspace_resource_id = module.avm-res-operationalinsights-workspace.resource_id
    interval_in_minutes   = 10
  }
}

resource "azurerm_network_watcher_flow_log" "avd" {
  provider                  = azurerm.subscription_avd
  name                      = module.naming_avd.network_watcher_flow_log
  network_watcher_name      = data.azurerm_network_watcher.avd.name
  resource_group_name       = data.azurerm_network_watcher.avd.resource_group_name
  location                  = var.region
  storage_account_id        = azurerm_storage_account.flow_logs_avd.id
  enabled                   = true
  version                   = 2
  network_security_group_id = azurerm_network_security_group.avd.id
  retention_policy {
    enabled = true
    days    = 90
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = module.avm-res-operationalinsights-workspace.resource.workspace_id
    workspace_region      = var.region
    workspace_resource_id = module.avm-res-operationalinsights-workspace.resource_id
    interval_in_minutes   = 10
  }
}
