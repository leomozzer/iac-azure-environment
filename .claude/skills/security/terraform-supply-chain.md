# Terraform Supply Chain and Static Analysis

## Provider Security

### Pin Provider Versions
Always use exact or constrained version pins in `required_providers` — never open-ended:
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"  # allow patch, lock major+minor
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.9.0"
}
```
- Run `terraform providers lock` after adding/upgrading providers — commit `.terraform.lock.hcl`
- Never delete `.terraform.lock.hcl` — it ensures reproducible provider downloads with hash verification
- Review provider changelogs before major version upgrades — breaking changes in `azurerm` v4 vs v3 are significant

### AVM Module Verification
- Only use modules from the official Azure Verified Modules registry: `registry.terraform.io`
- Always pin module versions — never use `version = "latest"` or omit version:
  ```hcl
  module "vnet" {
    source  = "Azure/avm-res-network-virtualnetwork/azurerm"
    version = "~> 0.8"  # pin to known-good minor
  }
  ```
- Before adopting a new AVM module: verify it appears in the published catalog at `azure.github.io/Azure-Verified-Modules`
- Check module security review status in the AVM catalog (look for the AVM badge and maintenance status)
- Never reference modules from GitHub directly (e.g., `git::https://...`) in production — use registry only

### Module Source Integrity
- After running `terraform init`, verify `.terraform/modules/` matches expected module versions
- Use `terraform providers mirror` for air-gapped or regulated environments
- Add `terraform init -upgrade` only intentionally — it can silently upgrade pinned modules

## Static Analysis

### tfsec
Run against all Terraform directories before PR merge:
```powershell
tfsec infra/ --format json --out tfsec-report.json
```
Key rules to enforce for this project:
- `azure-storage-no-public-access` — storage accounts must not allow public blob access
- `azure-network-no-public-ingress` — NSGs must not allow 0.0.0.0/0 inbound on sensitive ports
- `azure-keyvault-ensure-soft-delete` — Key Vault soft delete must be enabled
- `azure-keyvault-ensure-purge-protection` — purge protection on production vaults
- `azure-monitor-activity-retention-period` — Log Analytics retention ≥ 90 days

### Checkov
```powershell
checkov -d infra/ --framework terraform --output json
```
Focus checks:
- `CKV_AZURE_33` — Storage Account queue logging enabled
- `CKV_AZURE_35` — Storage Account network rules not set to allow all
- `CKV_AZURE_36` — Storage Account uses trusted Microsoft services only
- `CKV_AZURE_41` — Key Vault soft delete enabled
- `CKV_AZURE_42` — Key Vault purge protection enabled
- `CKV_AZURE_109` — Storage Account not publicly accessible
- `CKV_AZURE_110` — Storage Account uses HTTPS only

### terraform validate and fmt
Run both in CI before plan:
```powershell
terraform fmt -check -recursive
terraform validate
```

## Dependency Update Policy

- **Provider patch updates** (`~>` allows these automatically): apply each sprint, verify with `terraform plan`
- **Provider minor/major updates**: review changelog, test in dev environment first, then promote
- **AVM module updates**: check AVM release notes — modules follow SemVer; minor updates are safe, major may include breaking interface changes
- Track provider and module versions in a `versions.tf` or document in README — falling multiple major versions behind accumulates risk

## CI/CD Security Gates

Minimum gates before `terraform apply` in production:
- [ ] `terraform fmt -check` passes
- [ ] `terraform validate` passes
- [ ] `tfsec` returns no HIGH or CRITICAL findings
- [ ] Checkov passes all CRITICAL checks
- [ ] `terraform plan` output reviewed and approved (no unexpected destroys)
- [ ] `.terraform.lock.hcl` committed and matches expected hashes
