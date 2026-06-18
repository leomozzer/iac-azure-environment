terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = ">= 4.36.0"
      configuration_aliases = [azurerm.hub]
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.4"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
  }
}
