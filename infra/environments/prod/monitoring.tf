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

module "amba_eastus" {
  source                     = "../../modules/amba"
  region                     = "eastus"
  root_management_group_name = "7147592f-487e-44bf-b6e6-bbea6c888e35"
}
