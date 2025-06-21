terraform {
  required_version = ">= 1.9.0"
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "1.78.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3.4"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.1, < 4.0.0"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = "1.7.10"
    }
  }
}
