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
