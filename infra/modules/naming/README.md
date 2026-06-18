# Naming Module

Generates standardized Azure resource names following AVM conventions. All resource names are derived using a base pattern of `{prefix}-{purpose}-{region_code}-{instance}` where the prefix is resource-type-specific.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9 |

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| purpose | string | — | Yes | Workload descriptor in lowercase hyphen-separated format (e.g., operations, networking). After stripping hyphens, must be <= 16 characters to keep storage account names within Azure's 24-character limit. |
| region | string | — | Yes | Full Azure region name (e.g., eastus, westeurope). Currently supported: eastus, westeurope. Add new regions to the region_short map in locals.tf and update the validation block in variables.tf. |
| instance | string | "001" | No | Zero-padded 3-digit instance number (e.g., 001, 002, 010) to uniquely identify multiple deployments of the same purpose and region combination. Must be exactly 3 digits. |

## Outputs

| Name | Description |
|------|-------------|
| resource_group | The name of the resource group (prefix: rg). |
| log_analytics_workspace | The name of the Log Analytics Workspace (prefix: log). |
| virtual_network | The name of the Virtual Network (prefix: vnet). |
| subnet | The name of the subnet (prefix: snet). |
| storage_account | The name of the storage account (prefix: st, hyphens removed per Azure naming rules). |
| recovery_services_vault | The name of the Recovery Services Vault (prefix: rsv). |
| action_group | The name of the Azure Monitor Action Group (prefix: ag). |
| alert_rule | The name of the alert rule (prefix: alr). |
| network_security_group | The name of the Network Security Group (prefix: nsg). |
| vnet_peering | The name of the VNet peering (prefix: peer). |
| nat_gateway | The name of the NAT Gateway (prefix: ng). |
| network_watcher | The name of the Network Watcher (prefix: nw). |
| network_watcher_flow_log | The name of the Network Watcher flow log (prefix: flw). |
| azure_firewall | The name of the Azure Firewall (prefix: afw). |
| firewall_policy | The name of the Azure Firewall Policy (prefix: afwp). |
| public_ip | The name of the public IP address (prefix: pip). |
| route_table | The name of the route table (prefix: rt). |

## Naming Convention

All resources follow the standard pattern: `{prefix}-{purpose}-{region_code}-{instance}`

### Supported Regions

| Region Name | Short Code |
|---|---|
| eastus | eus |
| westeurope | weu |

To add a new region:
1. Add an entry to the `region_short` map in `locals.tf`
2. Add the region to the `validation` block in `variables.tf`

### Resource Prefixes

| Azure Resource | Prefix | Example Name |
|---|---|---|
| Resource Group | `rg` | `rg-operations-eus-001` |
| Log Analytics Workspace | `log` | `log-operations-eus-001` |
| Virtual Network | `vnet` | `vnet-networking-eus-001` |
| Subnet | `snet` | `snet-networking-eus-001` |
| Storage Account | `st` | `stoperationseus001` |
| Recovery Services Vault | `rsv` | `rsv-operations-eus-001` |
| Azure Monitor Action Group | `ag` | `ag-operations-eus-001` |
| Alert Rule | `alr` | `alr-operations-eus-001` |
| Network Security Group | `nsg` | `nsg-networking-eus-001` |
| VNet Peering | `peer` | `peer-networking-eus-001` |
| NAT Gateway | `ng` | `ng-networking-eus-001` |
| Network Watcher | `nw` | `nw-networking-eus-001` |
| Network Watcher Flow Log | `flw` | `flw-networking-eus-001` |
| Azure Firewall | `afw` | `afw-hub-eus-001` |
| Firewall Policy | `afwp` | `afwp-hub-eus-001` |
| Public IP | `pip` | `pip-hub-eus-001` |
| Route Table | `rt` | `rt-networking-eus-001` |

## Usage

```hcl
module "naming" {
  source = "./modules/naming"

  purpose  = "operations"
  region   = "eastus"
  instance = "001"
}

# Use outputs to derive resource names
resource "azurerm_resource_group" "example" {
  name     = module.naming.resource_group  # outputs: rg-operations-eus-001
  location = "eastus"
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = module.naming.log_analytics_workspace  # outputs: log-operations-eus-001
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
}
```

## Notes

- **Purpose Length**: The purpose field length (after stripping hyphens) is validated to ensure storage account names stay within Azure's 24-character limit.
- **Instance Format**: The instance parameter must be exactly 3 digits, zero-padded (e.g., 001, 010, 100).
- **Region Support**: New regions must be added to both the region_short map in locals.tf and the validation block in variables.tf.
- **Storage Account Naming**: Storage account names remove hyphens per Azure naming rules and cannot exceed 24 characters total.
