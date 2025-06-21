terraform {
  required_version = ">= 1.2.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.1, < 4.0.0"
    }
  }
}
