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
      workspace_resource_id = module.log_analytics_monitoring_eastus.workspace_resource_id
    }
  }
}
