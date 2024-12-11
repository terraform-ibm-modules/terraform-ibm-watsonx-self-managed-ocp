terraform {
  required_version = ">= 1.2.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.66.0, < 2.0.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = "1.18.2"
    }
  }
}
