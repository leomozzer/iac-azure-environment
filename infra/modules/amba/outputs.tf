output "resource_group_name" {
  description = "The name of the resource group containing the AMBA resources."
  value       = module.naming.resource_group
}

output "user_assigned_managed_identity_id" {
  description = "The resource ID of the user-assigned managed identity created by AMBA."
  value       = module.amba_alz.resource_id
}
