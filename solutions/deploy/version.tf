terraform {
  required_version = ">= 1.9.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.66.0, < 2.0.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3.4"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8.0, <3.0.0"
    }
  }
}
