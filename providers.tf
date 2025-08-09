terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      # Avoid forced recovery path for non-existent soft-deleted vault names
      recover_soft_deleted_key_vaults = false
    }
  }
}

# Configure the Kubernetes provider to use kubeconfig
provider "kubernetes" {
  # Use kubeconfig written by: az aks get-credentials ...
  config_path = pathexpand("~/.kube/config")
}
