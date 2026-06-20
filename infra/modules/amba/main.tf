data "azapi_client_config" "current" {}

module "naming" {
  source   = "../naming"
  purpose  = "amba"
  region   = var.region
  instance = var.instance
}

module "amba_alz" {
  source  = "Azure/avm-ptn-monitoring-amba-alz/azurerm"
  version = "0.3.0"

  location                            = var.region
  root_management_group_name          = var.root_management_group_name
  resource_group_name                 = module.naming.resource_group
  user_assigned_managed_identity_name = var.user_assigned_managed_identity_name
  tags                                = var.tags

  retries = {
    role_assignments = {
      error_message_regex  = ["AuthorizationFailed", "ResourceNotFound"]
      interval_seconds     = 5
      max_interval_seconds = 30
    }
  }

  timeouts = {
    role_assignment = {
      create = "15m"
      update = "15m"
    }
  }
}

module "amba_policy" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "0.12.0"

  architecture_name  = "amba"
  location           = var.region
  parent_resource_id = data.azapi_client_config.current.tenant_id

  policy_default_values = {
    amba_alz_management_subscription_id            = jsonencode({ value = var.management_subscription_id != "" ? var.management_subscription_id : data.azapi_client_config.current.subscription_id })
    amba_alz_resource_group_location               = jsonencode({ value = var.region })
    amba_alz_resource_group_name                   = jsonencode({ value = module.naming.resource_group })
    amba_alz_resource_group_tags                   = jsonencode({ value = var.tags })
    amba_alz_user_assigned_managed_identity_name   = jsonencode({ value = var.user_assigned_managed_identity_name })
    amba_alz_byo_user_assigned_managed_identity_id = jsonencode({ value = "" })
    amba_alz_disable_tag_name                      = jsonencode({ value = var.amba_disable_tag_name })
    amba_alz_disable_tag_values                    = jsonencode({ value = var.amba_disable_tag_values })
    amba_alz_action_group_email                    = jsonencode({ value = var.action_group_email })
    amba_alz_arm_role_id                           = jsonencode({ value = [] })
    amba_alz_webhook_service_uri                   = jsonencode({ value = [] })
    amba_alz_event_hub_resource_id                 = jsonencode({ value = [] })
    amba_alz_function_resource_id                  = jsonencode({ value = "" })
    amba_alz_function_trigger_url                  = jsonencode({ value = "" })
    amba_alz_logicapp_resource_id                  = jsonencode({ value = "" })
    amba_alz_logicapp_callback_url                 = jsonencode({ value = "" })
    amba_alz_byo_alert_processing_rule             = jsonencode({ value = "" })
    amba_alz_byo_action_group                      = jsonencode({ value = [] })
  }
}
