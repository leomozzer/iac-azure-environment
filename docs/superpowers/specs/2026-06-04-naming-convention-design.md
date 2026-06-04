# Naming Convention Design

**Date:** 2026-06-04  
**Status:** Approved  
**Scope:** Azure resource naming conventions, Terraform naming module, CLAUDE.md rules, README documentation

---

## Problem

No standardized naming convention exists for Azure resources. Names were hardcoded across Terraform files with no consistent pattern, making it difficult to identify resource purpose, region, and instance at a glance.

---

## Goals

1. Define a single naming pattern enforced across all resource types
2. Centralize naming logic in a reusable Terraform module
3. Document the convention in CLAUDE.md (rules) and README (reference)

---

## Naming Pattern

```
<prefix>-<purpose>-<region_short>-<instance>
```

| Segment | Description | Example |
|---|---|---|
| `prefix` | Resource type identifier (see table below) | `rg` |
| `purpose` | Lowercase hyphen-separated workload descriptor | `operations` |
| `region_short` | Short code for Azure region (see region map) | `eus` |
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

> **Storage Account exception:** Azure enforces 3–24 chars, lowercase alphanumeric only, no hyphens. The module outputs storage account names with hyphens stripped: `st<purpose><region_short><instance>` → `stoperationseus001`.

### Region Short Codes

| Azure Region | Short Code |
|---|---|
| `eastus` | `eus` |
| `westeurope` | `weu` |

New regions are added to the map in `infra/modules/naming/locals.tf` only — never inline.

---

## Architecture

### Naming Module

**Path:** `infra/modules/naming/`

```
infra/
  modules/
    naming/
      variables.tf   # inputs
      locals.tf      # region map + base string
      outputs.tf     # one output per resource type
  environments/
    prod/
      main.tf
      locals.tf
      variables.tf
      backend.tf
      provider.tf
```

**Inputs (`variables.tf`):**

| Variable | Type | Default | Description |
|---|---|---|---|
| `purpose` | `string` | — | Workload descriptor (e.g., `operations`) |
| `region` | `string` | — | Full Azure region name (e.g., `eastus`) |
| `instance` | `string` | `"001"` | Instance number |

**Locals (`locals.tf`):**
- `region_short` map: full region name → short code
- `region_code`: lookup of `var.region` in the map
- `base`: `"${var.purpose}-${local.region_code}-${var.instance}"`

**Outputs (`outputs.tf`):**
- One named output per resource type
- Follows `<prefix>-${local.base}` except storage account which strips hyphens

### Usage in Environment

```hcl
module "naming" {
  source   = "../../modules/naming"
  purpose  = "operations"
  region   = "eastus"
  instance = "001"
}

# Consume:
# module.naming.resource_group          → rg-operations-eus-001
# module.naming.log_analytics_workspace → log-operations-eus-001
# module.naming.storage_account         → stoperationseus001
```

---

## CLAUDE.md Rules (to add)

- All resource names derived from `infra/modules/naming/` — never hardcoded
- `purpose`: lowercase, hyphen-separated (e.g., `operations`, `networking`)
- `region`: full Azure region name passed to module; short code resolved internally
- `instance`: zero-padded 3-digit string, start at `001` per purpose+region combo
- New region → add to `infra/modules/naming/locals.tf` region map only
- New resource type → add output to `infra/modules/naming/outputs.tf`, add prefix to README and CLAUDE.md

---

## README Sections (to add/update)

1. Project overview — IaC for Azure using Terraform, organized under `infra/environments/`
2. Directory structure — tree showing naming module and prod environment
3. Naming conventions — pattern explanation + full prefix table + examples
4. How to add a new region — edit region map in naming module
5. How to add a new resource type — add module output + update docs

---

## Out of Scope

- Dev/staging environments (only `prod` exists)
- Policy definitions, role assignments, RBAC naming
- CI/CD pipeline changes
