variable "region" {
  type        = string
  description = "Full Azure region name (e.g., eastus). Used for both the naming module and the resource location."
}

variable "instance" {
  type        = string
  default     = "001"
  description = "Zero-padded 3-digit instance number (e.g., 001). Passed to the naming module."
}

variable "root_management_group_name" {
  type        = string
  description = "The name (ID) of the root management group for AMBA ALZ policy assignments."
}
