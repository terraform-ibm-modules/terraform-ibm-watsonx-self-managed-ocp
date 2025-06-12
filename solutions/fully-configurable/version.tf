terraform {
  required_version = ">= 1.9.0"
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "1.79.1"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3.4"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8.0, <3.0.0"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = "1.7.10"
    }
  }
}
