# Project Rule

## Task Delegation — Mandatory

Always delegate. Never implement or document directly in the main conversation.

- Writing or editing Terraform file → invoke **@terraformer**
- Comments, README → invoke **@documenter**
- Anything Azure resources, ARM SDK, KQL, Key Vault, Entra ID → invoke **@azure-specialist**

For tasks spanning multiple domains (e.g., new Azure resource = azure-specialist + terraformer + documenter), chain agents in sequence.

## Naming Convention Rules

All resource names must be derived from `module.naming` outputs. Never hardcode names.

- `purpose`: lowercase, hyphen-separated descriptor (e.g., `operations`, `networking`)
- `region`: full Azure region name (e.g., `eastus`) — short code resolved internally by naming module
- `instance`: zero-padded 3-digit string, start at `001` per unique purpose+region combination
- New region: add to `region_short` map in `infra/modules/naming/locals.tf` only — never inline. Also update the `validation` block in `infra/modules/naming/variables.tf` to include the new region.
- New resource type: add output to `infra/modules/naming/outputs.tf`, add prefix row to README.md and CLAUDE.md prefix tables

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