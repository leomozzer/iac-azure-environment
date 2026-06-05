---
name: security-review
description: Use before any production deployment, when adding or modifying Azure resources, when touching credentials or backend config, or when auditing Terraform configurations for security misconfigurations.
---

## Goal

Identify and remediate security misconfigurations across this Azure IaC project: Terraform configurations, Azure resource settings, secrets handling, network design, and supply chain.

## When to Activate

- Pre-deployment security review of Terraform changes
- Adding or modifying NSG rules, storage accounts, Key Vault, or network resources
- Any change touching Service Principal credentials, backend config, or Managed Identity assignments
- Adding new Terraform providers or AVM modules
- Auditing Azure Policy assignments for gaps
- Reviewing diagnostic settings coverage

## How to Execute

1. Identify the area of concern: secrets/credentials, Azure resource config, network security, or supply chain
2. Read the corresponding reference file in this skill folder
3. Apply the relevant checklist
4. Document each finding with: severity, resource, impact, and remediation
5. Prioritize by real risk (probability × impact)
6. Delegate fixes: Terraform changes → @terraformer, Azure config advice → @azure-specialist

## Reference Files

- `auth-secrets.md` — credentials, Service Principal, Managed Identity, state file secrets, backend security
- `terraform-supply-chain.md` — provider pinning, AVM module verification, static analysis (tfsec/Checkov)
- `azure-resource-security.md` — NSG rules, storage hardening, Key Vault config, Policy guardrails, diagnostic settings

## Severity Levels

- **Critical**: sensitive values in plaintext state, hardcoded credentials in `.tf` files, public storage with no firewall, Key Vault with no soft delete
- **High**: overly permissive NSG rules (0.0.0.0/0 inbound), no diagnostic settings on critical resources, SP with Owner role at subscription scope
- **Medium**: missing purge protection on Key Vault, storage TLS < 1.2, unpinned provider/module versions
- **Low**: missing resource tags, verbose Terraform outputs not marked `sensitive`, outdated but non-critical module versions
