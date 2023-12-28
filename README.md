# Terraform Templates
This repository will be used as base to start a new terraform project or even used as action to be invoked by a GitHub Action from any other repo

## Repo Folder Structure

```bash
📂.github
  └──📂actions
      └──📂azure-backend
          └──📜action.yaml
      └──📂terraform-apply
          └──📜action.yaml
      └──📂terraform-plan
          └──📜action.yaml
  └──📂workflows
      ├──📜audit.yml
      ├──📜terraform-apply.yml
      └──📜terraform-deploy.yml
      └──📜terraform-plan.yml
📂terraform-main
  ├──📜main.tf
  ├──📜outputs.tf
  └──📜variables.tf
📂terraform-modules
  └──📂module1
      ├──📜main.tf
      ├──📜outputs.tf
      └──📜variables.tf
```

## Configuration
- Create a new App Registration with a valid secret
- Grant owner permission to the App Registrato into the managment group were the subscriptions will be located
- Login in the App Registration in your device
- Check the [dev.tfvars](./terraform-live/dev.tfvars) and replace the required items. Also, you can rename it to another file like `prod.tfvars`
- Grant permissions to [terraform-backend.sh](./scripts/terraform-backend.sh) with `chmod +x .scripts/terraform-backend.sh `
- Run the bash command [terraform-backend.sh](./scripts/terraform-backend.sh)
- Grant permissions to [terraform-plan.sh](./scripts/terraform-plan.sh) with `chmod +x ./scripts/terraform-plan.sh `
  - If you're using the `dev.tfvars` or any other name diffrent from `prod.tfvars` file, change the value of variable `environment` in the script file
- Grant permissions to [terraform-apply.sh](./scripts/terraform-apply.sh) with `chmod +x ./scripts/terraform-apply.sh `
  - If you're using the `dev.tfvars` or any other name diffrent from `prod.tfvars` file, change the value of variable `environment` in the script file
- Run the bash command [terraform-plan.sh](./scripts/terraform-plan.sh) and check the output. If there's no issue run the next command. In case of issues check the output and fix them
- Run the bash command [terraform-apply.sh](./scripts/terraform-apply.sh)

## [Workflows](workflows)

Set or GitHub Actions Workflows to be used when handling with Terraform deployment
### [Audit](.github/workflows/audit.yml)