#!/bin/bash

varFile=prod.tfvars
outputFile=prod.plan
STORAGE_ACCOUNT_NAME="staciacazure"

# Change to the Terraform directory
cd ./terraform-live

 az storage blob download \
          --file provider.tf \
          --name provider.tf \
          --account-name $STORAGE_ACCOUNT_NAME \
          --container-name prod-tf-files

 az storage blob download \
          --file backend.tf \
          --name backend.tf \
          --account-name $STORAGE_ACCOUNT_NAME \
          --container-name prod-tf-files

# Initialize Terraform (if not already initialized)
terraform init -reconfigure

#Run terraform formating
terraform fmt
# Run Terraform plan and save the output to a plan file
terraform plan -var-file=$varFile -out=$outputFile

# Optionally, you can print the plan to the console
# terraform show -json tfplan | jq '.'

# Provide feedback to the user
echo "Terraform plan completed. The plan file is saved as tfplan in the ./terraform-live directory."