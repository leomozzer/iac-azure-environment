variable "purpose" {
  type        = string
  description = "Workload descriptor, lowercase hyphen-separated (e.g., operations, monitoring). Passed to the naming module."
}

variable "region" {
  type        = string
  description = "Full Azure region name (e.g., eastus). Used for both the naming module and the resource location."
}

variable "instance" {
  type        = string
  default     = "001"
  description = "Zero-padded 3-digit instance number (e.g., 001). Passed to the naming module."
}

variable "sku" {
  type        = string
  default     = "PerGB2018"
  description = "SKU of the Log Analytics Workspace. Valid values: Free, PerNode, Premium, Standard, Standalone, Unlimited, CapacityReservation, PerGB2018."
}

variable "retention_in_days" {
  type        = number
  default     = 30
  description = "Workspace data retention in days. Either 7 (Free tier only) or a value between 30 and 730."
}
