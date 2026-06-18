module "naming" {
  source   = "../naming"
  purpose  = var.purpose
  region   = var.region
  instance = var.instance
}

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"

  name     = local.resource_group_name
  location = var.region
}

module "log_analytics_workspace" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                                      = module.naming.log_analytics_workspace
  resource_group_name                       = module.resource_group.resource.name
  location                                  = var.region
  log_analytics_workspace_sku               = var.sku
  log_analytics_workspace_retention_in_days = var.retention_in_days
}
