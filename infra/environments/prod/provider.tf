terraform {
  required_version = ">= 1.12.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.36.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.4"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}

provider "azurerm" {
  alias           = "subscription_hub"
  subscription_id = var.hub_subscription_id
  features {}
}

provider "azapi" {
  alias           = "subscription_hub"
  subscription_id = var.hub_subscription_id
}

provider "azurerm" {
  alias           = "subscription_application"
  subscription_id = var.app_subscription_id
  features {}
}

provider "azapi" {
  alias           = "subscription_application"
  subscription_id = var.app_subscription_id
}

provider "azurerm" {
  alias           = "subscription_avd"
  subscription_id = var.avd_subscription_id
  features {}
}

provider "azapi" {
  alias           = "subscription_avd"
  subscription_id = var.avd_subscription_id
}
