# IaC Azure Environment

Infrastructure as Code for Azure using Terraform, organized under `infra/environments/`.

## Directory Structure

```
infra/
  modules/
    naming/
      variables.tf   # Module inputs: purpose, region, instance
      locals.tf      # Region short-code map and base string computation
      outputs.tf     # One output per resource type
  environments/
    prod/
      main.tf        # Naming module instantiation and resources
      locals.tf      # Environment-specific locals
      variables.tf   # Environment input variables
      backend.tf     # Terraform remote state backend (Azure Storage)
      provider.tf    # AzureRM provider and Terraform version constraint
```

## Naming Conventions

All resource names follow the pattern:

```
<prefix>-<purpose>-<region_short>-<instance>
```

| Segment | Description | Example |
|---|---|---|
| `prefix` | Resource type identifier | `rg` |
| `purpose` | Lowercase hyphen-separated workload descriptor | `operations` |
| `region_short` | Short code for Azure region | `eus` |
| `instance` | Zero-padded 3-digit number, starting at `001` | `001` |

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

> **Storage Account exception:** Azure enforces 3–24 chars, lowercase alphanumeric only, no hyphens. The naming module strips hyphens: `stoperationseus001`.

### Region Short Codes

| Azure Region | Short Code |
|---|---|
| `eastus` | `eus` |
| `westeurope` | `weu` |

### Usage Example

```hcl
module "naming" {
  source   = "../../modules/naming"
  purpose  = "operations"
  region   = "eastus"
  instance = "001"
}

# module.naming.resource_group          → rg-operations-eus-001
# module.naming.log_analytics_workspace → log-operations-eus-001
# module.naming.storage_account         → stoperationseus001
```

## How to Add a New Region

1. Open `infra/modules/naming/locals.tf` and add the new entry to `region_short`:
   ```hcl
   region_short = {
     eastus       = "eus"
     westeurope   = "weu"
     <new_region> = "<short_code>"
   }
   ```
2. Open `infra/modules/naming/variables.tf` and add the new region to the `validation` block inside `variable "region"`.
3. Add a test run block to `infra/modules/naming/tests/naming.tftest.hcl` verifying the new short code.
4. Run `terraform test` from `infra/modules/naming/` and confirm it passes.

## How to Add a New Resource Type

1. Add output to `infra/modules/naming/outputs.tf`:
   ```hcl
   output "<resource_type>" {
     value = "<prefix>-${local.base}"
   }
   ```
2. Add a test run block to `infra/modules/naming/tests/naming.tftest.hcl`.
3. Run `terraform test` from `infra/modules/naming/` and confirm it passes.
4. Add prefix row to the README.md prefix table.
5. Add prefix row to the CLAUDE.md prefix table.
