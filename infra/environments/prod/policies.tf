data "azurerm_management_group" "root" {
  name = "7147592f-487e-44bf-b6e6-bbea6c888e35"
}

module "allowed_regions" {
  source              = "gettek/policy-as-code/azurerm//modules/definition"
  version             = "2.8.0"
  policy_name         = "allowed_regions"
  display_name        = "Allow resources only in specific regions"
  policy_category     = "General"
  management_group_id = data.azurerm_management_group.root.id
}

module "org_mg_allowed_regions" {
  source            = "gettek/policy-as-code/azurerm//modules/def_assignment"
  version           = "2.8.0"
  definition        = module.allowed_regions.definition
  assignment_scope  = data.azurerm_management_group.root.id
  assignment_effect = "Deny"

  assignment_parameters = {
    listOfRegionsAllowed = [
      "East US",
      "West Europe",
      "Global"
    ]
  }
}
