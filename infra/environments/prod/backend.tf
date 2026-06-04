# Initialize with: terraform init \
#   -backend-config="resource_group_name=<rg>" \
#   -backend-config="storage_account_name=<sa>"
terraform {
  backend "azurerm" {
    resource_group_name  = ""
    storage_account_name = ""
    container_name       = "tfstate"
    key                  = "prod.tfstate"
  }
}
