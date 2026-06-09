# Spoke Virtual Network Module

Provisions a spoke Virtual Network in Azure with a workload subnet, optional Network Security Group, route table, and optional bastion subnet. Establishes bidirectional peering with a hub Virtual Network and supports egress through a hub-based Azure Firewall via force-tunneled default routes.

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.9 |
| azurerm | >= 4.36.0 |
| azapi | ~> 2.4 |
| modtm | ~> 0.3 |

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| purpose | string | — | Yes | Workload descriptor passed to the naming module. Must be lowercase and hyphen-separated (e.g. 'application', 'avd'). |
| region | string | — | Yes | Azure region for all resources and passed to the naming module (e.g. 'eastus', 'westeurope'). |
| address_space | list(string) | — | Yes | One or more CIDR ranges for the spoke Virtual Network (e.g. ["10.20.0.0/24"]). |
| subnet_workload_cidr | string | — | Yes | CIDR block for the workload subnet. A route table is always attached; an NSG is attached only when create_workload_nsg = true. |
| hub_vnet_resource_id | string | — | Yes | Resource ID of the hub Virtual Network. Used as the remote_virtual_network_id in the spoke-to-hub peering. |
| hub_vnet_name | string | — | Yes | Name of the hub Virtual Network. Used in the hub-to-spoke peering resource (requires azurerm.hub provider). |
| hub_resource_group_name | string | — | Yes | Name of the hub resource group. Used in the hub-to-spoke peering resource (requires azurerm.hub provider). |
| instance | string | "001" | No | Zero-padded 3-digit instance identifier passed to the naming module. Defaults to '001'. |
| subnet_bastion_cidr | string | null | No | CIDR block for AzureBastionSubnet. When set, the bastion subnet is added to the VNet without an NSG or route table. |
| additional_subnets | `map(object({ name = string, cidr = string, create_nsg = optional(bool, true) }))` | `{}` | No | Additional subnets to create inside the spoke VNet. Key = internal Terraform ref. `name` = Azure subnet name (`snet-{purpose}-{region}-{instance}`). `cidr` must fall within `address_space`. Route table always attached. NSG auto-created and attached unless `create_nsg = false`; NSG name is derived by replacing `snet-` prefix with `nsg-` in the subnet name. |
| hub_firewall_private_ip | string | null | No | Private IP address of the hub Azure Firewall. When set, a default route (0.0.0.0/0 → VirtualAppliance) is added to the spoke route table to force-tunnel traffic through the firewall. |
| create_workload_nsg | bool | true | No | When false, no NSG is created or attached to the workload subnet. |
| diagnostic_settings | map(object) | {} | No | Diagnostic settings passed to NSG and VNet. Map keys must be statically known strings — do not use computed values as keys. Example key: "to_log_analytics". |

## Outputs

| Name | Description |
|------|-------------|
| vnet_resource_id | The resource ID of the spoke Virtual Network. |
| vnet_name | The name of the spoke Virtual Network. |
| workload_subnet_id | The resource ID of the workload subnet. |
| route_table_resource_id | The resource ID of the route table associated with the workload subnet. |
| resource_group_name | The name of the resource group that contains all spoke VNet resources. |
| resource_group_id | The resource ID of the resource group that contains all spoke VNet resources. |
| nsg_resource_id | The resource ID of the Network Security Group attached to the workload subnet. Null when create_workload_nsg = false. |
| additional_subnet_ids | Map of resource IDs for additional subnets, keyed by the same keys as `var.additional_subnets`. Empty map when no additional subnets are defined. |
| additional_nsg_ids | Map of NSG resource IDs for additional subnets where `create_nsg = true`. Keyed by the same keys as `var.additional_subnets`. |

## Resources Created

- **Resource Group**: Dedicated RG for all spoke VNet resources
- **Virtual Network**: Spoke VNet with address space
- **Workload Subnet**: Primary subnet with route table (and optional NSG)
- **Bastion Subnet** (optional): AzureBastionSubnet when subnet_bastion_cidr is provided
- **Network Security Group** (optional): Attached to workload subnet (can be disabled with create_workload_nsg = false)
- **Route Table**: Always attached to workload subnet; contains default firewall route when hub_firewall_private_ip is set
- **VNet Peerings**: Bidirectional peering between spoke and hub (spoke-to-hub and hub-to-spoke)
- **module.additional_nsg**: One NSG per additional subnet entry where `create_nsg = true`

## Usage

