output "resource_group" {
  value = "rg-${local.base}"
}

output "log_analytics_workspace" {
  value = "log-${local.base}"
}

output "virtual_network" {
  value = "vnet-${local.base}"
}

output "subnet" {
  value = "snet-${local.base}"
}

output "storage_account" {
  value = "st${replace(local.base, "-", "")}"
}

output "recovery_services_vault" {
  value = "rsv-${local.base}"
}

output "action_group" {
  value = "ag-${local.base}"
}

output "alert_rule" {
  value = "alr-${local.base}"
}

output "network_security_group" {
  value = "nsg-${local.base}"
}

output "vnet_peering" {
  value = "peer-${local.base}"
}

output "nat_gateway" {
  value = "ng-${local.base}"
}
