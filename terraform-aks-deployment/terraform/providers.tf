terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"  # Latest 3.x version (stable, no breaking changes)
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53"  # Latest 2.x version
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

  # Backend configuration for remote state
  # Uncomment and configure for production
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "stterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "aks.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }

  # Skip automatic provider registration (providers already registered manually)
  skip_provider_registration = true

  # Authentication handled by Azure CLI (certificate-based)
  # No credentials needed here when using az login
}

provider "azuread" {
  # Authentication handled by Azure DevOps service connection
}

