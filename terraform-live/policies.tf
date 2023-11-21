
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
  remediation_scope      = data.azurerm_management_group.management_group.id

  assignment_parameters = {
    workspaceId    = azurerm_log_analytics_workspace.laws_operations.id
    metricsEnabled = true
    logsEnabled    = true
  }
}

###########################################
