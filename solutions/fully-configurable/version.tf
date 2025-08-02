terraform {
  required_version = ">= 1.9.0"
  # Lock DA into an exact provider versions - renovate automation will keep it updated
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "1.81.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.5"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = "1.7.10"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}
