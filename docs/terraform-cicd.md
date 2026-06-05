# Terraform CI/CD Pipeline Setup Guide

This guide covers the Terraform CI/CD pipeline that automates infrastructure validation, planning, and deployment to Azure using GitHub Actions and OpenID Connect (OIDC) authentication.

## 1. Overview

The Terraform CI/CD pipeline automates infrastructure changes through three phases:

1. **Validate** — Format checks, Terraform validation, and security scanning (no backend required)
2. **Plan** — Initialize Terraform with backend config, plan changes, upload plan artifact to Azure Blob Storage
3. **Apply** — Download pre-approved plan and apply changes to Azure

### Pipeline Triggers

- **Pull Request (PR)** → Validate + Plan (no apply, comment on PR with plan)
- **Push to `main`** → Validate + Plan + Apply (requires environment approval)
- **Manual Dispatch** → Any stage (dev/test/prod), any phase (validate/plan/apply)

### Pipeline Diagram

```
GitHub Event
    │
    ├─ PR to main ──────────────────────────────────────┐
    │                                                    │
    ├─ Push to main ────────────────────────────────────┤
    │                                                    │
    └─ workflow_dispatch (manual) ──────────────────────┘
                    │
                    v
            ┌──────────────┐
            │   Validate   │  (fmt, validate, tfsec)
            └──────────────┘
                    │
                    v
            ┌──────────────┐
            │     Plan     │  (init, plan, upload)
            └──────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
        v                       v
    (PR only)             (push/dispatch)
    Comment PR            Approval Gate
        │                       │
        │                       v
        │                ┌──────────────┐
        └───────────────→│     Apply    │  (download, apply)
                         └──────────────┘
                                 │
                                 v
                            Azure Resources
```

## 2. Authentication — OIDC Setup (One-Time)

Azure OIDC authentication eliminates the need to manage service principal secrets. GitHub's OIDC token is exchanged directly for an Azure access token.

### Step 1: Create App Registration in Azure Entra ID

