# ============================================================
# Block 1 — Naming
# ============================================================

module "naming" {
  source   = "../naming"
  purpose  = var.purpose
  region   = var.region
  instance = var.instance
}

locals {
  firewall_subnet_name = "AzureFirewallSubnet"
  bastion_subnet_name  = "AzureBastionSubnet"
}

# ============================================================
# Block 2 — Resource Group
# ============================================================

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"

  name     = module.naming.resource_group
  location = var.region
}

# ============================================================
# Block 3 — Network Security Group
# ============================================================

module "nsg" {
  count   = var.create_workload_nsg ? 1 : 0
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  name                = module.naming.network_security_group
  location            = var.region
  resource_group_name = module.resource_group.resource.name

  diagnostic_settings = var.diagnostic_settings

  depends_on = [module.resource_group]
}

# ============================================================
# Block 4 — Route Table
# ============================================================

module "route_table" {
  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "0.5.0"

  name                = module.naming.route_table
  location            = var.region
  resource_group_name = module.resource_group.resource.name

  depends_on = [module.resource_group]
}

# ============================================================
# Block 5 — Virtual Network
# ============================================================

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  name          = module.naming.virtual_network
  location      = var.region
  parent_id     = module.resource_group.resource.id
  address_space = var.address_space

  subnets = merge(
    {
      workload = {
        name             = module.naming.subnet
        address_prefixes = [var.subnet_workload_cidr]
        network_security_group = var.create_workload_nsg ? {
          id = module.nsg[0].resource_id
        } : null
        route_table = {
          id = module.route_table.resource_id
        }
      }
    },
    var.egress_type == "firewall" && var.subnet_firewall_cidr != null ? {
      firewall = {
        name             = local.firewall_subnet_name
        address_prefixes = [var.subnet_firewall_cidr]
      }
    } : {},
    var.subnet_bastion_cidr != null ? {
      bastion = {
        name             = local.bastion_subnet_name
        address_prefixes = [var.subnet_bastion_cidr]
      }
    } : {}
  )

  diagnostic_settings = var.diagnostic_settings
}

# ============================================================
# Block 6 — Firewall resources (conditional on egress_type == "firewall")
# ============================================================

module "pip_firewall" {
  count   = var.egress_type == "firewall" ? 1 : 0
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.2.1"

  name                = "pip-${module.naming.azure_firewall}"
  resource_group_name = module.resource_group.resource.name
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = []
}

module "firewall_policy" {
  count   = var.egress_type == "firewall" ? 1 : 0
  source  = "Azure/avm-res-network-firewallpolicy/azurerm"
  version = "0.3.4"

  name                = module.naming.firewall_policy
  resource_group_name = module.resource_group.resource.name
  location            = var.region
  firewall_policy_sku = var.firewall_policy_sku

  firewall_policy_dns = {
    proxy_enabled = true
  }

  firewall_policy_insights = var.log_analytics_workspace_id != null ? {
    enabled                            = true
    default_log_analytics_workspace_id = var.log_analytics_workspace_id
    retention_in_days                  = 90
  } : null
}

module "firewall_hub" {
  count   = var.egress_type == "firewall" ? 1 : 0
  source  = "Azure/avm-res-network-azurefirewall/azurerm"
  version = "0.4.0"

  name                = module.naming.azure_firewall
  resource_group_name = module.resource_group.resource.name
  location            = var.region
  firewall_sku_name   = "AZFW_VNet"
  firewall_sku_tier   = var.firewall_policy_sku
  firewall_policy_id  = module.firewall_policy[0].resource_id
  firewall_zones      = []

  ip_configurations = {
    ipconfig = {
      name                 = "ipconfig-${module.naming.azure_firewall}"
      subnet_id            = module.vnet.subnets["firewall"].resource_id
      public_ip_address_id = module.pip_firewall[0].resource_id
    }
  }

  diagnostic_settings = var.diagnostic_settings
}

module "rule_collection_groups" {
  for_each = var.egress_type == "firewall" ? var.firewall_policy_rule_collection_groups : {}
  source   = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  version  = "0.3.4"

  firewall_policy_rule_collection_group_firewall_policy_id = module.firewall_policy[0].resource_id
  firewall_policy_rule_collection_group_name               = each.key
  firewall_policy_rule_collection_group_priority           = each.value.priority
  firewall_policy_rule_collection_group_network_rule_collection     = each.value.network_rule_collection
  firewall_policy_rule_collection_group_application_rule_collection = each.value.application_rule_collection
  firewall_policy_rule_collection_group_nat_rule_collection         = each.value.nat_rule_collection
}

# ============================================================
# Block 7 — NAT Gateway (conditional on egress_type == "nat_gateway")
# ============================================================

module "nat_gateway" {
  count   = var.egress_type == "nat_gateway" ? 1 : 0
  source  = "Azure/avm-res-network-natgateway/azurerm"
  version = "0.3.2"

  name      = module.naming.nat_gateway
  location  = var.region
  parent_id = module.resource_group.resource.id

  public_ip_configuration = {
    pip1 = {
      name = "pip-ng-${module.naming.virtual_network}"
    }
  }

  diagnostic_settings = var.diagnostic_settings
}

resource "azurerm_subnet_nat_gateway_association" "workload" {
  count          = var.egress_type == "nat_gateway" ? 1 : 0
  subnet_id      = module.vnet.subnets["workload"].resource_id
  nat_gateway_id = module.nat_gateway[0].resource_id
}

# ============================================================
# Block 8 — Default route to firewall (conditional on egress_type == "firewall")
# ============================================================

resource "azurerm_route" "default_to_firewall" {
  count                  = var.egress_type == "firewall" ? 1 : 0
  name                   = "default-to-firewall"
  resource_group_name    = module.resource_group.resource.name
  route_table_name       = module.route_table.resource.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.firewall_hub[0].resource.ip_configuration[0].private_ip_address
}
