variable "purpose" {
  type        = string
  description = "Workload descriptor, lowercase hyphen-separated (e.g., operations)"
  default     = "operations"
}

variable "region" {
  type        = string
  description = "Full Azure region name (e.g., eastus)"
  default     = "eastus"
}

variable "instance" {
  type        = string
  description = "Zero-padded 3-digit instance number"
  default     = "001"
}

variable "hub_subscription_id" {
  type        = string
  description = "Azure subscription ID for the hub VNet (Subscription A)"
}

variable "app_subscription_id" {
  type        = string
  description = "Azure subscription ID for the application spoke (Subscription B)"
}

variable "avd_subscription_id" {
  type        = string
  description = "Azure subscription ID for the AVD spoke (Subscription C)"
}

variable "enable_firewall" {
  type        = bool
  description = "Deploy Azure Firewall Standard in the hub. Set false to keep VNets only (no firewall cost)."
  default     = false
}

variable "root_management_group_name" {
  type        = string
  description = "Root management group name for the Azure landing zone"
}
