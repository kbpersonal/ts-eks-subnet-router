terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
    docker = {
      source = "kreuzwerker/docker"
      version = ">= 3.0.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.18"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = ">= 0.13.7"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "tailscale" {
  oauth_client_id        = local.oauth_client_id
  oauth_client_secret    = local.oauth_client_secret
}

provider "kubernetes" {
  host                    = local.aks_cluster_host
  cluster_ca_certificate   = local.aks_cluster_ca_certificate
  client_key              = local.aks_cluster_client_key
  client_certificate       = local.aks_cluster_client_certificate
}

provider "kubectl" {
  host                    = local.aks_cluster_host
  cluster_ca_certificate   = local.aks_cluster_ca_certificate
  client_key              = local.aks_cluster_client_key
  client_certificate       = local.aks_cluster_client_certificate
}

provider "helm" {
  kubernetes {
    host                    = local.aks_cluster_host
    cluster_ca_certificate   = local.aks_cluster_ca_certificate
    client_key              = local.aks_cluster_client_key
    client_certificate       = local.aks_cluster_client_certificate
  }
}

# Docker provider configuration using SSH to the Azure VM
provider "docker" {
  host     = "ssh://ubuntu@${local.azure_vm_client_public_ip}"
  # Unfortunately atm, we have no easy way to add host key to ~/.ssh/known_hosts for this provider to not complain and fail when connecting to our instance over SSH
  # So we disable host key checking to make it work. I REALLY hate this kind of bs with TF providers.
  ssh_opts = ["-i", "${local.ssh_private_key_path}", "-o", "StrictHostKeyChecking=no"]
}