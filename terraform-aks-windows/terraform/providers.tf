terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116" # Latest 3.x version (stable)
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    nirmata = {
      source  = "nirmata/nirmata"
      version = "~> 1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

  # Backend configuration for remote state (optional)
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "stterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "aks-windows.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  # Skip automatic provider registration (providers already registered)
  skip_provider_registration = true

  # Authentication handled by Azure CLI (certificate-based)
  # No credentials needed here
}

provider "azuread" {
  # Authentication handled by Azure CLI
}

provider "random" {
  # No configuration needed
}

