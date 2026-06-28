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

## Modules

This section describes each Terraform module available in the `infra/modules/` directory. All modules are designed to be reusable and follow the naming conventions established in this project. For detailed module documentation, see the README.md in each module directory.

### naming

**Purpose**: Generates standardized Azure resource names following AVM conventions.

The naming module is the foundation of this repository. All resource names are derived using the pattern `{prefix}-{purpose}-{region_code}-{instance}` where the prefix is resource-type-specific.

**Inputs**:

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| purpose | string | — | Yes | Workload descriptor in lowercase hyphen-separated format (e.g., operations, networking). After stripping hyphens, must be ≤ 16 characters to keep storage account names within Azure's 24-character limit. |
| region | string | — | Yes | Full Azure region name (e.g., eastus, westeurope). Must be a supported region defined in locals.tf. |
| instance | string | "001" | No | Zero-padded 3-digit instance number (e.g., 001, 002, 010) to uniquely identify multiple deployments of the same purpose and region combination. |

**Key Outputs** (18 total): resource_group, log_analytics_workspace, virtual_network, subnet, storage_account, recovery_services_vault, action_group, alert_rule, network_security_group, vnet_peering, nat_gateway, network_watcher, network_watcher_flow_log, azure_firewall, firewall_policy, public_ip, route_table

**Usage Example**:

```hcl
module "naming" {
  source = "../../modules/naming"
  purpose  = "operations"
  region   = "eastus"
  instance = "001"
}

# All outputs are used to derive resource names throughout the infrastructure
resource "azurerm_resource_group" "example" {
  name     = module.naming.resource_group  # Outputs: rg-operations-eus-001
  location = "eastus"
}
```

---

### log-analytics-workspace

**Purpose**: Creates a Log Analytics Workspace and its resource group. Used for centralized logging and monitoring across the infrastructure.

**Key Features**:
- Creates a resource group using the naming module
- Deploys a Log Analytics Workspace with configurable SKU and retention
- Outputs workspace and resource group identifiers for use in diagnostic settings across other modules

**Inputs**:

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| purpose | string | — | Yes | Workload descriptor, lowercase hyphen-separated (e.g., operations, monitoring). Passed to the naming module. |
| region | string | — | Yes | Full Azure region name (e.g., eastus). Used for both the naming module and the resource location. |
| instance | string | "001" | No | Zero-padded 3-digit instance number (e.g., 001). Passed to the naming module. |
| sku | string | "PerGB2018" | No | SKU of the Log Analytics Workspace. Valid values: Free, PerNode, Premium, Standard, Standalone, Unlimited, CapacityReservation, PerGB2018. |
| retention_in_days | number | 30 | No | Workspace data retention in days. Either 7 (Free tier only) or a value between 30 and 730. |

**Outputs**:

| Name | Description |
|------|-------------|
| workspace_resource_id | The resource ID of the Log Analytics Workspace. Use when configuring diagnostic settings in other modules. |
| workspace_name | The name of the Log Analytics Workspace. |
| resource_group_name | The name of the resource group containing the Log Analytics Workspace. |
| resource_group_id | The resource ID of the resource group containing the Log Analytics Workspace. |

**Usage Example**:

```hcl
module "log_analytics_monitoring_eastus" {
  source = "../../modules/log-analytics-workspace"
  purpose            = "monitoring"
  region             = "eastus"
  instance           = "001"
  sku                = "PerGB2018"
  retention_in_days  = 30
}

# Use the workspace_resource_id in hub and spoke modules for diagnostic logging
```

---

### hub-vnet

**Purpose**: Creates a hub Virtual Network and its supporting infrastructure (subnets, NSG, route table). Optionally deploys an Azure Firewall for centralized egress control.

The hub VNet serves as the central network node in a hub-and-spoke topology. It can host an Azure Firewall and Bastion subnet for spoke access.

