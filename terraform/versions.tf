terraform {
  required_version = ">= 1.6.0"

  backend "local" {
    path = "state/sre-prr.tfstate"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16"
    }
  }
}
