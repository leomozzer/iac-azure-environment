data "azurerm_management_group" "root" {
  name = var.root_management_group_name
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
