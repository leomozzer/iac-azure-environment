module "naming" {
  source   = "../naming"
  purpose  = "amba"
  region   = var.region
  instance = var.instance
}

module "avm_ptn_monitoring_amba_alz" {
  source  = "Azure/avm-ptn-monitoring-amba-alz/azurerm"
  version = "0.3.0"

  location                   = var.region
  root_management_group_name = var.root_management_group_name
  resource_group_name        = module.naming.resource_group

  timeouts = {
    create = "30m"
    update = "30m"
  }
}
