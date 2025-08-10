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

provider "kubernetes" {
  # Use local kubeconfig for authentication to AKS.
  # Ensure kubeconfig uses azurecli via: `kubelogin convert-kubeconfig -l azurecli`
  config_path    = "~/.kube/config"
  config_context = "optscale-aks-cluster-app"
}
