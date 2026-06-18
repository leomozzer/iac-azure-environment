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

variable "create_firewall_route" {
  type        = bool
  default     = false
  description = "When true, adds a default route (0.0.0.0/0 → VirtualAppliance) pointing at hub_firewall_private_ip. Must be set explicitly — cannot be inferred from hub_firewall_private_ip at plan time because the firewall IP is a computed value unknown until apply."
}

variable "create_nat_gateway" {
  type        = bool
  default     = false
  description = "When true, creates a NAT Gateway in the spoke and associates it with the workload subnet and any additional subnets with associate_nat_gateway = true. Mutually exclusive with create_firewall_route — a UDR to the hub firewall overrides NAT gateway egress."
}

variable "create_workload_nsg" {
  type        = bool
  default     = true
  description = "When false, no NSG is created or attached to the workload subnet."
}

variable "nsg_security_rules" {
  type = map(object({
    access                                     = string
    direction                                  = string
    name                                       = string
    priority                                   = number
    protocol                                   = string
    description                                = optional(string)
    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(set(string))
    destination_application_security_group_ids = optional(set(string))
    destination_port_range                     = optional(string)
    destination_port_ranges                    = optional(set(string))
    source_address_prefix                      = optional(string)
    source_address_prefixes                    = optional(set(string))
    source_application_security_group_ids      = optional(set(string))
    source_port_range                          = optional(string)
    source_port_ranges                         = optional(set(string))
  }))
  default     = {}
  description = "Security rules applied to the workload NSG. Map key is a Terraform-internal identifier. When create_nat_gateway = true and no rules are provided, Azure's default AllowInternetOutBound rule permits all outbound traffic — define explicit allow rules and a deny-internet catch-all to restrict egress."
}

variable "additional_subnets" {
  type = map(object({
    name                  = string
    cidr                  = string
    create_nsg            = optional(bool, false)
    create_route_table    = optional(bool, false)
    associate_nat_gateway = optional(bool, false)
  }))
  default     = {}
  description = "Additional subnets to create inside the spoke VNet. Map key is an internal Terraform reference (e.g. \"database\"). name is the Azure subnet name (follow project naming convention: snet-{purpose}-{region}-{instance}). cidr must fall within address_space. By default the shared spoke route table and workload NSG are attached. Set create_nsg = true to auto-create a dedicated NSG (named by replacing snet- with nsg- in the subnet name). Set create_route_table = true to auto-create a dedicated route table (named by replacing snet- with rt- in the subnet name)."
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
