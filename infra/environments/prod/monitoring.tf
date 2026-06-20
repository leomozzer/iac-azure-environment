# Create Log Analytics workspaces for monitoring in different regions

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

module "avm-ptn-monitoring-amba-alz" {
  source  = "Azure/avm-ptn-monitoring-amba-alz/azurerm"
  version = "0.3.0"

  location = "eastus"

  root_management_group_name = "Landing-Zone"

  # insert the 2 required variables here
}
