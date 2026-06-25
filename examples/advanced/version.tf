terraform {
  required_version = ">= 1.3.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 2.1.0, < 3.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.1.0, < 4.0.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3.5, < 3.0.0"
    }
  }
}
