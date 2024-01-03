management_group            = "<managment group id>"
management_subscription_id  = "<management subscription id>"
management_monitoring_email = "<favourite email>"
environment_name            = "con"

default_vnet_hub_definition = {
  subscription_id = "<subscription id>"
  hubs = [{
    address_space = ["10.0.0.0/20"] #change if needed
    location      = "eastus"        #change if needed
    subnets = [{
      address_prefix = "10.0.0.0/24" #change if needed
    }]
  }]
}

default_vnet_spoke_definition = [
  {
    identifier = "application" #change if needed
    spokes = [
      {
        address_space = ["10.0.16.0/20"] #change if needed
        location      = "eastus"         #change if needed
        subnets = [{
          address_prefix = "10.0.16.0/24" #change if needed
        }]
      },
      {
        address_space = ["192.168.0.0/20"] #change if needed
        location      = "west europe"      #change if needed
        subnets = [{
          address_prefix = "192.168.1.0/24" #change if needed
        }]
      }
    ]
    subscription_id = "<subscription id>"
  },
  {
    identifier = "identity" #change if needed
    spokes = [{
      address_space = ["10.1.0.0/16"] #change if needed
      location      = "west europe"   #change if needed
      subnets = [{
        address_prefix = "10.1.0.0/24" #change if needed
      }]
    }]
    subscription_id = "<subscription id>"
  }
]
