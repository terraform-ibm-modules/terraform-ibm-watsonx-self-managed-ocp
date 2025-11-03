terraform {
  required_version = ">= 1.9.0"
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">=1.79.2, <2.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.3, < 4.0.0"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = ">= 1.7.10, <2.0.0"
    }
  }
}
