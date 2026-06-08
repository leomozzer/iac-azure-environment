output "workspace_resource_id" {
  description = "The resource ID of the Log Analytics Workspace."
  value       = module.log_analytics_workspace.resource_id
}

output "workspace_name" {
  description = "The name of the Log Analytics Workspace."
  sensitive   = true
  value       = module.log_analytics_workspace.resource.name
}

output "resource_group_name" {
  description = "The name of the resource group containing the Log Analytics Workspace."
  value       = module.resource_group.resource.name
}

output "resource_group_id" {
  description = "The resource ID of the resource group containing the Log Analytics Workspace."
  value       = module.resource_group.resource.id
}
