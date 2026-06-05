# Terraform CI/CD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement production-grade Terraform CI/CD pipelines using GitHub Actions with Azure Blob Storage backend, OIDC authentication, composite reusable actions, security scanning, and PR plan comments.

**Architecture:** Four composite actions (azure-backend, terraform-validate, terraform-plan, terraform-apply) called by two workflows (terraform-backend.yml bootstraps the backend infra; terraform-deploy.yml handles validate → plan → apply with environment gates). State files live in an Azure Storage Account created by the backend workflow; plan tarballs are uploaded to a `plans` container and downloaded in the apply job so plan and apply are decoupled across jobs.

**Tech Stack:** GitHub Actions, azure/login@v2 (OIDC), hashicorp/setup-terraform@v3, azure/cli@v2, aquasecurity/tfsec-action@v1.0.3, a7ul/tar-action@v1.1.3, marocchino/sticky-pull-request-comment@v2

---

## OIDC Authentication — Why and How

OIDC (Workload Identity Federation) is the best practice for GitHub Actions → Azure authentication. No stored client secrets, short-lived tokens issued per job.

**Required GitHub secrets** (replace `AZURE_SP` JSON blob approach):

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | Application (client) ID of the App Registration |
| `AZURE_TENANT_ID` | Directory (tenant) ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription ID |

**Required workflow permission:**
```yaml
permissions:
  id-token: write   # OIDC token request
  contents: read
```

**Setup in Azure (one-time, done outside pipeline):**
1. Create App Registration in Entra ID
2. Grant Contributor role on the subscription (or specific RGs)
3. Under App Registration → Certificates & secrets → Federated credentials → Add credential:
   - Entity type: `GitHub Actions`
   - Organization: your GitHub org
   - Repository: `iac-azure-environment`
   - Entity type: `Branch` → `main` (for apply)
   - Entity type: `Pull request` (for plan)

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `.github/actions/azure-backend/action.yml` | Create | Idempotent RG + storage account creation |
| `.github/actions/terraform-validate/action.yml` | Create | fmt check, init (no backend), validate, tfsec |
| `.github/actions/terraform-plan/action.yml` | Create | init with backend-config, plan, upload plan tar |
| `.github/actions/terraform-apply/action.yml` | Create | Download plan tar, apply |
| `.github/workflows/terraform-backend.yml` | Modify | Bootstrap backend infra via workflow_dispatch |
| `.github/workflows/terraform-deploy.yml` | Modify | PR → plan only; push/dispatch → plan + apply |
| `infra/environments/prod/backend.tf` | Modify | Remove empty strings — proper partial config |
| `docs/terraform-cicd.md` | Create (via @documenter) | Usage guide: setup, secrets, environments |

---

## Task 1: Create `azure-backend` composite action

**Files:**
- Create: `.github/actions/azure-backend/action.yml`

Bootstraps the Azure backend: resource group + storage account (with versioning + soft delete for state protection) + two containers (`tfstate`, `plans`). All steps are idempotent.

- [ ] **Step 1: Create directory and file**

```yaml
# .github/actions/azure-backend/action.yml
name: "Setup Terraform Backend"
description: "Idempotent: creates Azure RG, storage account, and containers for Terraform state"

inputs:
  azure-client-id:
    description: "Azure app registration client ID (OIDC)"
    required: true
  azure-tenant-id:
    description: "Azure tenant ID"
    required: true
  azure-subscription-id:
    description: "Azure subscription ID"
    required: true
  resource-group-name:
    description: "Name of the resource group to create"
    required: true
  resource-group-location:
    description: "Azure region (e.g. eastus)"
    required: true
  storage-account-name:
    description: "Storage account name — must be globally unique, max 24 chars, lowercase alphanumeric"
    required: true
  stage:
    description: "Deployment stage tag (dev/test/prod)"
    required: true

runs:
  using: composite
  steps:
    - name: Azure Login (OIDC)
      uses: azure/login@v2
      with:
        client-id: ${{ inputs.azure-client-id }}
        tenant-id: ${{ inputs.azure-tenant-id }}
        subscription-id: ${{ inputs.azure-subscription-id }}

    - name: Create Resource Group
      uses: azure/cli@v2
      with:
        inlineScript: |
          az group create \
            --location "${{ inputs.resource-group-location }}" \
            --name "${{ inputs.resource-group-name }}" \
            --tags "UseCase=TerraformBackend" "Stage=${{ inputs.stage }}" \
            --output none

    - name: Create Storage Account
      uses: azure/cli@v2
      with:
        inlineScript: |
          az storage account create \
            --resource-group "${{ inputs.resource-group-name }}" \
            --name "${{ inputs.storage-account-name }}" \
            --sku Standard_LRS \
            --kind StorageV2 \
            --access-tier Cool \
            --allow-blob-public-access false \
            --min-tls-version TLS1_2 \
            --output none

    - name: Enable Blob Versioning and Soft Delete
      uses: azure/cli@v2
      with:
        inlineScript: |
          az storage account blob-service-properties update \
            --account-name "${{ inputs.storage-account-name }}" \
            --resource-group "${{ inputs.resource-group-name }}" \
            --enable-versioning true \
            --enable-delete-retention true \
            --delete-retention-days 30 \
            --output none

    - name: Create Containers
      uses: azure/cli@v2
      with:
        inlineScript: |
          az storage container create \
            --name tfstate \
            --account-name "${{ inputs.storage-account-name }}" \
            --auth-mode login \
            --output none

          az storage container create \
            --name plans \
            --account-name "${{ inputs.storage-account-name }}" \
            --auth-mode login \
            --output none
```

