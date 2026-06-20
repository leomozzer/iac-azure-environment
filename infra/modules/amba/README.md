# AMBA Module

Deploys Azure Monitor Baseline Alerts (AMBA) for Azure Landing Zone (ALZ) using the AVM pattern module for standardized monitoring and alerting governance.

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
| root_management_group_name | string | — | Yes | The name (ID) of the root management group for AMBA ALZ policy assignments and scope definition. |

## Outputs

| Name | Description |
|------|-------------|
| resource_group_name | The name of the resource group containing the AMBA resources. |
| resource_group_id | The resource ID of the resource group containing the AMBA resources. |

## Usage

```hcl
module "amba" {
  source = "./modules/amba"

  purpose                    = "amba"
  region                     = "eastus"
  root_management_group_name = "Landing-Zone"
}
```

Resource names are derived automatically via the naming module. For the example above with instance defaulting to "001":
- Resource Group: `rg-amba-eus-001`
