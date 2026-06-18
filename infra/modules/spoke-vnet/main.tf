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
  bastion_subnet_name = "AzureBastionSubnet"
}

# ============================================================
# Block 2 — Resource Group
# ============================================================

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"

  name     = local.resource_group_name
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

  security_rules      = var.nsg_security_rules
  diagnostic_settings = var.diagnostic_settings

  depends_on = [module.resource_group]
}

# ============================================================
# Block 3b — Dedicated NSGs for additional subnets (opt-in)
# ============================================================

module "additional_nsg" {
  for_each = { for k, v in var.additional_subnets : k => v if v.create_nsg }
  source   = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version  = "0.5.1"

  name                = replace(each.value.name, "/^snet-/", "nsg-")
  location            = var.region
  resource_group_name = module.resource_group.resource.name

  diagnostic_settings = var.diagnostic_settings

  depends_on = [module.resource_group]
}

# ============================================================
# Block 3c — Dedicated route tables for additional subnets (opt-in)
# ============================================================

module "additional_route_table" {
  for_each = { for k, v in var.additional_subnets : k => v if v.create_route_table }
  source   = "Azure/avm-res-network-routetable/azurerm"
  version  = "0.5.0"

  name                = replace(each.value.name, "/^snet-/", "rt-")
  location            = var.region
  resource_group_name = module.resource_group.resource.name

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
# Block 4b — NAT Gateway (conditional on create_nat_gateway)
# ============================================================

module "nat_gateway" {
  count   = var.create_nat_gateway ? 1 : 0
  source  = "Azure/avm-res-network-natgateway/azurerm"
  version = "0.3.2"

  name      = module.naming.nat_gateway
  location  = var.region
  parent_id = module.resource_group.resource.id

  sku_name = "Standard"

  public_ips = {
    pip1 = {
      name = "pip-ng-${module.naming.virtual_network}"
    }
  }

  public_ip_configuration = {
    pip1 = {
      sku   = "StandardV2"
      zones = [1, 2, 3]
    }
  }

  diagnostic_settings = var.diagnostic_settings

  depends_on = [module.resource_group]
}

resource "terraform_data" "nat_firewall_exclusive" {
  count = var.create_nat_gateway ? 1 : 0

  lifecycle {
    precondition {
      condition     = !var.create_firewall_route
      error_message = "create_nat_gateway and create_firewall_route are mutually exclusive. A UDR to the hub firewall overrides the NAT gateway for egress."
    }
  }
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
        nat_gateway = var.create_nat_gateway ? {
          id = module.nat_gateway[0].resource_id
        } : null
      }
    },
    var.subnet_bastion_cidr != null ? {
      bastion = {
        name             = local.bastion_subnet_name
        address_prefixes = [var.subnet_bastion_cidr]
      }
    } : {},
    { for k, v in var.additional_subnets : k => {
      name             = v.name
      address_prefixes = [v.cidr]
      network_security_group = v.create_nsg ? {
        id = module.additional_nsg[k].resource_id
        } : var.create_workload_nsg ? {
        id = module.nsg[0].resource_id
      } : null
      route_table = {
        id = v.create_route_table ? module.additional_route_table[k].resource_id : module.route_table.resource_id
      }
      nat_gateway = var.create_nat_gateway && v.associate_nat_gateway ? {
        id = module.nat_gateway[0].resource_id
      } : null
    } }
  )

  diagnostic_settings = var.diagnostic_settings
}

# ============================================================
# Block 6 — Default route to hub firewall (conditional)
# ============================================================

resource "azurerm_route" "default_to_firewall" {
  count                  = var.create_firewall_route ? 1 : 0
  name                   = "default-to-firewall"
  resource_group_name    = module.resource_group.resource.name
  route_table_name       = module.route_table.resource.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.hub_firewall_private_ip
}

# ============================================================
# Block 7 — VNet Peerings (bidirectional)
# ============================================================

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-${module.naming.virtual_network}-to-hub"
  resource_group_name       = module.resource_group.resource.name
  virtual_network_name      = module.vnet.name
  remote_virtual_network_id = var.hub_vnet_resource_id
  allow_forwarded_traffic   = true
  use_remote_gateways       = false

  depends_on = [module.vnet]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  provider = azurerm.hub

  name                      = "peer-hub-to-${module.naming.virtual_network}"
  resource_group_name       = var.hub_resource_group_name
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = module.vnet.resource_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false

  depends_on = [module.vnet]
}
