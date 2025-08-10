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
  host                   = "https://optscale-aks-app-h9m1bdj6.b14368d4-3bae-4c83-8ff6-9c53bfcfd791.privatelink.eastus.azmk8s.io"
  token                  = "<your-token>"
  cluster_ca_certificate = "<your-cluster-ca-certificate>"
}
