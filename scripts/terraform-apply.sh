#!/bin/bash

planFile=prod.plan

# Change to the Terraform directory
cd ./terraform-live

# Run Terraform apply using the saved plan file
terraform apply $planFile

# Provide feedback to the user
echo "Terraform apply completed."