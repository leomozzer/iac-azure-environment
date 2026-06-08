# ============================================================
# Required variables
# ============================================================

variable "purpose" {
  type        = string
  description = "Workload descriptor passed to the naming module. Must be lowercase and hyphen-separated (e.g. 'hub', 'networking')."
}

variable "region" {
  type        = string
  description = "Azure region for all resources and passed to the naming module (e.g. 'eastus', 'westeurope')."
}

variable "address_space" {
  type        = list(string)
  description = "One or more CIDR ranges for the hub Virtual Network (e.g. [\"10.10.0.0/23\"])."
}

variable "subnet_workload_cidr" {
  type        = string
  description = "CIDR block for the workload subnet. A route table is always attached; an NSG is attached only when create_workload_nsg = true."
}

# ============================================================
# Optional variables with defaults
# ============================================================

variable "instance" {
  type        = string
  default     = "001"
  description = "Zero-padded 3-digit instance identifier passed to the naming module. Defaults to '001'."
}

variable "subnet_firewall_cidr" {
  type        = string
  default     = null
  description = "CIDR block for AzureFirewallSubnet. Required when egress_type = \"firewall\". Ignored otherwise."
}

variable "subnet_bastion_cidr" {
  type        = string
  default     = null
  description = "CIDR block for AzureBastionSubnet. When set, the bastion subnet is added to the VNet without an NSG or route table."
}

variable "egress_type" {
  type        = string
  default     = "none"
  description = "Egress strategy for workloads. Allowed values: 'none', 'firewall', 'nat_gateway'."

  validation {
    condition     = contains(["none", "firewall", "nat_gateway"], var.egress_type)
    error_message = "egress_type must be one of: 'none', 'firewall', 'nat_gateway'."
  }
}

variable "firewall_policy_sku" {
  type        = string
  default     = "Standard"
  description = "SKU tier for the Azure Firewall Policy (and the firewall itself). Allowed values: 'Standard', 'Premium'. Only used when egress_type = \"firewall\"."

  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_policy_sku)
    error_message = "firewall_policy_sku must be either 'Standard' or 'Premium'."
  }
}

variable "firewall_policy_rule_collection_groups" {
  type = map(object({
    priority = number
    network_rule_collection = optional(list(object({
      action   = string
      name     = string
      priority = number
      rule = list(object({
        description           = optional(string)
        destination_addresses = optional(list(string), [])
        destination_fqdns     = optional(list(string), [])
        destination_ip_groups = optional(list(string), [])
        destination_ports     = list(string)
        name                  = string
        protocols             = list(string)
        source_addresses      = optional(list(string), [])
        source_ip_groups      = optional(list(string), [])
      }))
    })))
    application_rule_collection = optional(list(object({
      action   = string
      name     = string
      priority = number
      rule = list(object({
        description           = optional(string)
        destination_addresses = optional(list(string), [])
        destination_fqdn_tags = optional(list(string), [])
        destination_fqdns     = optional(list(string), [])
        destination_urls      = optional(list(string), [])
        name                  = string
        source_addresses      = optional(list(string), [])
        source_ip_groups      = optional(list(string), [])
        terminate_tls         = optional(bool)
        web_categories        = optional(list(string), [])
        protocols = optional(list(object({
          port = number
          type = string
        })))
      }))
    })))
    nat_rule_collection = optional(list(object({
      action   = string
      name     = string
      priority = number
      rule = list(object({
        description         = optional(string)
        destination_address = optional(string)
        destination_ports   = optional(list(string), [])
        name                = string
        protocols           = list(string)
        source_addresses    = optional(list(string), [])
        source_ip_groups    = optional(list(string), [])
        translated_address  = optional(string)
        translated_fqdn     = optional(string)
        translated_port     = number
      }))
    })))
  }))
  default     = {}
  description = "Map of firewall policy rule collection groups. Keys are group names. Only used when egress_type = \"firewall\"."
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Resource ID of a Log Analytics Workspace. When set, diagnostic settings are configured on all resources that support them (VNet, NSG, Azure Firewall, Firewall Policy)."
}

variable "create_workload_nsg" {
  type        = bool
  default     = true
  description = "When false, no NSG is created or attached to the workload subnet. Safe to set false when egress_type = \"firewall\" and all inbound access is via Bastion or the firewall."

  validation {
    condition     = var.create_workload_nsg || var.egress_type == "firewall"
    error_message = "create_workload_nsg can only be false when egress_type = \"firewall\". Setting it false with egress_type = \"none\" or \"nat_gateway\" leaves the workload subnet with no layer-4 inspection."
  }
}
