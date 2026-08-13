terraform {
  required_version = ">= 1.9.0"
  # Lock DA into an exact provider versions - renovate automation will keep it updated
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "2.4.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.0"
    }
  }
}