- [ ] **Step 2: Commit**

```bash
git add .github/actions/azure-backend/action.yml
git commit -m "feat(ci): add azure-backend composite action"
```

---

## Task 2: Create `terraform-validate` composite action

**Files:**
- Create: `.github/actions/terraform-validate/action.yml`

Runs fmt check, `init -backend=false` (downloads providers, no state), validate, and tfsec security scan. No backend credentials needed — safe for PR workflows.

- [ ] **Step 1: Create file**

```yaml
# .github/actions/terraform-validate/action.yml
name: "Terraform Validate"
description: "Format check, validate, and tfsec security scan — no backend required"

inputs:
  working-dir:
    description: "Path to the Terraform root module (e.g. ./infra/environments/prod)"
    required: true
  terraform-version:
    description: "Terraform version to install"
    required: false
    default: "1.9.0"

runs:
  using: composite
  steps:
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: ${{ inputs.terraform-version }}

    - name: Terraform Format Check
      shell: bash
      working-directory: ${{ inputs.working-dir }}
      run: terraform fmt -check -recursive -diff
      continue-on-error: false

    - name: Terraform Init (no backend)
      shell: bash
      working-directory: ${{ inputs.working-dir }}
      run: terraform init -backend=false

    - name: Terraform Validate
      shell: bash
      working-directory: ${{ inputs.working-dir }}
      run: terraform validate

    - name: tfsec Security Scan
      uses: aquasecurity/tfsec-action@v1.0.3
      with:
        working_directory: ${{ inputs.working-dir }}
        github_token: ${{ github.token }}
```

- [ ] **Step 2: Commit**

```bash
git add .github/actions/terraform-validate/action.yml
git commit -m "feat(ci): add terraform-validate composite action"
```

---

## Task 3: Create `terraform-plan` composite action

**Files:**
- Create: `.github/actions/terraform-plan/action.yml`

Runs `terraform init` with partial `-backend-config` flags (no hardcoded backend values), `terraform plan -out`, archives the entire working dir (including plan binary) as a tarball, and uploads to the `plans` container. The archive is keyed by `run_number` so the apply job can download the exact same artifact.

- [ ] **Step 1: Create file**

