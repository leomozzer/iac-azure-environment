run "resource_group_eastus" {
  variables {
    purpose  = "operations"
    region   = "eastus"
    instance = "001"
  }

  assert {
    condition     = output.resource_group == "rg-operations-eus-001"
    error_message = "resource_group: got ${output.resource_group}"
  }
}

run "log_analytics_workspace_eastus" {
  variables {
    purpose  = "operations"
    region   = "eastus"
    instance = "001"
  }

  assert {
    condition     = output.log_analytics_workspace == "log-operations-eus-001"
    error_message = "log_analytics_workspace: got ${output.log_analytics_workspace}"
  }
}

run "virtual_network_eastus" {
  variables {
    purpose  = "networking"
    region   = "eastus"
    instance = "001"
  }

  assert {
    condition     = output.virtual_network == "vnet-networking-eus-001"
    error_message = "virtual_network: got ${output.virtual_network}"
  }
}

run "subnet_eastus" {
  variables {
    purpose  = "networking"
    region   = "eastus"
    instance = "001"
  }

  assert {
    condition     = output.subnet == "snet-networking-eus-001"
    error_message = "subnet: got ${output.subnet}"
  }
}

run "storage_account_strips_hyphens" {
  variables {
    purpose  = "operations"
    region   = "eastus"
    instance = "001"
  }

  assert {
    condition     = output.storage_account == "stoperationseus001"
    error_message = "storage_account: got ${output.storage_account}"
  }
}

run "recovery_services_vault_eastus" {
  variables {
    purpose  = "operations"
    region   = "eastus"
    instance = "001"
  }

  assert {
    condition     = output.recovery_services_vault == "rsv-operations-eus-001"
    error_message = "recovery_services_vault: got ${output.recovery_services_vault}"
  }
}

run "action_group_eastus" {
  variables {
    purpose  = "operations"
    region   = "eastus"
    instance = "001"
  }

  assert {
    condition     = output.action_group == "ag-operations-eus-001"
    error_message = "action_group: got ${output.action_group}"
  }
}

run "alert_rule_eastus" {
  variables {
    purpose  = "operations"
    region   = "eastus"
    instance = "001"
  }

  assert {
    condition     = output.alert_rule == "alr-operations-eus-001"
    error_message = "alert_rule: got ${output.alert_rule}"
  }
}

run "network_security_group_eastus" {
  variables {
    purpose  = "networking"
    region   = "eastus"
    instance = "001"
  }

  assert {
    condition     = output.network_security_group == "nsg-networking-eus-001"
    error_message = "network_security_group: got ${output.network_security_group}"
  }
}

run "vnet_peering_eastus" {
  variables {
    purpose  = "networking"
    region   = "eastus"
    instance = "001"
  }

  assert {
    condition     = output.vnet_peering == "peer-networking-eus-001"
    error_message = "vnet_peering: got ${output.vnet_peering}"
  }
}

run "nat_gateway_eastus" {
  variables {
    purpose  = "networking"
    region   = "eastus"
    instance = "001"
  }

  assert {
    condition     = output.nat_gateway == "ng-networking-eus-001"
    error_message = "nat_gateway: got ${output.nat_gateway}"
  }
}

run "westeurope_short_code" {
  variables {
    purpose  = "operations"
    region   = "westeurope"
    instance = "001"
  }

  assert {
    condition     = output.resource_group == "rg-operations-weu-001"
    error_message = "westeurope short code: got ${output.resource_group}"
  }
}

run "non_default_instance" {
  variables {
    purpose  = "operations"
    region   = "eastus"
    instance = "002"
  }

  assert {
    condition     = output.resource_group == "rg-operations-eus-002"
    error_message = "non_default_instance: got ${output.resource_group}"
  }
}
