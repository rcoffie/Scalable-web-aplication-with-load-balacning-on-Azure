# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.11.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  #   resource_provider_registrations = "none" # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
  subscription_id = "d23c01fa-5060-43cd-a999-9dd91ef91994"
}
