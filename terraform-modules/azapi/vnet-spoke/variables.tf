variable "subscription_id" {
  type = string
}

variable "location" {
  type        = string
  description = "Location of the resources"
}

variable "spoke_resource_group_name" {
  type = string
}

variable "spoke_vnet_name" {
  type = string
}

variable "vnet_body" {
  type = string
}

variable "default_subnet_name" {
  type = string
}

variable "default_subnet_body" {
  type = string
}

variable "hubs" {

}

variable "peerings" {

}
