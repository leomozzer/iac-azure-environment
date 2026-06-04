variable "purpose" {
  type        = string
  description = "Workload descriptor, lowercase hyphen-separated (e.g., operations, networking)"

  validation {
    condition     = length(replace(var.purpose, "-", "")) <= 16
    error_message = "purpose '${var.purpose}' is too long. After stripping hyphens, must be <= 16 chars to keep storage account name within Azure's 24-char limit."
  }
}

variable "region" {
  type        = string
  description = "Full Azure region name (e.g., eastus)"

  validation {
    condition     = contains(["eastus", "westeurope"], var.region)
    error_message = "Region '${var.region}' is not supported. Add it to the region_short map in locals.tf first."
  }
}

variable "instance" {
  type        = string
  default     = "001"
  description = "Zero-padded 3-digit instance number (e.g., 001)"

  validation {
    condition     = can(regex("^\\d{3}$", var.instance))
    error_message = "instance must be exactly 3 digits (e.g., 001, 002, 010)."
  }
}
