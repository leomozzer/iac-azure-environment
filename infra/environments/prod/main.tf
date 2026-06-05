module "operationalinsights" {
  source   = "../../modules/naming"
  purpose  = "monitoring"
  region   = var.region
  instance = var.instance
}

module "avm-res-operationalinsights-workspace" {
  source              = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version             = "0.5.1"
  resource_group_name = module.operationalinsights.resource_group
  location            = var.region
  name                = module.operationalinsights.log_analytics_workspace
}
