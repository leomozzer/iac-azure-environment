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

variable "management_subscription_id" {
  type        = string
  default     = ""
  description = "Subscription ID where AMBA resources are deployed. Defaults to the current subscription when empty."
}

variable "user_assigned_managed_identity_name" {
  type        = string
  default     = "id-amba-prod-001"
  description = "Name of the user-assigned managed identity created by AMBA for monitoring policy remediation."
}

variable "tags" {
  type        = map(string)
  default     = { _deployed_by_amba = "true" }
  description = "(Optional) Tags applied to all resources deployed by this module."
}

variable "action_group_email" {
  type        = list(string)
  default     = []
  description = "Email addresses for the AMBA action group alert notifications."
}

variable "amba_disable_tag_name" {
  type        = string
  default     = "MonitorDisable"
  description = "Tag name used to disable AMBA monitoring at the resource level."
}

variable "amba_disable_tag_values" {
  type        = list(string)
  default     = ["true", "Test", "Dev", "Sandbox"]
  description = "Tag values that disable AMBA monitoring when present on a resource."
}