### Example 1: Basic spoke VNet with no NSG and no firewall integration

```hcl
module "spoke_vnet_basic" {
  source = "../../modules/spoke-vnet"

  purpose                = "application"
  region                 = "eastus"
  instance               = "001"
  address_space          = ["10.20.0.0/24"]
  subnet_workload_cidr   = "10.20.0.0/26"
  
  hub_vnet_resource_id        = module.hub_vnet.vnet_resource_id
  hub_vnet_name               = module.hub_vnet.vnet_name
  hub_resource_group_name     = module.hub_vnet.resource_group_name
  
  create_workload_nsg = false
}
```

### Example 2: Spoke VNet with NSG and firewall force-tunneling

```hcl
module "spoke_vnet_with_firewall" {
  source = "../../modules/spoke-vnet"

  purpose                = "application"
  region                 = "eastus"
  instance               = "001"
  address_space          = ["10.20.0.0/24"]
  subnet_workload_cidr   = "10.20.0.0/26"
  
  hub_vnet_resource_id        = module.hub_vnet.vnet_resource_id
  hub_vnet_name               = module.hub_vnet.vnet_name
  hub_resource_group_name     = module.hub_vnet.resource_group_name
  
  hub_firewall_private_ip = module.hub_vnet.firewall_private_ip
  create_workload_nsg     = true
  
  diagnostic_settings = {
    to_log_analytics = {
      workspace_resource_id = azurerm_log_analytics_workspace.hub.id
    }
  }
}
```

### Example 3: Spoke VNet with bastion subnet and firewall integration

```hcl
module "spoke_vnet_with_bastion" {
  source = "../../modules/spoke-vnet"

  purpose                = "application"
  region                 = "eastus"
  instance               = "001"
  address_space          = ["10.20.0.0/23"]
  subnet_workload_cidr   = "10.20.1.0/26"
  subnet_bastion_cidr    = "10.20.0.0/27"
  
  hub_vnet_resource_id        = module.hub_vnet.vnet_resource_id
  hub_vnet_name               = module.hub_vnet.vnet_name
  hub_resource_group_name     = module.hub_vnet.resource_group_name
  
  hub_firewall_private_ip = module.hub_vnet.firewall_private_ip
  create_workload_nsg     = true
  
  diagnostic_settings = {
    to_log_analytics = {
      workspace_resource_id = azurerm_log_analytics_workspace.hub.id
    }
  }
}
```

### Example 4: Spoke VNet with additional subnets and NSG control

```hcl
module "vnet_spoke_application_eastus_001" {
  source = "../../modules/spoke-vnet"

  purpose              = "application"
  region               = "eastus"
  instance             = "001"
  address_space        = ["10.20.0.0/24"]
  subnet_workload_cidr = "10.20.0.0/25"

  additional_subnets = {
    database = {
      name = "snet-database-eus-001"
      cidr = "10.20.0.128/26"
      # create_nsg defaults to true — NSG named nsg-database-eus-001 is auto-created
    }
    management = {
      name       = "snet-management-eus-001"
      cidr       = "10.20.0.192/27"
      create_nsg = false
    }
  }

  hub_vnet_resource_id    = module.vnet_hub_eastus_001.vnet_resource_id
  hub_vnet_name           = module.vnet_hub_eastus_001.vnet_name
  hub_resource_group_name = module.vnet_hub_eastus_001.resource_group_name

  providers = {
    azurerm     = azurerm.subscription_application
    azurerm.hub = azurerm.subscription_hub
  }
}

# Access additional subnet IDs
output "db_subnet_id" {
  value = module.vnet_spoke_application_eastus_001.additional_subnet_ids["database"]
}
```

## Notes

- **Naming**: All resource names are derived from the naming module using `purpose`, `region`, and `instance` parameters. Resource naming follows Azure Virtual Machine (AVM) conventions.
- **Provider Alias**: The hub-to-spoke peering uses the `azurerm.hub` provider alias to establish peering from the hub resource group. Ensure this alias is configured in your root Terraform configuration.
- **Route Table**: The workload subnet always has a route table. When `hub_firewall_private_ip` is provided, a default route (0.0.0.0/0) is automatically added to force traffic through the hub firewall.
- **NSG Attachment**: The workload NSG is only created and attached when `create_workload_nsg = true`. The bastion subnet never receives an NSG.
- **Diagnostic Settings**: Diagnostic settings can be configured for both the VNet and NSG. Use statically known map keys (not computed values).
