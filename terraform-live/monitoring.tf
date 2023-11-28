resource "azurerm_resource_group" "rg_monitoring" {
  provider = azurerm.management
  name     = local.rg_defaul_monitoring
  location = var.principal_location
}

resource "azurerm_monitor_action_group" "action_group_monitoring" {
  provider            = azurerm.management
  short_name          = "group"
  resource_group_name = azurerm_resource_group.rg_monitoring.name
  name                = "Default Action Group"
  email_receiver {
    name          = "default"
    email_address = var.management_monitoring_email
  }
}

resource "azurerm_monitor_metric_alert" "storage_account_alert" {
  provider            = azurerm.management
  for_each            = { for storage_accounts in local.filtered_storaged_accounts : storage_accounts.name => storage_accounts }
  name                = "${local.default_alerts["storage_account_avaliability"]["name"]} - ${each.value.name}"
  resource_group_name = azurerm_resource_group.rg_monitoring.name
  scopes              = [each.value.id]
  description         = local.default_alerts["storage_account_avaliability"]["description"]

  criteria {
    metric_namespace       = "Microsoft.Storage/storageaccounts"
    metric_name            = local.default_alerts["storage_account_avaliability"]["metrics"]["metric_name"]
    aggregation            = local.default_alerts["storage_account_avaliability"]["metrics"]["availability"]["time_aggregation"]
    operator               = local.default_alerts["storage_account_avaliability"]["metrics"]["availability"]["operator"]
    skip_metric_validation = local.default_alerts["storage_account_avaliability"]["metrics"]["availability"]["skip_metric_validation"]
    threshold              = local.default_alerts["storage_account_avaliability"]["metrics"]["availability"]["threshold"]
  }

  enabled     = local.default_alerts["storage_account_avaliability"]["metrics"]["enabled"]
  frequency   = local.default_alerts["storage_account_avaliability"]["metrics"]["evaluation_frequency"]
  severity    = local.default_alerts["storage_account_avaliability"]["metrics"]["severity"]
  window_size = local.default_alerts["storage_account_avaliability"]["metrics"]["window_size"]

  action {
    action_group_id = azurerm_monitor_action_group.action_group_monitoring.id
  }
}
