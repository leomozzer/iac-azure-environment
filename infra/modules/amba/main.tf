module "naming" {
  source   = "../naming"
  purpose  = "amba"
  region   = var.region
  instance = var.instance
}

module "avm-res-resources-resourcegroup" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name     = module.naming.resource_group
  location = var.region
}

module "avm_ptn_monitoring_amba_alz" {
  source  = "Azure/avm-ptn-monitoring-amba-alz/azurerm"
  version = "0.3.0"

  location                   = var.region
  root_management_group_name = var.root_management_group_name
}
