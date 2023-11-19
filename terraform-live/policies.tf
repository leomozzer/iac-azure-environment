
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

module "key_vault_diagnostic_settings" {
  source              = "gettek/policy-as-code/azurerm//modules/definition"
  version             = "2.8.0"
  policy_name         = "deploy_keyvault_diagnostic_setting"
  display_name        = "Deploy Diagnostic Settings for KeyVaults to a Log Analytics workspace"
  policy_category     = "Monitoring"
  management_group_id = data.azurerm_management_group.management_group.id
}

module "key_vault_diagnostic_settings_assignment" {
  depends_on        = [azurerm_log_analytics_workspace.laws_operations]
  source            = "gettek/policy-as-code/azurerm//modules/def_assignment"
  version           = "2.8.0"
  definition        = module.key_vault_diagnostic_settings.definition
  assignment_scope  = data.azurerm_management_group.management_group.id
  assignment_effect = "DeployIfNotExists"
  assignment_parameters = {
    logAnalyticsId = azurerm_log_analytics_workspace.laws_operations.id
  }
}

# module "subscription_definition" {
#   source  = "gettek/policy-as-code/azurerm//modules/definition"
#   version = "2.8.0"
#   for_each = {
#     for index, definition in var.policy_definitions : definition.name => definition
#   }
#   policy_name         = each.value.file_name
#   display_name        = (jsondecode(file("../policies/${each.value.category}/${each.value.file_name}.json"))).properties.displayName
#   policy_description  = (jsondecode(file("../policies/${each.value.category}/${each.value.file_name}.json"))).properties.description
#   policy_category     = (jsondecode(file("../policies/${each.value.category}/${each.value.file_name}.json"))).properties.metadata.category
#   policy_version      = (jsondecode(file("../policies/${each.value.category}/${each.value.file_name}.json"))).properties.metadata.version
#   management_group_id = data.azurerm_management_group.management_group.id
#   policy_rule         = (jsondecode(file("../policies/${each.value.category}/${each.value.file_name}.json"))).properties.policyRule
#   policy_parameters   = (jsondecode(file("../policies/${each.value.category}/${each.value.file_name}.json"))).properties.parameters
#   policy_metadata     = (jsondecode(file("../policies/${each.value.category}/${each.value.file_name}.json"))).properties.metadata
# }

# module "configure_initiative" {
#   source  = "gettek/policy-as-code/azurerm//modules/initiative"
#   version = "2.8.0"
#   for_each = {
#     for key, initiative in local.initiative_list : key => initiative
#   }
#   initiative_name         = each.value["initiative"]["initiative_name"]
#   initiative_display_name = "${each.value["initiative"]["initiative_category"]}: ${each.value["initiative"]["initiative_display_name"]}"
#   initiative_description  = each.value["initiative"]["initiative_description"]
#   initiative_category     = each.value["initiative"]["initiative_category"]
#   management_group_id     = data.azurerm_management_group.management_group.id

#   member_definitions = each.value["initiative"]["definitions"]
# }

# module "initiative_assignment" {
#   source  = "gettek/policy-as-code/azurerm//modules/set_assignment"
#   version = "2.8.0"
#   for_each = {
#     for key, initiative in local.initiative_list : key => initiative
#   }
#   initiative        = module.configure_initiative[each.value["initiative"]["module_index"]].initiative
#   assignment_scope  = data.azurerm_management_group.management_group.id
#   assignment_effect = each.value["initiative"]["assignment_effect"]

#   # resource remediation options
#   skip_role_assignment   = each.value["initiative"]["skip_role_assignment"]
#   skip_remediation       = each.value["initiative"]["skip_remediation"]
#   re_evaluate_compliance = each.value["initiative"]["re_evaluate_compliance"]
# }