1. Go to [Azure Portal](https://portal.azure.com) → **Azure Entra ID** → **App registrations** → **New registration**
2. Enter a name (e.g., `terraform-cicd-iac`)
3. Leave **Supported account types** as default (single tenant)
4. Click **Register**
5. Note the **Application (client) ID** and **Directory (tenant) ID** — you'll need these later

### Step 2: Grant Azure Role

1. In the Azure Portal, navigate to **Subscriptions** → select your subscription
2. Click **Access control (IAM)** → **Add** → **Add role assignment**
3. Select role **Contributor** (or a more restrictive role if you manage only specific resource groups)
4. Assign to: select the app registration you just created
5. Click **Save**

### Step 3: Add Federated Credentials

In your app registration, go to **Certificates & secrets** → **Federated credentials** → **Add credential**.

Create **three** separate credentials:

#### Credential 1: Pull Requests (plan-only)
- **Federated credential scenario** → `GitHub Actions deploying Azure resources`
- **Organization** → your GitHub username/org name
- **Repository** → `iac-azure-environment`
- **Entity type** → `Pull request`
- **Name** → `terraform-pr-plan`

#### Credential 2: Push to main (apply)
- **Federated credential scenario** → `GitHub Actions deploying Azure resources`
- **Organization** → your GitHub username/org name
- **Repository** → `iac-azure-environment`
- **Entity type** → `Branch`
- **Branch name** → `main`
- **Name** → `terraform-main-apply`

#### Credential 3: Manual Dispatch
- **Federated credential scenario** → `GitHub Actions deploying Azure resources`
- **Organization** → your GitHub username/org name
- **Repository** → `iac-azure-environment`
- **Entity type** → `Branch`
- **Branch name** → `main`
- **Name** → `terraform-dispatch`

(Note: Credential 2 and 3 can share the same credential — all non-PR triggers use the same auth context.)

### Step 4: Add GitHub Secrets

In your GitHub repository, go to **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.

Create three secrets:

| Secret | Value | Where to find it |
|--------|-------|------------------|
| `AZURE_CLIENT_ID` | Application (client) ID | App registration → Overview |
| `AZURE_TENANT_ID` | Directory (tenant) ID | App registration → Overview |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID | Azure Subscriptions → Properties |

## 3. GitHub Environments Setup

GitHub Environments provide a gate for production deployments. The `apply` job in the Terraform Deploy workflow requires approval before running.

### Create the `prod` Environment

1. Go to **Settings** → **Environments** → **New environment**
2. Enter name: `prod`
3. Under **Deployment branches**, select **Selected branches** → **Add deployment branch** → select `main`
4. Click **Create environment**

### Add Required Reviewers (Approval Gate)

1. In the `prod` environment, scroll to **Required reviewers**
2. Check **Require reviews before deploying to this environment**
3. Add one or more GitHub users or teams who must approve apply jobs
4. Click **Save protection rules**

**Why this matters:** When a push or manual dispatch targets `prod`, the `apply` job will pause and wait for an approved reviewer to click the green "Approve and deploy" button in the Actions tab.

### Optional: Create `dev` and `test` Environments

Repeat the above steps to create `dev` and `test` environments if needed. You do not need to add required reviewers for non-prod environments.

## 4. First-Time Setup

Follow this exact sequence:

### 1. Configure OIDC (Section 2)
- Create app registration
- Grant Contributor role
- Add three federated credentials
- Create three GitHub secrets

### 2. Configure GitHub Environments (Section 3)
- Create `prod` environment
- Add required reviewers

### 3. Update Storage Account Name (if desired)

The current storage account name is `sttfstateiaceus001` (defined in `.github/workflows/terraform-backend.yml` and `.github/workflows/terraform-deploy.yml`).

This name **must be globally unique** across all Azure accounts. If the name is taken, choose a new name:
- Lowercase alphanumeric only
- Max 24 characters
- No hyphens or underscores

**Update both files:**

`.github/workflows/terraform-backend.yml` — line 23:
```yaml
STORAGE_ACCOUNT_NAME: sttfstateiaceus001
```

`.github/workflows/terraform-deploy.yml` — line 27:
```yaml
STORAGE_ACCOUNT_NAME: sttfstateiaceus001
```

### 4. Run Backend Bootstrap Workflow

1. Go to GitHub repository → **Actions** → select **`0 - Terraform Backend`** workflow
2. Click **Run workflow**
3. Select stage: `prod` (for your primary deployment)
4. Click **Run workflow**
5. Wait for the job to complete (2–3 minutes)

**What it does:**
- Creates resource group `rg-tfstate-eus-001`
- Creates storage account `sttfstateiaceus001`
- Enables blob versioning and soft delete (30-day retention)
- Creates containers: `tfstate` (state files) and `plans` (plan artifacts)

### 5. Verify in Azure

In the Azure Portal, check that:
- Resource group `rg-tfstate-eus-001` exists
- Storage account `sttfstateiaceus001` exists in that RG
- Containers `tfstate` and `plans` are present
- Blob versioning is enabled

### 6. Test the Deployment Pipeline

Open a pull request with a change to `infra/environments/prod/` (e.g., add a comment):

```hcl
# infra/environments/prod/main.tf
# Test PR comment
```

Push the branch and create the PR. Within seconds, the Terraform Deploy workflow should:
1. Run **Validate**
2. Run **Plan** and comment on your PR with the plan output

If the comment appears, the pipeline is working. Merge the PR (no deploy happens on PR merge because `apply` doesn't run for PRs).

### 7. Test the Apply Job

On the `main` branch, make a small change and push:

```bash
git checkout main
git pull origin main
# Make a change
git add infra/
git commit -m "test: small terraform change"
git push origin main
```

Go to GitHub Actions and watch the Terraform Deploy workflow:
1. It will run **Validate** and **Plan**
2. It will pause at **Apply** waiting for approval
3. Go to the workflow run → click the **Review deployments** button
4. Select approvers and click **Approve and deploy**
5. The **Apply** job will start and apply changes to Azure

## 5. Storage Account Naming

The storage account name is critical — it must be globally unique across **all Azure customers**.

### Current Value

```
sttfstateiaceus001
```

| Part | Meaning |
|------|---------|
| `st` | Azure naming prefix (Storage account) |
| `tfstate` | Purpose (Terraform state) |
| `iac` | Project identifier |
| `eus` | Region short code (East US) |
| `001` | Instance number |

### If Name Is Taken

If you see an error during backend bootstrap:

```
Code: StorageAccountAlreadyTaken
Message: The storage account named 'sttfstateiaceus001' is already taken.
```

1. Choose a new name (e.g., `stiaceustate001`)
2. Update `.github/workflows/terraform-backend.yml` (line 23)
3. Update `.github/workflows/terraform-deploy.yml` (line 27)
4. Re-run the backend bootstrap workflow

## 6. Adding a New Environment (dev/test)

To add a new environment alongside prod, follow this pattern:

### Step 1: Create Environment Directory

```bash
cp -r infra/environments/prod infra/environments/dev
```

### Step 2: Update Backend Config

Edit `infra/environments/dev/backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    container_name = "tfstate"
    key            = "dev.tfstate"  # Change this key
  }
}
```

The key must be unique per environment (e.g., `dev.tfstate`, `test.tfstate`, `prod.tfstate`).

### Step 3: Create GitHub Environment

In your repository:
1. **Settings** → **Environments** → **New environment**
2. Enter name: `dev`
3. (Optional) Add required reviewers

### Step 4: No Workflow Changes Needed

The workflows already support arbitrary stage names via `workflow_dispatch` input. When you run a manual dispatch and select `dev`, it will:
- Use `infra/environments/dev/`
- Use `dev.tfstate` key
- Require approval from the `dev` environment (if you added required reviewers)

## 7. Local Development

To run Terraform locally during development:

### Prerequisites

Ensure you are authenticated to Azure:

```bash
az login
```

Or set these environment variables for headless auth:

```bash
export ARM_CLIENT_ID="<application-client-id>"
export ARM_CLIENT_SECRET="<client-secret>"  # Not recommended for long-term
export ARM_TENANT_ID="<tenant-id>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
```

(OIDC works in CI but local runs typically use a service principal secret.)

### Initialize Terraform

```bash
cd infra/environments/prod
terraform init \
  -backend-config="resource_group_name=rg-tfstate-eus-001" \
  -backend-config="storage_account_name=sttfstateiaceus001" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=prod.tfstate"
```

### Plan Changes

```bash
terraform plan -out=tfplan
```

### Apply Changes

```bash
terraform apply tfplan
```

### Switching Environments

To work on the dev environment:

```bash
cd ../dev
terraform init \
  -backend-config="resource_group_name=rg-tfstate-eus-001" \
  -backend-config="storage_account_name=sttfstateiaceus001" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev.tfstate"
terraform plan
```

Note: The `-reconfigure` flag in CI's `terraform init` re-initializes the backend if it changes.

## 8. Troubleshooting

### "The storage account named X is already taken"

The storage account name is not available. Choose a new name and update both workflow files (see Section 5).

### "OIDC token request failed" or "Unauthorized"

Check:
1. App registration exists and has **Contributor** role on subscription
2. Federated credentials exist (three separate credentials for PR, push, dispatch)
3. GitHub secrets (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`) are set
4. Branch being deployed matches the federated credential (e.g., branch `main` for push/dispatch scenarios)

### Plan comment is not appearing on PR

Check:
1. GitHub Actions workflow has `pull-requests: write` permission (line 22 of `terraform-deploy.yml`)
2. The Validate and Plan jobs passed
3. The sticky-pull-request-comment action ran (check job logs)

### Apply job is stuck waiting for approval

This is expected if a required reviewer is set on the `prod` environment. Approve the deployment:
1. Go to the workflow run in Actions
2. Click **Review deployments**
3. Select your GitHub user/team and click **Approve and deploy**

### Terraform state lock timeout

If Terraform is waiting for a lock longer than 10 minutes:

```
Error: resource tainted or locked for too long
```

Manually inspect the state lock in Azure Blob Storage:
1. Go to storage account → Blob containers → `tfstate`
2. Download the `.terraform.lock.hcl` file (if present)
3. If the lock is stale, delete it and retry

## 9. Best Practices

- **Always use PRs** for non-emergency changes — they provide a safe testing ground via plan-only validation
- **Review the plan** before approving the apply job — unexpected changes might indicate a bug
- **Pin the Terraform version** in `.github/actions/terraform-validate/action.yml` to avoid surprises
- **Use state locking** — the backend is configured with blob leasing to prevent concurrent applies
- **Archive state backups** — Azure Blob versioning (enabled automatically) retains 30 days of history
- **Limit app registration permissions** — Contributor is broad; consider custom roles for read-only deployments
- **Rotate federated credentials** annually — review OIDC trust relationships in Azure Entra ID