```yaml
# .github/actions/terraform-plan/action.yml
name: "Terraform Plan"
description: "Init with backend config, plan, and upload plan artifact to Azure Blob"

inputs:
  working-dir:
    description: "Path to the Terraform root module"
    required: true
  azure-client-id:
    required: true
  azure-tenant-id:
    required: true
  azure-subscription-id:
    required: true
  resource-group-name:
    description: "Resource group of the backend storage account"
    required: true
  storage-account-name:
    description: "Backend storage account name"
    required: true
  container-name:
    description: "Container for state files"
    required: false
    default: "tfstate"
  state-key:
    description: "State file blob key (e.g. prod.tfstate)"
    required: true
  stage:
    description: "Deployment stage (dev/test/prod)"
    required: true
  terraform-version:
    required: false
    default: "1.9.0"
  plan-output-file:
    description: "Output file for plan text (used for PR comments)"
    required: false
    default: "tfplan.txt"

outputs:
  plan-text:
    description: "Human-readable plan output"
    value: ${{ steps.show-plan.outputs.stdout }}

runs:
  using: composite
  steps:
    - name: Azure Login (OIDC)
      uses: azure/login@v2
      with:
        client-id: ${{ inputs.azure-client-id }}
        tenant-id: ${{ inputs.azure-tenant-id }}
        subscription-id: ${{ inputs.azure-subscription-id }}

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: ${{ inputs.terraform-version }}
        terraform_wrapper: false

    - name: Terraform Init
      shell: bash
      working-directory: ${{ inputs.working-dir }}
      env:
        ARM_USE_OIDC: "true"
      run: |
        terraform init \
          -backend-config="resource_group_name=${{ inputs.resource-group-name }}" \
          -backend-config="storage_account_name=${{ inputs.storage-account-name }}" \
          -backend-config="container_name=${{ inputs.container-name }}" \
          -backend-config="key=${{ inputs.state-key }}" \
          -reconfigure

    - name: Terraform Plan
      id: plan
      shell: bash
      working-directory: ${{ inputs.working-dir }}
      env:
        ARM_USE_OIDC: "true"
      run: terraform plan -out="${{ inputs.stage }}.tfplan" -lock-timeout=10m

    - name: Show Plan (text for PR comment)
      id: show-plan
      shell: bash
      working-directory: ${{ inputs.working-dir }}
      run: |
        terraform show -no-color "${{ inputs.stage }}.tfplan" | tee "${{ inputs.plan-output-file }}"

    - name: Archive working directory with plan
      uses: a7ul/tar-action@v1.1.3
      with:
        command: c
        cwd: ${{ inputs.working-dir }}
        files: |
          ./
        outPath: plan-${{ inputs.stage }}-${{ github.run_number }}.tar.gz

    - name: Upload plan archive to Azure Blob
      uses: azure/cli@v2
      with:
        inlineScript: |
          az storage blob upload \
            --account-name "${{ inputs.storage-account-name }}" \
            --container-name "plans" \
            --file "plan-${{ inputs.stage }}-${{ github.run_number }}.tar.gz" \
            --name "plan-${{ inputs.stage }}-${{ github.run_number }}.tar.gz" \
            --auth-mode login \
            --overwrite
```

- [ ] **Step 2: Commit**

```bash
git add .github/actions/terraform-plan/action.yml
git commit -m "feat(ci): add terraform-plan composite action"
```

---

## Task 4: Create `terraform-apply` composite action

**Files:**
- Create: `.github/actions/terraform-apply/action.yml`

Downloads the plan archive from `plans` container (keyed by `run_number`), extracts it into the working dir, and runs `terraform apply` against the pre-approved plan binary. Does NOT re-run `terraform init` — the `.terraform` dir is inside the tarball.

- [ ] **Step 1: Create file**

```yaml
# .github/actions/terraform-apply/action.yml
name: "Terraform Apply"
description: "Download pre-approved plan from Azure Blob and apply"

inputs:
  working-dir:
    description: "Path to the Terraform root module (must match what was planned)"
    required: true
  azure-client-id:
    required: true
  azure-tenant-id:
    required: true
  azure-subscription-id:
    required: true
  storage-account-name:
    description: "Backend storage account name"
    required: true
  stage:
    description: "Deployment stage (dev/test/prod)"
    required: true

runs:
  using: composite
  steps:
    - name: Azure Login (OIDC)
      uses: azure/login@v2
      with:
        client-id: ${{ inputs.azure-client-id }}
        tenant-id: ${{ inputs.azure-tenant-id }}
        subscription-id: ${{ inputs.azure-subscription-id }}

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_wrapper: false

    - name: Download plan archive from Azure Blob
      uses: azure/cli@v2
      with:
        inlineScript: |
          az storage blob download \
            --account-name "${{ inputs.storage-account-name }}" \
            --container-name "plans" \
            --name "plan-${{ inputs.stage }}-${{ github.run_number }}.tar.gz" \
            --file "plan-${{ inputs.stage }}-${{ github.run_number }}.tar.gz" \
            --auth-mode login

    - name: Extract plan archive
      uses: a7ul/tar-action@v1.1.3
      with:
        command: x
        cwd: ${{ inputs.working-dir }}
        files: plan-${{ inputs.stage }}-${{ github.run_number }}.tar.gz

    - name: Terraform Apply
      shell: bash
      working-directory: ${{ inputs.working-dir }}
      env:
        ARM_USE_OIDC: "true"
      run: terraform apply -lock-timeout=10m "${{ inputs.stage }}.tfplan"
```

- [ ] **Step 2: Commit**

```bash
git add .github/actions/terraform-apply/action.yml
git commit -m "feat(ci): add terraform-apply composite action"
```

---

## Task 5: Update `terraform-backend.yml` workflow

**Files:**
- Modify: `.github/workflows/terraform-backend.yml`

