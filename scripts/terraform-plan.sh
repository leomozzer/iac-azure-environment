#!/bin/bash

environment=prod
varFile=$environment.tfvars
outputFile=$environment.plan
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
echo "Terraform plan completed"

az storage blob upload \
    --container-name $environment-tf-files \
    --file $outputFile \
    --name $outputFile \
    --account-name $STORAGE_ACCOUNT_NAME \
    --overwrite

az storage blob upload \
    --container-name $environment-tf-files \
    --file $environment.tfvars \
    --name $environment.tfvars \
    --account-name $STORAGE_ACCOUNT_NAME \
    --overwrite

# Optionally, you can print the plan to the console
# terraform show -json tfplan | jq '.'
