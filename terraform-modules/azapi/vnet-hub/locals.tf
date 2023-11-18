locals {
  subnets = flatten([
    for value, key in var.subnets : {
      subnet_name           = value
      subnet_address_prefix = key["subnet_address_prefix"]
    }
  ])
}
