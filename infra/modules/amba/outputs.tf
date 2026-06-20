output "resource_group_name" {
  description = "The name of the resource group containing the AMBA resources."
  value       = module.avm-res-resources-resourcegroup.resource.name
}

output "resource_group_id" {
  description = "The resource ID of the resource group containing the AMBA resources."
  value       = module.avm-res-resources-resourcegroup.resource.id
}
