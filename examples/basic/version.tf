terraform {
  required_version = ">= 1.3"
  required_providers {
    # renovate is set up to keep provider version at the latest for all DA solutions.
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "1.71.3"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1, < 1.0.0"
    }
  }
}
