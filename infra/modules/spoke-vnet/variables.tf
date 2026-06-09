# ============================================================
# Required variables
# ============================================================

variable "purpose" {
  type        = string
  description = "Workload descriptor passed to the naming module. Must be lowercase and hyphen-separated (e.g. 'application', 'avd')."
}

variable "region" {
  type        = string
  description = "Azure region for all resources and passed to the naming module (e.g. 'eastus', 'westeurope')."
}

variable "address_space" {
  type        = list(string)
  description = "One or more CIDR ranges for the spoke Virtual Network (e.g. [\"10.20.0.0/24\"])."
}

variable "subnet_workload_cidr" {
  type        = string
  description = "CIDR block for the workload subnet. A route table is always attached; an NSG is attached only when create_workload_nsg = true."
}

variable "hub_vnet_resource_id" {
  type        = string
  description = "Resource ID of the hub Virtual Network. Used as the remote_virtual_network_id in the spoke-to-hub peering."
}

variable "hub_vnet_name" {
  type        = string
  description = "Name of the hub Virtual Network. Used in the hub-to-spoke peering resource (requires azurerm.hub provider)."
}

variable "hub_resource_group_name" {
  type        = string
  description = "Name of the hub resource group. Used in the hub-to-spoke peering resource (requires azurerm.hub provider)."
}

# ============================================================
# Optional variables with defaults
# ============================================================

variable "instance" {
  type        = string
  default     = "001"
  description = "Zero-padded 3-digit instance identifier passed to the naming module. Defaults to '001'."
}

variable "subnet_bastion_cidr" {
  type        = string
  default     = null
  description = "CIDR block for AzureBastionSubnet. When set, the bastion subnet is added to the VNet without an NSG or route table."
}

variable "hub_firewall_private_ip" {
  type        = string
  default     = null
  description = "Private IP address of the hub Azure Firewall. When set, a default route (0.0.0.0/0 → VirtualAppliance) is added to the spoke route table to force-tunnel traffic through the firewall."
}

variable "create_workload_nsg" {
  type        = bool
  default     = true
  description = "When false, no NSG is created or attached to the workload subnet."
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = "Diagnostic settings passed to NSG and VNet. Map keys must be statically known strings — do not use computed values as keys. Example key: \"to_log_analytics\"."
}