**Key Features**:
- Creates VNet with workload and optional bastion subnets
- Supports three egress strategies: none, firewall, or NAT Gateway
- When egress_type = "firewall", deploys Azure Firewall with configurable policy rules
- Integrates with Log Analytics for diagnostic logging on VNet, NSG, Firewall, and Firewall Policy
- Configurable NSG for the workload subnet

**Inputs** (major ones):

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| purpose | string | — | Yes | Workload descriptor passed to the naming module (e.g., hub, networking). |
| region | string | — | Yes | Azure region for all resources and passed to the naming module (e.g., eastus). |
| address_space | list(string) | — | Yes | One or more CIDR ranges for the hub Virtual Network (e.g., ["10.10.0.0/23"]). |
| subnet_workload_cidr | string | — | Yes | CIDR block for the workload subnet. Route table always attached; NSG only when create_workload_nsg = true. |
| instance | string | "001" | No | Zero-padded 3-digit instance identifier passed to the naming module. |
| subnet_firewall_cidr | string | null | No | CIDR block for AzureFirewallSubnet. Required when egress_type = "firewall". Ignored otherwise. |
| subnet_bastion_cidr | string | null | No | CIDR block for AzureBastionSubnet. When set, the bastion subnet is added without NSG or route table. |
| egress_type | string | "none" | No | Egress strategy. Allowed values: 'none', 'firewall', 'nat_gateway'. |
| firewall_policy_sku | string | "Standard" | No | SKU tier for Azure Firewall Policy. Only used when egress_type = "firewall". |
| log_analytics_workspace_id | string | null | No | Resource ID of Log Analytics Workspace. When set, diagnostic settings are configured on all supported resources. |
| create_workload_nsg | bool | true | No | When false, no NSG is created or attached. Can only be false when egress_type = "firewall". |

**Outputs**:

| Name | Description |
|------|-------------|
| vnet_resource_id | The resource ID of the hub Virtual Network. |
| vnet_name | The name of the hub Virtual Network. |
| workload_subnet_id | The resource ID of the workload subnet. |
| route_table_resource_id | The resource ID of the route table associated with the workload subnet. |
| resource_group_name | The name of the resource group containing all hub VNet resources. |
| resource_group_id | The resource ID of the resource group containing all hub VNet resources. |
| firewall_private_ip | The private IP address of the Azure Firewall. Null when egress_type is not 'firewall'. |
| nsg_resource_id | The resource ID of the Network Security Group attached to the workload subnet. Null when create_workload_nsg = false. |

**Usage Example**:

```hcl
module "vnet_hub_eastus_001" {
  source = "../../modules/hub-vnet"
  purpose              = "hub"
  region               = "eastus"
  address_space        = ["10.10.0.0/23"]
  subnet_workload_cidr = "10.10.0.0/24"
  subnet_bastion_cidr  = "10.10.1.64/26"

  # Optional: Enable firewall for egress control
  # egress_type           = "firewall"
  # subnet_firewall_cidr  = "10.10.1.0/26"
  # firewall_policy_sku   = "Standard"

  log_analytics_workspace_id = module.log_analytics_monitoring_eastus.workspace_resource_id
}
```

---

### spoke-vnet

**Purpose**: Creates a spoke Virtual Network peered to a hub VNet. Designed for workload isolation while allowing centralized egress control through the hub firewall.

The spoke VNet maintains a bidirectional peering relationship with the hub and can be configured to route traffic through the hub's firewall.

**Key Features**:
- Creates VNet with workload and optional bastion subnets
- Establishes bidirectional VNet peering to hub
- Supports optional default route to hub firewall (0.0.0.0/0 → VirtualAppliance)
- Optionally creates NAT Gateway for outbound connectivity
- Supports additional custom subnets with independent NSG/route table configuration
- Integrates with Log Analytics for diagnostic logging

