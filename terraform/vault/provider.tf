terraform {
  required_version = ">= 0.13.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.17.0"
    }
    vaultoperator = {
      source = "rickardgranberg/vaultoperator"
      version = "0.1.3"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.66.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "3.1.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.4.1"
    }
    random = {
      version = "~> 3.1.0"
    }
    local = {
      version = "~> 2.1.0"
    }
    null = {
      version = "~> 3.1.0"
    }
    external = {
      source = "hashicorp/external"
      version = "2.2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.13.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "random" {}

provider "tls" {}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = var.kubectl_ctx
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = var.kubectl_ctx
  }
}
