# Terraform Templates
This repository will be used as base to start a new terraform project or even used as action to be invoked by a GitHub Action from any other repo

## Repo Folder Structure

```bash
📂.github
  └──📂workflows
      └──📜terraform-deploy.yml
📂scripts
  ├──📜terraform-apply.tf
  ├──📜terraform-backend-local.tf
  ├──📜terraform-backend.tf
  ├──📜terraform-destoy.tf
  └──📜terraform-plan.tf
📂terraform-main
  ├──📜datasource.tf
  ├──📜general.tf
  ├──📜locals.tf
  ├──📜main.tf
  ├──📜management.tf
  ├──📜monitoring.tf
  ├──📜networking.tf
  ├──📜output.tf
  ├──📜policies.tf
  └──📜variables.tf
📂terraform-modules
  └──📂azapi
      └──📂peering-hub-spoke
          ├──📜main.tf
          ├──📜provider.tf
          └──📜variables.tf
      └──📂vnet
          ├──📜main.tf
          ├──📜outputs.tf
          ├──📜provider.tf
          └──📜variables.tf
```

## Configuration
- Create a new App Registration with a valid secret
- Grant owner permission to the App Registraton into the managment group were the subscriptions will be located
- Login in the App Registration in your device
- Check the [dev.tfvars](./terraform-live/dev.tfvars) and replace the required items. Also, you can rename it to another file like `prod.tfvars`
- Grant permissions to [terraform-backend.sh](./scripts/terraform-backend.sh) with `chmod +x .scripts/terraform-backend.sh `
- Replace the variables of the bash script `terraform-backend.sh` if needed
```bash
WORKING_DIR=./terraform-live
ENVIRONMENT=prod

# Set the desired values for the backend configuration
LOCATION=eastus
RESOURCE_GROUP_NAME="rg" #name of the resource group where the storage account with the state files will be saved
STORAGE_ACCOUNT_NAME="stac" #storage account where the state files will be saved
CONTAINER_NAME="states" #location optional
KEY="$ENVIRONMENT.tfstate"
```
- Run the bash command [terraform-backend.sh](./scripts/terraform-backend.sh)
- Grant permissions to [terraform-plan.sh](./scripts/terraform-plan.sh) with `chmod +x ./scripts/terraform-plan.sh `
  - If you're using the `dev.tfvars` or any other name diffrent from `prod.tfvars` file, change the value of variable `ENVIRONMENT` in the script file
  ```bash
  WORKING_DIR=./terraform-live
  ENVIRONMENT=prod
  STORAGE_ACCOUNT_NAME=stac #storage account where the state files will be saved

  VAR_FILE=$ENVIRONMENT.tfvars
  PLAN_FILE=$ENVIRONMENT.plan
  ```
- Grant permissions to [terraform-apply.sh](./scripts/terraform-apply.sh) with `chmod +x ./scripts/terraform-apply.sh `
  - If you're using the `dev.tfvars` or any other name diffrent from `prod.tfvars` file, change the value of variable `environment` in the script file
  ```bash
  WORKING_DIR=./terraform-live
  ENVIRONMENT=prod
  PLAN_FILE=$ENVIRONMENT.plan
  STORAGE_ACCOUNT_NAME=stac #storage account where the state files will be saved
  ```
- Run the bash command [terraform-plan.sh](./scripts/terraform-plan.sh) and check the output. If there's no issue run the next command. In case of issues check the output and fix them
- Run the bash command [terraform-apply.sh](./scripts/terraform-apply.sh)

## Workflows
### [terraform-deply-bash](.github/workflows/terraform-deply-bash.yml)
- When using this script to run the terraform, first replace the values of the following variables in the files:
  - [terraform-plan.sh](./scripts/terraform-plan.sh)
  ```bash
  WORKING_DIR=./terraform-live
  ENVIRONMENT=prod
  STORAGE_ACCOUNT_NAME=stac #storage account where the state files will be saved

  VAR_FILE=$ENVIRONMENT.tfvars
  PLAN_FILE=$ENVIRONMENT.plan
  ```

  - [terraform-apply.sh](./scripts/terraform-apply.sh)
  ```bash
  WORKING_DIR=./terraform-live
  ENVIRONMENT=prod
  PLAN_FILE=$ENVIRONMENT.plan
  STORAGE_ACCOUNT_NAME=stac #storage account where the state files will be saved
  ```
- Make sure that the secrets below are configured and available:
   - AZURE_SP
   - ARM_CLIENT_ID
   - ARM_CLIENT_SECRET
   - ARM_SUBSCRIPTION_ID
   - ARM_TENANT_ID