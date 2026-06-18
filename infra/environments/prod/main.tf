module "log_analytics_monitoring_eastus" {
  source   = "../../modules/log-analytics-workspace"
  purpose  = "monitoring"
  region   = "eastus"
  instance = "001"
}

module "log_analytics_monitoring_westeurope" {
  source   = "../../modules/log-analytics-workspace"
  purpose  = "monitoring"
  region   = "westeurope"
  instance = "001"
}

# ============================================================
# Hub VNet — East US
# ============================================================

module "vnet_hub_eastus_001" {
  source = "../../modules/hub-vnet"

  purpose              = "hub"
  region               = "eastus"
  instance             = "001"
  address_space        = ["10.10.0.0/23"]
  subnet_workload_cidr = "10.10.0.0/24"
  subnet_bastion_cidr  = "10.10.1.64/26"

  # Firewall Settings #
  # To use it, uncomment the this section

  # subnet_firewall_cidr = "10.10.1.0/26"

  # egress_type = "firewall"
  # spoke_address_spaces = {
  #   "snet-application-eus-001" = "10.10.2.0/24"
  #   "snet-avd-eus-001"         = "10.10.5.0/25"
  # }
  # firewall_policy_sku = "Standard"

  # firewall_policy_rule_collection_groups = {
  #   base_rules = {
  #     priority = 100
  #     network_rule_collection = [
  #       {
  #         name     = "allow-infrastructure"
  #         priority = 100
  #         action   = "Allow"
  #         rule = [
  #           {
  #             name                  = "allow-dns-azure"
  #             protocols             = ["UDP"]
  #             source_addresses      = ["10.10.5.0/26"]
  #             destination_addresses = ["168.63.129.16"]
  #             destination_ports     = ["53"]
  #           },
  #           {
  #             name                  = "allow-dns-public"
  #             protocols             = ["UDP"]
  #             source_addresses      = ["10.10.5.0/26"]
  #             destination_addresses = ["8.8.8.8", "8.8.4.4"]
  #             destination_ports     = ["53"]
  #           },
  #           {
  #             name                  = "allow-ntp"
  #             protocols             = ["UDP"]
  #             source_addresses      = ["10.10.5.0/26"]
  #             destination_addresses = ["*"]
  #             destination_ports     = ["123"]
  #           },
  #           {
  #             name              = "allow-kms"
  #             protocols         = ["TCP"]
  #             source_addresses  = ["10.10.5.0/26"]
  #             destination_fqdns = ["kms.core.windows.net", "azkms.core.windows.net"]
  #             destination_ports = ["1688"]
  #           },
  #         ]
  #       },
  #     ]
  #     application_rule_collection = [
  #       {
  #         name     = "allow-avd-required"
  #         priority = 200
  #         action   = "Allow"
  #         rule = [
  #           {
  #             name                  = "avd-control-plane"
  #             source_addresses      = ["10.10.5.0/26"]
  #             destination_fqdn_tags = ["WindowsVirtualDesktop"]
  #             protocols = [
  #               { port = 443, type = "Https" },
  #             ]
  #           },
  #           {
  #             name                  = "windows-update"
  #             source_addresses      = ["10.10.5.0/26"]
  #             destination_fqdn_tags = ["WindowsUpdate"]
  #             protocols = [
  #               { port = 443, type = "Https" },
  #               { port = 80, type = "Http" },
  #             ]
  #           },
  #           {
  #             name              = "avd-internet-https"
  #             source_addresses  = ["10.10.5.0/26"]
  #             destination_fqdns = ["*"]
  #             protocols = [
  #               { port = 443, type = "Https" },
  #             ]
  #           },
  #           {
  #             name              = "avd-internet-http"
  #             source_addresses  = ["10.10.5.0/26"]
  #             destination_fqdns = ["*"]
  #             protocols = [
  #               { port = 80, type = "Http" },
  #             ]
  #           },
  #         ]
  #       },
  #     ]
  #   }
  # }

  diagnostic_settings = {
    to_log_analytics = {
      name                  = "diag-setting"
      workspace_resource_id = module.log_analytics_monitoring_eastus.workspace_resource_id
    }
  }
}

module "vnet_spoke_application_eastus_001" {
  source = "../../modules/spoke-vnet"

