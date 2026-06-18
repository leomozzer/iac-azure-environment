output "vnet_resource_id" {
  description = "The resource ID of the spoke Virtual Network."
  value       = module.vnet.resource_id
}

output "vnet_name" {
  description = "The name of the spoke Virtual Network."
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
  description = "The name of the resource group that contains all spoke VNet resources."
  value       = module.resource_group.resource.name
}

output "resource_group_id" {
  description = "The resource ID of the resource group that contains all spoke VNet resources."
  value       = module.resource_group.resource.id
}

output "nsg_resource_id" {
  description = "The resource ID of the Network Security Group attached to the workload subnet. Null when create_workload_nsg = false."
  value       = var.create_workload_nsg ? module.nsg[0].resource_id : null
}

output "additional_subnet_ids" {
  description = "Map of resource IDs for additional subnets, keyed by the same keys as var.additional_subnets. Empty map when no additional subnets are defined."
  value       = { for k in keys(var.additional_subnets) : k => module.vnet.subnets[k].resource_id }
}

output "additional_nsg_ids" {
  description = "Map of NSG resource IDs for additional subnets where create_nsg = true. Keyed by the same keys as var.additional_subnets."
  value       = { for k, v in var.additional_subnets : k => module.additional_nsg[k].resource_id if v.create_nsg }
}

output "additional_route_table_ids" {
  description = "Map of dedicated route table resource IDs for additional subnets where create_route_table = true. Keyed by the same keys as var.additional_subnets."
  value       = { for k, v in var.additional_subnets : k => module.additional_route_table[k].resource_id if v.create_route_table }
}

output "nat_gateway_resource_id" {
  description = "The resource ID of the NAT Gateway created in the spoke. Null when create_nat_gateway = false."
  value       = var.create_nat_gateway ? module.nat_gateway[0].resource_id : null
}