Run once (or when backend infra changes). `workflow_dispatch` only. Calls the `azure-backend` composite action. Uses OIDC.

**Important:** `STORAGE_ACCOUNT_NAME` must be globally unique across all Azure. Change the value before first run.

- [ ] **Step 1: Replace file content**

```yaml
# .github/workflows/terraform-backend.yml
name: "0 - Terraform Backend"
# Run this workflow once to bootstrap the Azure storage account for Terraform state.
# After running, do NOT run again unless you need to recreate the backend.

on:
  workflow_dispatch:
    inputs:
      stage:
        description: "Deployment stage"
        required: true
        default: dev
        type: choice
        options: [dev, test, prod]

permissions:
  id-token: write
  contents: read

env:
  RESOURCE_GROUP_NAME: rg-tfstate-eus-001
  RESOURCE_GROUP_LOCATION: eastus
  # Must be globally unique, lowercase alphanumeric, max 24 chars — change before first run
  STORAGE_ACCOUNT_NAME: sttfstateiaceus001

jobs:
  backend:
    name: "Bootstrap Backend (${{ inputs.stage }})"
    runs-on: ubuntu-latest
    concurrency: backend-${{ inputs.stage }}
    steps:
      - uses: actions/checkout@v4

      - uses: ./.github/actions/azure-backend
        with:
          azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
          azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          resource-group-name: ${{ env.RESOURCE_GROUP_NAME }}
          resource-group-location: ${{ env.RESOURCE_GROUP_LOCATION }}
          storage-account-name: ${{ env.STORAGE_ACCOUNT_NAME }}
          stage: ${{ inputs.stage }}
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/terraform-backend.yml
git commit -m "feat(ci): update terraform-backend workflow — OIDC, composite action"
```

---

## Task 6: Rewrite `terraform-deploy.yml` workflow

**Files:**
- Modify: `.github/workflows/terraform-deploy.yml`

Three triggers:
- `pull_request` to `main` (infra paths): validate + plan, post plan as PR comment, **no apply**
- `push` to `main` (infra paths): validate + plan + apply (environment gate for `prod`)
- `workflow_dispatch`: manual, any stage, validate + plan + apply

The `apply` job has `environment: ${{ env.STAGE }}` which requires a GitHub Environment named `prod` (and optionally `dev`, `test`) with required reviewers. This is the approval gate.

**`env.STORAGE_ACCOUNT_NAME` must match what was set in `terraform-backend.yml`.**

- [ ] **Step 1: Replace file content**

```yaml
# .github/workflows/terraform-deploy.yml
name: "Terraform Deploy"

on:
  workflow_dispatch:
    inputs:
      stage:
        description: "Deployment stage"
        required: true
        default: prod
        type: choice
        options: [dev, test, prod]
  push:
    branches: [main]
    paths: ["infra/**"]
  pull_request:
    branches: [main]
    paths: ["infra/**"]

permissions:
  id-token: write
  contents: read
  pull-requests: write

env:
  # For push/PR events, always targets prod. workflow_dispatch uses inputs.stage.
  STAGE: ${{ inputs.stage || 'prod' }}
  RESOURCE_GROUP_NAME: rg-tfstate-eus-001
  # Must match terraform-backend.yml
  STORAGE_ACCOUNT_NAME: sttfstateiaceus001
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  ARM_USE_OIDC: "true"

jobs:
  validate:
    name: "Validate (${{ inputs.stage || 'prod' }})"
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: ./.github/actions/terraform-validate
        with:
          working-dir: ./infra/environments/${{ inputs.stage || 'prod' }}

  plan:
    name: "Plan (${{ inputs.stage || 'prod' }})"
    needs: validate
    runs-on: ubuntu-latest
    concurrency:
      group: plan-${{ inputs.stage || 'prod' }}
      cancel-in-progress: false
    outputs:
      plan-text: ${{ steps.plan.outputs.plan-text }}
    steps:
      - uses: actions/checkout@v4

      - name: Terraform Plan
        id: plan
        uses: ./.github/actions/terraform-plan
        with:
          working-dir: ./infra/environments/${{ inputs.stage || 'prod' }}
          azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
          azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          resource-group-name: ${{ env.RESOURCE_GROUP_NAME }}
          storage-account-name: ${{ env.STORAGE_ACCOUNT_NAME }}
          container-name: tfstate
          state-key: ${{ inputs.stage || 'prod' }}.tfstate
          stage: ${{ inputs.stage || 'prod' }}

      - name: Post Plan as PR Comment
        if: github.event_name == 'pull_request'
        uses: marocchino/sticky-pull-request-comment@v2
        with:
          header: terraform-plan-${{ inputs.stage || 'prod' }}
          message: |
            ## Terraform Plan — `${{ inputs.stage || 'prod' }}`

            <details><summary>Show Plan</summary>

            ```hcl
            ${{ steps.plan.outputs.plan-text }}
            ```

            </details>

            *Run: [`${{ github.run_number }}`](${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }})*

  apply:
    name: "Apply (${{ inputs.stage || 'prod' }})"
    needs: plan
    if: github.event_name != 'pull_request'
    runs-on: ubuntu-latest
    environment: ${{ inputs.stage || 'prod' }}
    concurrency:
      group: apply-${{ inputs.stage || 'prod' }}
      cancel-in-progress: false
    steps:
      - uses: actions/checkout@v4

      - uses: ./.github/actions/terraform-apply
        with:
          working-dir: ./infra/environments/${{ inputs.stage || 'prod' }}
          azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
          azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          storage-account-name: ${{ env.STORAGE_ACCOUNT_NAME }}
          stage: ${{ inputs.stage || 'prod' }}
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/terraform-deploy.yml
git commit -m "feat(ci): rewrite terraform-deploy — OIDC, PR comments, environment gates"
```

