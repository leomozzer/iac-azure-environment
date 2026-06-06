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
  purpose  = "application-spoke"
  region   = var.region
  instance = var.instance
}

module "naming_avd" {
  source   = "../../modules/naming"
  purpose  = "avd-spoke"
  region   = var.region
  instance = var.instance
}

locals {
  hub_vnet_name  = module.naming_hub.virtual_network
  hub_base       = trimprefix(local.hub_vnet_name, "vnet-hub-")
  app_spoke_base = trimprefix(module.naming_application.virtual_network, "vnet-")
  avd_spoke_base = trimprefix(module.naming_avd.virtual_network, "vnet-")
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

  diagnostic_settings = {
    to_log_analytics = {
      name                  = "diag-${module.naming_hub.virtual_network}"
      workspace_resource_id = data.azurerm_log_analytics_workspace.main.id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
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

  diagnostic_settings = {
    to_log_analytics = {
      name                  = "diag-setings"
      workspace_resource_id = data.azurerm_log_analytics_workspace.main.id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
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

  diagnostic_settings = {
    to_log_analytics = {
      name                  = "diag-settings"
      workspace_resource_id = data.azurerm_log_analytics_workspace.main.id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  }
}

# VNet Peerings — cross-subscription, bidirectional
# Name format: peer-<source-vnet-name>-to-<dest-purpose-spoke-region-instance>

resource "azurerm_virtual_network_peering" "hub_to_application" {
  provider                  = azurerm.subscription_hub
  name                      = "peer-${local.hub_vnet_name}-to-${local.app_spoke_base}"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = module.vnet_hub.name
  remote_virtual_network_id = module.vnet_application.resource_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
}

resource "azurerm_virtual_network_peering" "application_to_hub" {
  provider                  = azurerm.subscription_application
  name                      = "peer-${local.app_spoke_base}-to-${local.hub_vnet_name}"
  resource_group_name       = azurerm_resource_group.application.name
  virtual_network_name      = module.vnet_application.name
  remote_virtual_network_id = module.vnet_hub.resource_id
  allow_forwarded_traffic   = true
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "hub_to_avd" {
  provider                  = azurerm.subscription_hub
  name                      = "peer-${local.hub_vnet_name}-to-${local.avd_spoke_base}"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = module.vnet_hub.name
  remote_virtual_network_id = module.vnet_avd.resource_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
}

resource "azurerm_virtual_network_peering" "avd_to_hub" {
  provider                  = azurerm.subscription_avd
  name                      = "peer-${local.avd_spoke_base}-to-${local.hub_vnet_name}"
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

resource "azurerm_network_watcher" "hub" {
  provider            = azurerm.subscription_hub
  name                = module.naming_hub.network_watcher
  location            = var.region
  resource_group_name = azurerm_resource_group.hub.name
}

resource "azurerm_network_watcher" "application" {
  provider            = azurerm.subscription_application
  name                = module.naming_application.network_watcher
  location            = var.region
  resource_group_name = azurerm_resource_group.application.name
}

resource "azurerm_network_watcher" "avd" {
  provider            = azurerm.subscription_avd
  name                = module.naming_avd.network_watcher
  location            = var.region
  resource_group_name = azurerm_resource_group.avd.name
}

data "azurerm_log_analytics_workspace" "main" {
  name                = module.operationalinsights.log_analytics_workspace
  resource_group_name = azurerm_resource_group.operationalinsights.name
}

# azurerm_network_watcher_flow_log requires network_security_group_id in current provider.
# Using azapi_resource for VNet-scoped flow logs (version=2) via the Azure REST API directly.
resource "azapi_resource" "flow_log_hub" {
  provider  = azapi.subscription_hub
  type      = "Microsoft.Network/networkWatchers/flowLogs@2023-11-01"
  name      = module.naming_hub.network_watcher_flow_log
  parent_id = azurerm_network_watcher.hub.id
  location  = var.region

  body = {
    properties = {
      storageId        = azurerm_storage_account.flow_logs_hub.id
      enabled          = true
      targetResourceId = module.vnet_hub.resource_id
      format = {
        type    = "JSON"
        version = 2
      }
      retentionPolicy = {
        days    = 90
        enabled = true
      }
      flowAnalyticsConfiguration = {
        networkWatcherFlowAnalyticsConfiguration = {
          enabled                  = true
          workspaceId              = data.azurerm_log_analytics_workspace.main.workspace_id
          workspaceRegion          = var.region
          workspaceResourceId      = data.azurerm_log_analytics_workspace.main.id
          trafficAnalyticsInterval = 10
        }
      }
    }
  }
}

resource "azapi_resource" "flow_log_application" {
  provider  = azapi.subscription_application
  type      = "Microsoft.Network/networkWatchers/flowLogs@2023-11-01"
  name      = module.naming_application.network_watcher_flow_log
  parent_id = azurerm_network_watcher.application.id
  location  = var.region

  body = {
    properties = {
      storageId        = azurerm_storage_account.flow_logs_application.id
      enabled          = true
      targetResourceId = module.vnet_application.resource_id
      format = {
        type    = "JSON"
        version = 2
      }
      retentionPolicy = {
        days    = 90
        enabled = true
      }
      flowAnalyticsConfiguration = {
        networkWatcherFlowAnalyticsConfiguration = {
          enabled                  = true
          workspaceId              = data.azurerm_log_analytics_workspace.main.workspace_id
          workspaceRegion          = var.region
          workspaceResourceId      = data.azurerm_log_analytics_workspace.main.id
          trafficAnalyticsInterval = 10
        }
      }
    }
  }
}

resource "azapi_resource" "flow_log_avd" {
  provider  = azapi.subscription_avd
  type      = "Microsoft.Network/networkWatchers/flowLogs@2023-11-01"
  name      = module.naming_avd.network_watcher_flow_log
  parent_id = azurerm_network_watcher.avd.id
  location  = var.region

  body = {
    properties = {
      storageId        = azurerm_storage_account.flow_logs_avd.id
      enabled          = true
      targetResourceId = module.vnet_avd.resource_id
      format = {
        type    = "JSON"
        version = 2
      }
      retentionPolicy = {
        days    = 90
        enabled = true
      }
      flowAnalyticsConfiguration = {
        networkWatcherFlowAnalyticsConfiguration = {
          enabled                  = true
          workspaceId              = data.azurerm_log_analytics_workspace.main.workspace_id
          workspaceRegion          = var.region
          workspaceResourceId      = data.azurerm_log_analytics_workspace.main.id
          trafficAnalyticsInterval = 10
        }
      }
    }
  }
}

# ============================================================
# Diagnostic Settings — NSGs to Log Analytics
# VNet diagnostics are configured via the AVM module's diagnostic_settings input.
# ============================================================

resource "azurerm_monitor_diagnostic_setting" "nsg_hub" {
  provider                   = azurerm.subscription_hub
  name                       = "diag-${module.naming_hub.network_security_group}"
  target_resource_id         = azurerm_network_security_group.hub.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg_application" {
  provider                   = azurerm.subscription_application
  name                       = "diag-${module.naming_application.network_security_group}"
  target_resource_id         = azurerm_network_security_group.application.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg_avd" {
  provider                   = azurerm.subscription_avd
  name                       = "diag-${module.naming_avd.network_security_group}"
  target_resource_id         = azurerm_network_security_group.avd.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}
