output "vnet_resource_id" {
  description = "The resource ID of the hub Virtual Network."
  value       = module.vnet.resource_id
}

output "vnet_name" {
  description = "The name of the hub Virtual Network."
  value       = module.vnet.name
}

output "workload_subnet_id" {
  description = "The resource ID of the workload subnet."
  value       = module.vnet.subnets["workload"].resource_id
}

output "route_table_resource_id" {
  description = "The resource ID of the route table associated with the workload subnet."
  value       = module.route_table.resource_id
}

output "resource_group_name" {
  description = "The name of the resource group that contains all hub VNet resources."
  value       = module.resource_group.resource.name
}

output "resource_group_id" {
  description = "The resource ID of the resource group that contains all hub VNet resources."
  value       = module.resource_group.resource.id
}

output "firewall_private_ip" {
  description = "The private IP address of the Azure Firewall. Null when egress_type is not 'firewall'."
  value       = var.egress_type == "firewall" ? module.firewall_hub[0].resource.ip_configuration[0].private_ip_address : null
}

output "nsg_resource_id" {
  description = "The resource ID of the Network Security Group attached to the workload subnet. Null when create_workload_nsg = false."
  value       = var.create_workload_nsg ? module.nsg[0].resource_id : null
}
