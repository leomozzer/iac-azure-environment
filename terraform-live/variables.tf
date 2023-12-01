variable "management_group" {
  type = string
}

variable "management_subscription_id" {
  type        = string
  description = "Subscription if where general resources like log analytics, key vaults will be deployed"
}
variable "principal_location" {
  type        = string
  description = "Location were most of the commom resources will be deployed"
  default     = "eastus"
}

variable "environment_name" {
  type        = string
  description = "Name of the customer short, must have 3 letters at maximum"
}

variable "management_monitoring_email" {
  type    = string
  default = "Email that will receive notifications regarding monitoring"
}

variable "default_vnet_hub_definition" {
  type = object({
    subscription_id = string
    hubs = optional(list(object({
      address_space = list(string)
      location      = string,
      subnets = optional(list(object({
        name           = string
        address_prefix = string
      })))
    })), [])
  })
  default = {
    "subscription_id" = "",
    "hubs" = [
      {
        "address_space" = [],
        "location"      = "",
        "subnets"       = []
      }
    ]
  }
}

variable "default_vnet_spoke_definition" {
  type = list(object({
    subscription_id = string
    identifier      = optional(string)
    spokes = optional(list(object({
      location      = string
      address_space = list(string)
      subnets = optional(list(object({
        address_prefix = string
      })))
    })))
  }))
  default = [{
    subscription_id = "",
    identifier      = "",
    spokes = [{
      location      = "",
      address_space = [],
      subnets       = []
    }]
  }]
}
