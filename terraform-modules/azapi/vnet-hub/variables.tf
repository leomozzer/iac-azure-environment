variable "subscription_id" {
  type = string
}

variable "location" {
  type        = string
  description = "Location of the resources"
}

variable "hub_resource_group_name" {
  type = string
}

variable "hub_vnet_name" {
  type = string
}

variable "vnet_body" {
  type = string
}

variable "subnets" {
  type = any
}
