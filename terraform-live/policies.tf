# resource "azurerm_resource_group" "rg_policies" {
#   name     = local.resource_group_name_policies
#   location = var.principal_location
# }

# resource "azurerm_user_assigned_identity" "umi_policies" {
#   name                = local.managed_identity_name
#   location            = var.principal_location
#   resource_group_name = azurerm_resource_group.rg_policies.name
# }

# resource "azurerm_role_assignment" "role_assigment_umi" {
#   scope                = data.azurerm_management_group.management_group.id
#   role_definition_name = "Contributor"
#   principal_id         = azurerm_user_assigned_identity.umi_policies.principal_id
# }


module "whitelist_regions" {
  source              = "gettek/policy-as-code/azurerm//modules/definition"
  version             = "2.8.0"
  policy_name         = "whitelist_regions"
  display_name        = "Allow resources only in whitelisted regions"
  policy_category     = "General"
  management_group_id = data.azurerm_management_group.management_group.id
}

module "org_mg_whitelist_regions" {
  source            = "gettek/policy-as-code/azurerm//modules/def_assignment"
  version           = "2.8.0"
  definition        = module.whitelist_regions.definition
  assignment_scope  = data.azurerm_management_group.management_group.id
  assignment_effect = "Deny"

  assignment_parameters = {
    listOfRegionsAllowed = [
      "East US",
      "Central US",
      "West Europe",
      "Global"
    ]
  }
}
###########################################
# Configure Diagnostic Settings Resources #
###########################################
module "key_vault_diagnostic_settings" {
  source              = "gettek/policy-as-code/azurerm//modules/definition"
  version             = "2.8.0"
  policy_name         = "deploy_keyvault_diagnostic_setting"
  display_name        = "Deploy Diagnostic Settings for KeyVaults to a Log Analytics workspace"
  policy_category     = "Monitoring"
  management_group_id = data.azurerm_management_group.management_group.id
}

module "vnet_diagnostic_settings" {
  source              = "gettek/policy-as-code/azurerm//modules/definition"
  version             = "2.8.0"
  policy_name         = "deploy_vnet_diagnostic_setting"
  display_name        = "Deploy Diagnostic Settings for Vnets to a Log Analytics workspace"
  policy_category     = "Monitoring"
  management_group_id = data.azurerm_management_group.management_group.id
}

module "platform_diagnostics_initiative" {
  source                  = "gettek/policy-as-code/azurerm//modules/initiative"
  initiative_name         = "platform_diagnostics_initiative"
  initiative_display_name = "[Monitoring]: Diagnostics Settings Policy Initiative"
  initiative_description  = "Collection of policies that deploy resource and activity log forwarders to logging core resources"
  initiative_category     = "Monitoring"
  management_group_id     = data.azurerm_management_group.management_group.id

  member_definitions = [
    module.key_vault_diagnostic_settings.definition,
    module.vnet_diagnostic_settings.definition
  ]
}

module "diagnostics_initiative" {
  source            = "gettek/policy-as-code/azurerm//modules/set_assignment"
  initiative        = module.platform_diagnostics_initiative.initiative
  assignment_scope  = data.azurerm_management_group.management_group.id
  assignment_effect = "DeployIfNotExists"

  # optional resource remediation inputs
  re_evaluate_compliance = false
  skip_remediation       = false
  skip_role_assignment   = false
  role_assignment_scope  = data.azurerm_management_group.management_group.id
  remediation_scope      = data.azurerm_management_group.management_group.id

  assignment_parameters = {
    workspaceId    = azurerm_log_analytics_workspace.laws_operations.id
    resourceGroup  = local.law_operations_name
    metricsEnabled = true
    logsEnabled    = true
  }
}

###########################################
#           Configure Tags                #
###########################################
module "definition_resource_group_tags" {
  source              = "gettek/policy-as-code/azurerm//modules/definition"
  version             = "2.8.0"
  policy_name         = "require_resource_group_tags"
  display_name        = "Resource groups must have tags"
  policy_category     = "Tags"
  management_group_id = data.azurerm_management_group.management_group.id
}

module "assignment_resource_group_tags" {
  source            = "gettek/policy-as-code/azurerm//modules/def_assignment"
  version           = "2.8.0"
  definition        = module.definition_resource_group_tags.definition
  assignment_scope  = data.azurerm_management_group.management_group.id
  assignment_effect = "Audit"
}

####################################
# Configure Storage Account Alerts #
####################################
module "storage_account_avaliability_alert" {
  source              = "gettek/policy-as-code/azurerm//modules/definition"
  version             = "2.8.0"
  policy_name         = "deploy_storageaccount_avaliability_alert"
  display_name        = "Deploy Storage Account Avaliability Alert"
  policy_category     = "Monitoring"
  management_group_id = data.azurerm_management_group.management_group.id
}

module "storage_account_monitoring_initiative" {
  source                  = "gettek/policy-as-code/azurerm//modules/initiative"
  initiative_name         = "storage_account_monitoring_initiative"
  initiative_display_name = "[Monitoring]: Storage Accounts"
  initiative_description  = "Collection of policies that deploy alerts over storage accounts"
  initiative_category     = "Monitoring"
  management_group_id     = data.azurerm_management_group.management_group.id

  member_definitions = [
    module.storage_account_avaliability_alert.definition,
  ]
}

module "storage_account_monitoring_assignment" {
  source            = "gettek/policy-as-code/azurerm//modules/set_assignment"
  initiative        = module.storage_account_monitoring_initiative.initiative
  assignment_scope  = data.azurerm_management_group.management_group.id
  assignment_effect = "DeployIfNotExists"

  # optional resource remediation inputs
  re_evaluate_compliance = false
  skip_remediation       = false
  skip_role_assignment   = false
  remediation_scope      = data.azurerm_management_group.management_group.id

  assignment_parameters = {
    actionGroupID = azurerm_monitor_action_group.azurerm_monitor_action_group.id
  }
}

# module "storage_account_avaliability_alert_assignment" {
#   source            = "gettek/policy-as-code/azurerm//modules/def_assignment"
#   version           = "2.8.0"
#   definition        = module.storage_account_avaliability_alert.definition
#   assignment_scope  = data.azurerm_management_group.management_group.id
#   assignment_effect = "DeployIfNotExists"

#   assignment_parameters = {
#     actionGroupID = azurerm_monitor_action_group.azurerm_monitor_action_group.id
#   }
# }
