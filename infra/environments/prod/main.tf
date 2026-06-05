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
