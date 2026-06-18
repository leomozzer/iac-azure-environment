# Log Analytics Workspace Module

Provisions an Azure Log Analytics Workspace and resource group using AVM modules for operational insights collection and analysis.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9 |
| azurerm | >= 4.36.0 |
| azapi | ~> 2.4 |
| modtm | ~> 0.3 |
| random | ~> 3.5 |
| time | ~> 0.9 |

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| purpose | string | — | Yes | Workload descriptor in lowercase hyphen-separated format (e.g., operations, monitoring). Passed to the naming module to derive resource names. |
| region | string | — | Yes | Full Azure region name (e.g., eastus). Used for both the naming module region code derivation and the physical location of all resources. |
| instance | string | "001" | No | Zero-padded 3-digit instance number (e.g., 001, 002) to uniquely identify multiple deployments of the same purpose and region combination. Passed to the naming module. |
| sku | string | "PerGB2018" | No | SKU tier of the Log Analytics Workspace. Valid values: Free, PerNode, Premium, Standard, Standalone, Unlimited, CapacityReservation, PerGB2018. |
| retention_in_days | number | 30 | No | Data retention period in days. Must be 7 (Free tier only) or between 30 and 730 for other SKUs. |

## Outputs

| Name | Description |
|------|-------------|
| workspace_resource_id | The resource ID of the Log Analytics Workspace. |
| workspace_name | The name of the Log Analytics Workspace (sensitive). |
| resource_group_name | The name of the resource group containing the Log Analytics Workspace. |
| resource_group_id | The resource ID of the resource group containing the Log Analytics Workspace. |

## Usage

```hcl
module "log_analytics" {
  source = "./modules/log-analytics-workspace"

  purpose = "monitoring"
  region  = "eastus"

  sku                = "PerGB2018"
  retention_in_days  = 30
}
```

Resource names are derived automatically via the naming module. For the example above with instance defaulting to "001":
- Resource Group: `rg-monitoring-eus-001`
- Log Analytics Workspace: `log-monitoring-eus-001`
