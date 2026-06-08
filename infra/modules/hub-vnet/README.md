# Hub Virtual Network Module

Provisions a hub Virtual Network in Azure with a workload subnet, Network Security Group, route table, and optional egress infrastructure (Azure Firewall or NAT Gateway).

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
| purpose | string | — | Yes | Workload descriptor passed to the naming module. Must be lowercase and hyphen-separated (e.g. 'hub', 'networking'). |
| region | string | — | Yes | Azure region for all resources and passed to the naming module (e.g. 'eastus', 'westeurope'). |
| address_space | list(string) | — | Yes | One or more CIDR ranges for the hub Virtual Network (e.g. ["10.10.0.0/23"]). |
| subnet_workload_cidr | string | — | Yes | CIDR block for the workload subnet. An NSG and route table are attached to this subnet. |
| instance | string | "001" | No | Zero-padded 3-digit instance identifier passed to the naming module. |
| subnet_firewall_cidr | string | null | No | CIDR block for AzureFirewallSubnet. Required when egress_type = "firewall". |
| subnet_bastion_cidr | string | null | No | CIDR block for AzureBastionSubnet. When set, the bastion subnet is added to the VNet without an NSG or route table. |
| egress_type | string | "none" | No | Egress strategy for workloads. Allowed values: 'none', 'firewall', 'nat_gateway'. |
| firewall_policy_sku | string | "Standard" | No | SKU tier for Azure Firewall Policy. Allowed values: 'Standard', 'Premium'. Only used when egress_type = "firewall". |
| firewall_policy_rule_collection_groups | map(object) | {} | No | Map of firewall policy rule collection groups. Only used when egress_type = "firewall". |
| log_analytics_workspace_id | string | null | No | Resource ID of a Log Analytics Workspace. When set, diagnostic settings are configured on all applicable resources. |

## Outputs

| Name | Description |
|------|-------------|
| vnet_resource_id | The resource ID of the hub Virtual Network. |
| vnet_name | The name of the hub Virtual Network. |
| workload_subnet_id | The resource ID of the workload subnet. |
| route_table_resource_id | The resource ID of the route table associated with the workload subnet. |
| resource_group_name | The name of the resource group containing all hub VNet resources. |
| resource_group_id | The resource ID of the resource group containing all hub VNet resources. |
| firewall_private_ip | The private IP address of the Azure Firewall. Null when egress_type is not 'firewall'. |
| nsg_resource_id | The resource ID of the Network Security Group attached to the workload subnet. |

## Usage

### Example 1: Hub VNet with no egress infrastructure

```hcl
module "hub_vnet_none" {
  source = "../../modules/hub-vnet"

  purpose               = "hub"
  region                = "eastus"
  instance              = "001"
  address_space         = ["10.10.0.0/23"]
  subnet_workload_cidr  = "10.10.1.0/25"
  egress_type           = "none"
}
```

### Example 2: Hub VNet with Azure Firewall and policy rule collection group

```hcl
module "hub_vnet_firewall" {
  source = "../../modules/hub-vnet"

  purpose                = "hub"
  region                 = "eastus"
  instance               = "001"
  address_space          = ["10.10.0.0/23"]
  subnet_workload_cidr   = "10.10.1.0/25"
  subnet_firewall_cidr   = "10.10.0.0/25"
  egress_type            = "firewall"
  firewall_policy_sku    = "Standard"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.hub.id

  firewall_policy_rule_collection_groups = {
    base_rules = {
      priority = 100
      network_rule_collections = [
        {
          name     = "allow-dns"
          priority = 100
          action   = "Allow"
          rules = [
            {
              name                  = "dns-google"
              protocols             = ["UDP"]
              source_addresses      = ["10.10.1.0/25"]
              destination_addresses = ["8.8.8.8", "8.8.4.4"]
              destination_ports     = ["53"]
            }
          ]
        }
      ]
    }
  }
}
```

### Example 3: Hub VNet with NAT Gateway egress

```hcl
module "hub_vnet_nat" {
  source = "../../modules/hub-vnet"

  purpose               = "hub"
  region                = "eastus"
  instance              = "001"
  address_space         = ["10.10.0.0/23"]
  subnet_workload_cidr  = "10.10.1.0/25"
  subnet_bastion_cidr   = "10.10.0.128/26"
  egress_type           = "nat_gateway"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.hub.id
}
```
