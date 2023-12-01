variable "subscription_id" {
  type = string
}

variable "location" {
  type        = string
  description = "Location of the resources"
}

variable "resource_group_name" {
  type = string
}

variable "vnet_name" {
  type = string
}

# variable "vnet_body" {
#   type = string
# }

variable "vnet_address_prefix" {
  type    = list(string)
  default = [""]
}

variable "subnets" {
  type = list(object({
    name         = string
    subnet_range = string
  }))
  default = []
}