**Inputs** (major ones):

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| purpose | string | — | Yes | Workload descriptor passed to the naming module (e.g., application, avd). |
| region | string | — | Yes | Azure region for all resources and passed to the naming module (e.g., eastus). |
| address_space | list(string) | — | Yes | One or more CIDR ranges for the spoke Virtual Network (e.g., ["10.20.0.0/24"]). |
| subnet_workload_cidr | string | — | Yes | CIDR block for the workload subnet. Route table always attached; NSG only when create_workload_nsg = true. |
| hub_vnet_resource_id | string | — | Yes | Resource ID of the hub Virtual Network. Used as the remote_virtual_network_id in spoke-to-hub peering. |
| hub_vnet_name | string | — | Yes | Name of the hub Virtual Network. Used in hub-to-spoke peering (requires azurerm.hub provider). |
| hub_resource_group_name | string | — | Yes | Name of the hub resource group. Used in hub-to-spoke peering (requires azurerm.hub provider). |
| instance | string | "001" | No | Zero-padded 3-digit instance identifier passed to the naming module. |
| subnet_bastion_cidr | string | null | No | CIDR block for AzureBastionSubnet. When set, the bastion subnet is added without NSG or route table. |
| hub_firewall_private_ip | string | null | No | Private IP address of the hub Azure Firewall. When set with create_firewall_route = true, a default route forces traffic through the firewall. |
| create_firewall_route | bool | false | No | When true, adds a default route (0.0.0.0/0 → VirtualAppliance) pointing at hub_firewall_private_ip. Must be set explicitly — cannot be inferred at plan time. |
| create_nat_gateway | bool | false | No | When true, creates a NAT Gateway in the spoke. Mutually exclusive with create_firewall_route. |
| create_workload_nsg | bool | true | No | When false, no NSG is created or attached to the workload subnet. |
| additional_subnets | map(object) | {} | No | Additional subnets to create with independent NSG/route table configuration. Keys are internal Terraform references (e.g., "database"). |

**Outputs**:

| Name | Description |
|------|-------------|
| vnet_resource_id | The resource ID of the spoke Virtual Network. |
| vnet_name | The name of the spoke Virtual Network. |
| workload_subnet_id | The resource ID of the workload subnet. |
| route_table_resource_id | The resource ID of the route table associated with the workload subnet. |
| resource_group_name | The name of the resource group containing all spoke VNet resources. |
| resource_group_id | The resource ID of the resource group containing all spoke VNet resources. |
| nsg_resource_id | The resource ID of the Network Security Group attached to the workload subnet. Null when create_workload_nsg = false. |
| additional_subnet_ids | Map of resource IDs for additional subnets, keyed by the same keys as var.additional_subnets. |
| additional_nsg_ids | Map of NSG resource IDs for additional subnets where create_nsg = true. |
| additional_route_table_ids | Map of route table resource IDs for additional subnets where create_route_table = true. |
| nat_gateway_resource_id | The resource ID of the NAT Gateway created in the spoke. Null when create_nat_gateway = false. |

**Usage Example**:

```hcl
module "vnet_spoke_application" {
  source = "../../modules/spoke-vnet"
  purpose                 = "application"
  region                  = "eastus"
  address_space           = ["10.20.0.0/24"]
  subnet_workload_cidr    = "10.20.0.0/25"
  
  # Hub peering details
  hub_vnet_resource_id        = module.vnet_hub_eastus_001.vnet_resource_id
  hub_vnet_name               = module.vnet_hub_eastus_001.vnet_name
  hub_resource_group_name     = module.vnet_hub_eastus_001.resource_group_name
  hub_firewall_private_ip     = module.vnet_hub_eastus_001.firewall_private_ip
  create_firewall_route       = true

  log_analytics_workspace_id  = module.log_analytics_monitoring_eastus.workspace_resource_id
}
```

---

### amba

**Purpose**: Deploys Azure Monitor Baseline Alerts (AMBA) using the AMBA ALZ policy module. Provides comprehensive monitoring and alerting for Azure resources through Azure Policy.

AMBA is an initiative to promote baseline alerts across Azure resources. This module orchestrates policy deployment at the management group level and creates supporting infrastructure for monitoring.

