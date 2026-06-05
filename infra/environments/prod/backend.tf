# Partial backend configuration.
# resource_group_name and storage_account_name are injected at init time via -backend-config flags.
# In CI: see .github/actions/terraform-plan/action.yml (terraform init step).
# Locally:
#   terraform init \
#     -backend-config="resource_group_name=rg-tfstate-eus-001" \
#     -backend-config="storage_account_name=sttfstateiaceus001"
terraform {
  backend "azurerm" {
    container_name = "tfstate"
    key            = "prod.tfstate"
  }
}
