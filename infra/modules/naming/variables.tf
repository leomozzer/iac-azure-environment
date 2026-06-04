variable "purpose" {
  type        = string
  description = "Workload descriptor, lowercase hyphen-separated (e.g., operations, networking)"
}

variable "region" {
  type        = string
  description = "Full Azure region name (e.g., eastus)"
}

variable "instance" {
  type        = string
  default     = "001"
  description = "Zero-padded 3-digit instance number (e.g., 001)"
}