**Key Features**:
- Deploys AMBA ALZ monitoring policies to a management group
- Creates a user-assigned managed identity for policy remediation
- Creates an action group for alert notifications
- Supports tagging resources to disable monitoring (via amba_disable_tag_name)
- Configurable email addresses for alert notifications

**Inputs**:

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| region | string | — | Yes | Full Azure region name (e.g., eastus). Used for both the naming module and the resource location. |
| root_management_group_name | string | — | Yes | The name (ID) of the root management group for AMBA ALZ policy assignments. |
| instance | string | "001" | No | Zero-padded 3-digit instance number (e.g., 001). Passed to the naming module. |
| management_subscription_id | string | "" | No | Subscription ID where AMBA resources are deployed. Defaults to the current subscription when empty. |
| user_assigned_managed_identity_name | string | "id-amba-prod-001" | No | Name of the user-assigned managed identity created by AMBA for policy remediation. |
| tags | map(string) | { _deployed_by_amba = "true" } | No | Tags applied to all resources deployed by this module. |
| action_group_email | list(string) | [] | No | Email addresses for the AMBA action group alert notifications. |
| amba_disable_tag_name | string | "MonitorDisable" | No | Tag name used to disable AMBA monitoring at the resource level. |
| amba_disable_tag_values | list(string) | ["true", "Test", "Dev", "Sandbox"] | No | Tag values that disable AMBA monitoring when present on a resource. |

**Outputs**:

| Name | Description |
|------|-------------|
| resource_group_name | The name of the resource group containing the AMBA resources. |
| user_assigned_managed_identity_id | The resource ID of the user-assigned managed identity created by AMBA. |

**Usage Example**:

```hcl
module "amba_eastus" {
  source = "../../modules/amba"
  region                     = "eastus"
  root_management_group_name = var.root_management_group_name
  
  # Optional: Configure alert notifications
  action_group_email = ["ops-team@example.com"]
  
  # Optional: Customize monitoring disable tag
  amba_disable_tag_name   = "MonitorDisable"
  amba_disable_tag_values = ["true", "Test", "Dev", "Sandbox"]
}
```

---

## Module Architecture

The modules follow a layered architecture:

1. **naming** (foundation) — All other modules depend on this for consistent resource naming
2. **log-analytics-workspace** (logging tier) — Provides centralized logging infrastructure
3. **hub-vnet** and **spoke-vnet** (networking tier) — Create network infrastructure, optionally logging to Log Analytics
4. **amba** (monitoring tier) — Deploys monitoring policies across the infrastructure

## Calling Multiple Modules

All modules are designed to work together. The typical deployment pattern is:

```hcl
# 1. Create Log Analytics for logging
module "log_analytics" {
  source   = "../../modules/log-analytics-workspace"
  purpose  = "monitoring"
  region   = "eastus"
  instance = "001"
}

# 2. Create hub network
module "hub_vnet" {
  source                     = "../../modules/hub-vnet"
  purpose                    = "hub"
  region                     = "eastus"
  address_space              = ["10.10.0.0/23"]
  subnet_workload_cidr       = "10.10.0.0/24"
  subnet_bastion_cidr        = "10.10.1.64/26"
  log_analytics_workspace_id = module.log_analytics.workspace_resource_id
}

# 3. Create spokes and peer to hub
module "spoke_vnet" {
  source                  = "../../modules/spoke-vnet"
  purpose                 = "application"
  region                  = "eastus"
  address_space           = ["10.20.0.0/24"]
  subnet_workload_cidr    = "10.20.0.0/25"
  hub_vnet_resource_id    = module.hub_vnet.vnet_resource_id
  hub_vnet_name           = module.hub_vnet.vnet_name
  hub_resource_group_name = module.hub_vnet.resource_group_name
  hub_firewall_private_ip = module.hub_vnet.firewall_private_ip
  create_firewall_route   = true
}

# 4. Deploy baseline monitoring alerts
module "amba" {
  source                     = "../../modules/amba"
  region                     = "eastus"
  root_management_group_name = "your-management-group-id"
}
```

See `infra/environments/prod/` for a complete working example using all modules together.
