terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=5.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  subscription_id = "1165b150-2a4e-4bde-b9eb-33d712eb910d"
  tenant_id       = "4b3dc399-1a2a-48c8-9b66-0535f356233c"
}