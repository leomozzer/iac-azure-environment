#!/bin/bash
WORKING_DIR=./terraform-live
ENVIRONMENT=prod
PLAN_FILE=$ENVIRONMENT.plan
STORAGE_ACCOUNT_NAME="staciacazure"

# Change to the Terraform directory
cd $WORKING_DIR

 az storage blob download \
          --file $PLAN_FILE \
          --name $PLAN_FILE \
          --account-name $STORAGE_ACCOUNT_NAME \
          --container-name $ENVIRONMENT-tf-files

 az storage blob download \
          --file $ENVIRONMENT.tfvars \
          --name $ENVIRONMENT.tfvars \
          --account-name $STORAGE_ACCOUNT_NAME \
          --container-name $ENVIRONMENT-tf-files

#https://stackoverflow.com/questions/70049758/terraform-for-each-one-by-one
TF_CLI_ARGS_apply="-parallelism=1"
# Run Terraform apply using the saved plan file
terraform apply $PLAN_FILE

# Provide feedback to the user
echo "Terraform apply completed."