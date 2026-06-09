module "log_analytics_monitoring_eastus" {
  source   = "../../modules/log-analytics-workspace"
  purpose  = "monitoring"
  region   = "eastus"
  instance = "001"
}

module "log_analytics_monitoring_westeurope" {
  source   = "../../modules/log-analytics-workspace"
  purpose  = "monitoring"
  region   = "westeurope"
  instance = "001"
}

# ============================================================
# Hub VNet — East US
# ============================================================

module "vnet_hub_eastus_001" {
  source = "../../modules/hub-vnet"

  purpose              = "hub"
  region               = "eastus"
  instance             = "001"
  address_space        = ["10.10.0.0/23"]
  subnet_workload_cidr = "10.10.0.0/24"
  subnet_bastion_cidr  = "10.10.1.64/26"

  diagnostic_settings = {
    to_log_analytics = {
      name                  = "diag-setting"
      workspace_resource_id = module.log_analytics_monitoring_eastus.workspace_resource_id
    }
  }
}

module "vnet_spoke_application_eastus_001" {
  source = "../../modules/spoke-vnet"

  purpose              = "application"
  region               = "eastus"
  instance             = "001"
  address_space        = ["10.10.2.0/24"]
  subnet_workload_cidr = "10.10.2.0/25"

  hub_vnet_resource_id    = module.vnet_hub_eastus_001.vnet_resource_id
  hub_vnet_name           = module.vnet_hub_eastus_001.vnet_name
  hub_resource_group_name = module.vnet_hub_eastus_001.resource_group_name

  diagnostic_settings = {
    to_log_analytics = {
      name                  = "diag-setting"
      workspace_resource_id = module.log_analytics_monitoring_eastus.workspace_resource_id
    }
  }

  providers = {
    azurerm     = azurerm.subscription_application
    azurerm.hub = azurerm.subscription_hub
  }
}

module "vnet_spoke_avd_eastus_001" {
  source = "../../modules/spoke-vnet"

  purpose              = "avd"
  region               = "eastus"
  instance             = "001"
  address_space        = ["10.10.5.0/25"]
  subnet_workload_cidr = "10.10.5.0/26"

  hub_vnet_resource_id    = module.vnet_hub_eastus_001.vnet_resource_id
  hub_vnet_name           = module.vnet_hub_eastus_001.vnet_name
  hub_resource_group_name = module.vnet_hub_eastus_001.resource_group_name

  diagnostic_settings = {
    to_log_analytics = {
      name                  = "diag-setting"
      workspace_resource_id = module.log_analytics_monitoring_eastus.workspace_resource_id
    }
  }

  providers = {
    azurerm     = azurerm.subscription_application
    azurerm.hub = azurerm.subscription_hub
  }
}

# ============================================================
# Hub VNet — West Europe
# ============================================================

module "vnet_hub_westeurope_001" {
  source = "../../modules/hub-vnet"

  purpose              = "hub"
  region               = "westeurope"
  instance             = "001"
  address_space        = ["136.0.0.0/23"]
  subnet_workload_cidr = "136.0.0.0/24"

  diagnostic_settings = {
    to_log_analytics = {
      name                  = "diag-setting"
      workspace_resource_id = module.log_analytics_monitoring_westeurope.workspace_resource_id
    }
  }
}

module "vnet_spoke_application_westeurope_001" {
  source = "../../modules/spoke-vnet"

  purpose              = "application"
  region               = "westeurope"
  instance             = "001"
  address_space        = ["136.0.2.128/25"]
  subnet_workload_cidr = "136.0.2.0/24"

  hub_vnet_resource_id    = module.vnet_hub_westeurope_001.vnet_resource_id
  hub_vnet_name           = module.vnet_hub_westeurope_001.vnet_name
  hub_resource_group_name = module.vnet_hub_westeurope_001.resource_group_name

  diagnostic_settings = {
    to_log_analytics = {
      name                  = "diag-setting"
      workspace_resource_id = module.log_analytics_monitoring_westeurope.workspace_resource_id
    }
  }

  providers = {
    azurerm     = azurerm.subscription_application
    azurerm.hub = azurerm.subscription_hub
  }
}
