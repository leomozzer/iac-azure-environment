location=eastus
resourceGroup=rg-iac-azure
storageAccount=staciacazure

# Set the desired values for the backend configuration
RESOURCE_GROUP_NAME="rg-iac-azure"
STORAGE_ACCOUNT_NAME="staciacazure"
CONTAINER_NAME="states"
KEY="prod.tfstate"

cd ./terraform-live

az group create --location $location --resource-group $resourceGroup
az storage account create --resource-group $resourceGroup --name $storageAccount --sku Standard_LRS --kind StorageV2 --encryption-services blob --access-tier Cool --allow-blob-public-access false
az storage container create --name states --account-name $storageAccount
az storage container create --name plans --account-name $storageAccount
# 
az storage container create --name prod-tf-files --account-name $storageAccount

# Create the backend.tf file
cat <<EOL > backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "$RESOURCE_GROUP_NAME"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "$CONTAINER_NAME"
    key                  = "$KEY"
  }
}
EOL

echo "backend.tf file has been created with the specified configuration."

cat <<EOL > provider.tf
provider "azurerm" {
  features {

  }
}

provider "azurerm" {
  features {

  }
  alias           = "management"
  subscription_id = var.management_subscription_id
}
EOL

#Copy provider and backend file create locally to tffiles container
az storage blob upload \
    --container-name prod-tf-files \
    --file provider.tf \
    --name provider.tf \
    --account-name $storageAccount \
    --overwrite

az storage blob upload \
    --container-name prod-tf-files \
    --file backend.tf \
    --name backend.tf \
    --account-name $storageAccount \
    --overwrite