---

## Task 7: Fix `infra/environments/prod/backend.tf`

**Files:**
- Modify: `infra/environments/prod/backend.tf`

Remove the empty string values for `resource_group_name` and `storage_account_name`. Terraform's partial configuration requires these to be **absent** from the file so they can be passed via `-backend-config` flags. Leaving empty strings causes init to fail.

- [ ] **Step 1: Replace file content**

```hcl
# Partial backend configuration — resource_group_name and storage_account_name
# are injected at init time via -backend-config flags in CI (see terraform-plan action)
# or manually:
#   terraform init \
#     -backend-config="resource_group_name=rg-tfstate-eus-001" \
#     -backend-config="storage_account_name=sttfstateiaceus001"
terraform {
  backend "azurerm" {
    container_name = "tfstate"
    key            = "prod.tfstate"
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add infra/environments/prod/backend.tf
git commit -m "fix(terraform): remove empty backend config values — use partial config"
```

---

## Task 8: Documentation (delegate to @documenter)

**Files:**
- Create: `docs/terraform-cicd.md`

Instruct @documenter to write a guide covering:

1. **Overview** — how the pipeline works (backend bootstrap → validate → plan → apply)
2. **Prerequisites** — OIDC App Registration setup in Azure Entra ID with federated credentials for `main` branch and `pull_request`
3. **GitHub Secrets to configure** — `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
4. **GitHub Environments to create** — `prod` (and optionally `dev`, `test`) with required reviewers for the apply gate
5. **First-time setup steps** — run `terraform-backend.yml` first, then `terraform-deploy.yml`
6. **Storage account naming** — must be globally unique; where to change it (both workflow files, same value)
7. **Adding a new environment** — create `infra/environments/<stage>/` mirroring `prod/`, update `backend.tf` with `key = "<stage>.tfstate"`, add stage to workflow input `options`
8. **Local development** — how to run `terraform init` manually with `-backend-config` flags for local plan/apply outside CI

---

## Self-Review

**Spec coverage:**
- ✅ Best practices CI/CD: OIDC auth, composite actions, tfsec, environment gates, concurrency
- ✅ PR plan comments: sticky comment via `marocchino/sticky-pull-request-comment`
- ✅ Backend creation: `azure-backend` action + `terraform-backend.yml` workflow
- ✅ Backend configuration: partial config in `backend.tf`, `-backend-config` flags in plan action
- ✅ Plan/apply decoupled: tarball in blob storage keyed by `run_number`
- ✅ Documentation: Task 8 via @documenter

**Placeholder scan:** None found.

**Type consistency:**
- `inputs.stage || 'prod'` used consistently in both workflow files
- `STORAGE_ACCOUNT_NAME` env var named identically in both workflows — note to keep in sync
- `plan-${{ inputs.stage }}-${{ github.run_number }}.tar.gz` naming matches across plan and apply actions

**Gap found:** The `terraform-validate` action runs `terraform init -backend=false` which downloads the azurerm provider. For the `prod` environment, the provider version constraint is `~> 3.0` (in `provider.tf`). No issue — this is fine.

**Gap found:** The `plan` job output `plan-text` needs `terraform_wrapper: false` in setup-terraform (added) so `terraform show` stdout is captured cleanly without wrapper noise.