  purpose              = "application"
  region               = "eastus"
  instance             = "001"
  address_space        = ["10.10.2.0/24"]
  subnet_workload_cidr = "10.10.2.0/25"

  hub_vnet_resource_id    = module.vnet_hub_eastus_001.vnet_resource_id
  hub_vnet_name           = module.vnet_hub_eastus_001.vnet_name
  hub_resource_group_name = module.vnet_hub_eastus_001.resource_group_name
  # Use this to add the firewall private IP to the spoke for routing purposes. Ensure that the firewall has a network rule allowing the necessary traffic from the spoke.
  # hub_firewall_private_ip = module.vnet_hub_eastus_001.firewall_private_ip
  # create_firewall_route   = true

  additional_subnets = {
    database = {
      name = "snet-database-001"
      cidr = "10.10.2.128/28"
    }
    isolated = {
      name               = "snet-isolated-001"
      cidr               = "10.10.2.144/28"
      create_nsg         = true
      create_route_table = true
    }
  }
  diagnostic_settings = {
    to_log_analytics = {
      name                  = "diag-setting"
      workspace_resource_id = module.log_analytics_monitoring_eastus.workspace_resource_id
    }
  }

  providers = {
    azurerm     = azurerm.subscription_application
    azurerm.hub = azurerm.subscription_hub
  }
}

module "vnet_spoke_avd_eastus_001" {
  source = "../../modules/spoke-vnet"

  purpose              = "avd"
  region               = "eastus"
  instance             = "001"
  address_space        = ["10.10.5.0/25"]
  subnet_workload_cidr = "10.10.5.0/26"

  hub_vnet_resource_id    = module.vnet_hub_eastus_001.vnet_resource_id
  hub_vnet_name           = module.vnet_hub_eastus_001.vnet_name
  hub_resource_group_name = module.vnet_hub_eastus_001.resource_group_name
  # Use this to add the firewall private IP to the spoke for routing purposes. Ensure that the firewall has a network rule allowing the necessary traffic from the spoke.
  # hub_firewall_private_ip = module.vnet_hub_eastus_001.firewall_private_ip
  # create_firewall_route   = true

  diagnostic_settings = {
    to_log_analytics = {
      name                  = "diag-setting"
      workspace_resource_id = module.log_analytics_monitoring_eastus.workspace_resource_id
    }
  }

  providers = {
    azurerm     = azurerm.subscription_application
    azurerm.hub = azurerm.subscription_hub
  }
}

# ============================================================
# Hub VNet — West Europe
# ============================================================

module "vnet_hub_westeurope_001" {
  source = "../../modules/hub-vnet"

  purpose              = "hub"
  region               = "westeurope"
  instance             = "001"
  address_space        = ["136.0.0.0/23"]
  subnet_workload_cidr = "136.0.0.0/24"

  diagnostic_settings = {
    to_log_analytics = {
      name                  = "diag-setting"
      workspace_resource_id = module.log_analytics_monitoring_westeurope.workspace_resource_id
    }
  }
}

module "vnet_spoke_application_westeurope_001" {
  source = "../../modules/spoke-vnet"

  purpose              = "application"
  region               = "westeurope"
  instance             = "001"
  address_space        = ["136.0.2.128/25"]
  subnet_workload_cidr = "136.0.2.128/26"

  hub_vnet_resource_id    = module.vnet_hub_westeurope_001.vnet_resource_id
  hub_vnet_name           = module.vnet_hub_westeurope_001.vnet_name
  hub_resource_group_name = module.vnet_hub_westeurope_001.resource_group_name

  # When using NAT Gateway and NSG to reach internet

  create_nat_gateway = true
  nsg_security_rules = {
    allow_https_out = {
      name                       = "Allow-HTTPS-Outbound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "Internet"
    }
    deny_internet_out = {
      name                       = "Deny-Internet-Outbound"
      priority                   = 4000
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    }
  }

  additional_subnets = {
    sap = {
      name                  = "snet-sap-001"
      cidr                  = "136.0.2.192/27"
      associate_nat_gateway = true
    }
  }

  diagnostic_settings = {
    to_log_analytics = {
      name                  = "diag-setting"
      workspace_resource_id = module.log_analytics_monitoring_westeurope.workspace_resource_id
    }
  }

  providers = {
    azurerm     = azurerm.subscription_application
    azurerm.hub = azurerm.subscription_hub
  }
}
