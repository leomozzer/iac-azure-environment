# Azure Resource Security

## Virtual Networking

### NSG Rules
- Default deny all inbound from Internet — never rely on Azure's default rules alone
- No inbound rules allowing `*` or `0.0.0.0/0` on ports 22, 3389, or any management port
- Use Application Security Groups (ASG) for workload-to-workload rules — avoids hardcoded IP ranges
- Audit `azurerm_network_security_rule` blocks: `source_address_prefix = "Internet"` is a red flag on inbound allow rules
- Log NSG flow logs to Log Analytics Workspace via `azurerm_network_watcher_flow_log`

### Subnet Design
- Every subnet must have an NSG — no bare subnets
- Management subnets: restrict inbound to known CIDR ranges only (no `*`)
- Service endpoints or private endpoints for PaaS resources (Storage, Key Vault) — avoid public routing

### VNet Peering
- Peering does not inherit NSG rules — verify NSGs exist on both sides
- Disable `allow_gateway_transit` and `use_remote_gateways` unless explicitly required

## Storage Account

### Mandatory Hardening
```hcl
resource "azurerm_storage_account" "example" {
  min_tls_version              = "TLS1_2"
  public_network_access_enabled = false
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled   = true  # implied by TLS setting but explicit is better
  
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = []  # scope to CI/CD IPs if public access needed
  }
}
```
- Enable soft delete for blobs and containers: `delete_retention_policy { days = 7 }` minimum, 30 for production
- Enable versioning for state containers
- Diagnostic settings: send `StorageRead`, `StorageWrite`, `StorageDelete` logs to Log Analytics

### Backend State Storage Specific
- Dedicated Storage Account for Terraform state — no other data
- Lock state container with `azurerm_management_lock { lock_level = "CanNotDelete" }`
- Restrict access via Managed Identity — no storage account key access if avoidable

## Key Vault

### Required Configuration
```hcl
resource "azurerm_key_vault" "example" {
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true   # mandatory for production
  enable_rbac_authorization   = true   # RBAC over legacy access policies
  
  network_acls {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}
```
- Private endpoint for production Key Vaults — no public network access
- RBAC roles: `Key Vault Secrets User` for read-only consumers, `Key Vault Secrets Officer` for write
- Diagnostic settings: `AuditEvent` category to Log Analytics — mandatory for compliance

## Recovery Services Vault

```hcl
resource "azurerm_recovery_services_vault" "example" {
  sku                          = "Standard"
  soft_delete_enabled          = true   # never disable in production
  storage_mode_type            = "GeoRedundant"
  cross_region_restore_enabled = true
}
```
- Immutability: set `immutability = "Locked"` for production vaults handling compliance workloads
- Monitor backup job failures via Alert Rules on `azurerm_monitor_metric_alert` targeting the vault
- Backup policies: enforce minimum retention (30 days daily, 12 weeks weekly) for production VMs

## Log Analytics Workspace

- Retention: minimum 90 days (`retention_in_days = 90`), extend to 365 for compliance
- All Azure resources in scope must have diagnostic settings pointing to the workspace
- Workspace access: use RBAC (`Log Analytics Reader` for query access, `Log Analytics Contributor` for config)
- Network: private link for workspaces handling sensitive log data

## Azure Policy Guardrails

Assign these at the resource group or subscription scope as `Deny` effect to enforce security baseline:

| Policy | Effect | Purpose |
|---|---|---|
| Require HTTPS on Storage Accounts | Deny | Blocks HTTP-only storage |
| Require TLS 1.2 minimum on Storage | Deny | Blocks weak TLS |
| Deny public network access on Key Vault | Deny | Prevents public KV exposure |
| Require soft delete on Key Vault | Deny | Prevents accidental secret loss |
| Require NSG on subnets | Deny | Prevents bare subnets |
| Require diagnostic settings | DeployIfNotExists | Enforces logging coverage |
| Require tags | Deny | Enforces governance tagging |

## Diagnostic Settings — Coverage Checklist

Every resource must have `azurerm_monitor_diagnostic_setting` sending to the Log Analytics Workspace:
- [ ] Virtual Networks — flow logs via Network Watcher
- [ ] NSGs — flow logs
- [ ] Storage Accounts — read/write/delete operations
- [ ] Key Vaults — AuditEvent
- [ ] Recovery Services Vaults — AzureBackupReport, CoreAzureBackup
- [ ] Action Groups — alert fire events
- [ ] Log Analytics Workspace itself — audit logs

## Quick Security Review Checklist

- [ ] No NSG rules with `source_address_prefix = "*"` on inbound allow?
- [ ] All storage accounts: `public_network_access_enabled = false`?
- [ ] All storage accounts: `min_tls_version = "TLS1_2"`?
- [ ] Key Vault has `purge_protection_enabled = true`?
- [ ] Key Vault uses RBAC auth (`enable_rbac_authorization = true`)?
- [ ] Recovery Services Vault has `soft_delete_enabled = true`?
- [ ] Terraform state backend storage: network rules set to Deny?
- [ ] All sensitive Terraform outputs marked `sensitive = true`?
- [ ] Diagnostic settings configured for all resources in scope?
- [ ] No plaintext credentials in `.tf` or `.tfvars` files committed to git?
