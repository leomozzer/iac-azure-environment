#!/bin/bash
environment=prod
planFile=$environment.plan
STORAGE_ACCOUNT_NAME="staciacazure"

# Change to the Terraform directory
cd ./terraform-live

 az storage blob download \
          --file $planFile \
          --name $planFile \
          --account-name $STORAGE_ACCOUNT_NAME \
          --container-name $environment-tf-files

 az storage blob download \
          --file $environment.tfvars \
          --name $environment.tfvars \
          --account-name $STORAGE_ACCOUNT_NAME \
          --container-name $environment-tf-files

#https://stackoverflow.com/questions/70049758/terraform-for-each-one-by-one
TF_CLI_ARGS_apply="-parallelism=1"
# Run Terraform apply using the saved plan file
terraform apply $planFile

# Provide feedback to the user
echo "Terraform apply completed."