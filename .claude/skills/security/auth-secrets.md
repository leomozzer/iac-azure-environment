# Auth and Secrets — Azure IaC

## Terraform Execution Identity

### Preferred: Managed Identity (CI/CD)
- Use a User-Assigned Managed Identity for CI/CD pipelines running `terraform apply`
- Assign only the required RBAC roles — never `Owner` at subscription scope
- Minimum roles for this project:
  - `Contributor` — resource provisioning
  - `User Access Administrator` — only if Terraform manages RBAC assignments (scope to specific resource groups)
  - `Key Vault Administrator` — only on Key Vault resource groups

### Fallback: Service Principal
- Use client certificate auth, not client secret, where possible
- Client secrets: rotate every 90 days, store in Azure Key Vault — never in `.env` or `.tfvars` committed to git
- One SP per environment (dev / prod) — never share credentials across environments
- Never set SP credentials via environment variables in shared CI runners without secret masking

## Terraform State File Security

### What the State File Contains
- State files can contain sensitive values (admin passwords, connection strings, secrets passed as variables)
- Always use remote state (Azure Storage backend) — never commit `.tfstate` files to git

### Backend Security
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "<rg-name>"
    storage_account_name = "<st-name>"
    container_name       = "tfstate"
    key                  = "<env>/<stack>.tfstate"
  }
}
```
- Storage Account must have: `min_tls_version = "TLS1_2"`, `public_network_access_enabled = false`, firewall scoped to CI/CD runner IPs or private endpoint
- Enable Storage Account versioning and soft delete on the blob container
- Lock the state container with `azurerm_management_lock` to prevent accidental deletion
- Use SAS tokens or Managed Identity for backend auth — never storage account keys in CI secrets

### Sensitive Outputs
- Always mark outputs containing secrets, connection strings, or credentials with `sensitive = true`
- Never use `terraform output` in logs without `-json` and secret masking
- Audit `outputs.tf` files: any output referencing Key Vault secrets, passwords, or primary keys must be sensitive

## Secrets — What Never to Do

- Never hardcode subscription IDs, tenant IDs, client IDs, or client secrets in `.tf` files
- Never commit `.tfvars` files containing real credential values — use `.gitignore` and document with `.tfvars.example`
- Never log sensitive variable values — use `sensitive = true` on variables containing secrets
- Never store secrets as Terraform `local` values — they appear plaintext in state

## Secrets — Where to Store

| Secret | Storage |
|---|---|
| SP client secret (CI/CD) | Azure Key Vault or CI/CD platform secret store |
| Terraform backend credentials | Managed Identity or CI/CD platform secret store |
| Resource admin passwords | Generated via `random_password`, stored in Key Vault via `azurerm_key_vault_secret` |
| SSH public keys | Variable input — private keys never in Terraform |
| API keys for resources | Azure Key Vault, referenced via data source |

## Key Vault Security Checklist

- [ ] `soft_delete_retention_days` ≥ 7 (default 90)
- [ ] `purge_protection_enabled = true` on production Key Vaults
- [ ] Access via RBAC (`enable_rbac_authorization = true`) — not legacy access policies
- [ ] No public network access unless explicitly required; use private endpoint
- [ ] Diagnostic settings sending audit logs to Log Analytics Workspace
- [ ] No wildcard secret permissions — scope to specific secret names where possible
