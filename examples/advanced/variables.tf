##############################################################################
# Account Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = "The IBM Cloud API key to deploy resources."
  type        = string
  sensitive   = true
}

variable "prefix" {
  description = "A unique identifier for resources that is prepended to resources that are provisioned. Must begin with a lowercase letter and end with a lowercase letter or number. Must be 16 or fewer characters."
  type        = string
  default     = "ocp-cp4d"

  validation {
    error_message = "Prefix must begin with a letter and contain only lowercase letters, numbers, and - characters. Prefixes must end with a lowercase letter or number and be 16 or fewer characters."
    condition     = can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix)) && length(var.prefix) <= 16
  }
}

variable "region" {
  description = "Region where VPC will be created. To find your VPC region, use `ibmcloud is regions` command to find available regions."
  type        = string
  default     = "us-south"
}

variable "resource_tags" {
  type        = list(string)
  description = "List of resource tags to associate with all resource instances created by this example."
  default     = []
}

variable "resource_group" {
  type        = string
  description = "The name of an existing resource group to provision resources in to. If not set a new resource group will be created using the prefix variable."
  default     = null
}

##############################################################################
# Cluster Variables
##############################################################################

variable "existing_cluster_name" {
  description = "Name of an existing Red Hat OpenShift cluster to install watsonx onto. If not provided, a new cluster will be created."
  type        = string
  default     = null
}

variable "create_public_gateway" {
  description = "Set to true to create a public gateway for the VPC subnet. Set to false for a secure private-only configuration."
  type        = bool
  default     = true
}

variable "disable_outbound_traffic_protection" {
  description = "Set to true to disable outbound traffic protection. Required when using Code Engine to build images in private clusters."
  type        = bool
  default     = true
}

##############################################################################
# Cloud Pak for Data Variables
##############################################################################

variable "cpd_admin_password" {
  description = "Password for the Cloud Pak for Data admin user."
  sensitive   = true
  type        = string
}

variable "cpd_entitlement_key" {
  description = "Cloud Pak for Data entitlement key for access to the IBM Entitled Registry. Can be fetched from https://myibm.ibm.com/products-services/containerlibrary."
  sensitive   = true
  type        = string
}

##############################################################################
# Cloud Pak Deployer Image Variables
##############################################################################

variable "cloud_pak_deployer_image" {
  description = "Cloud Pak Deployer image to use. Set to null to trigger automatic image build using Code Engine and publish to IBM Container Registry."
  type        = string
  default     = "quay.io/cloud-pak-deployer/cloud-pak-deployer:v3.3.6@sha256:85df0250395085b4115e751be37937ac0675201929dc22e6e4e41446dff84359"
}

variable "cloud_pak_deployer_secret" {
  description = "Secret for accessing the Cloud Pak Deployer image. If null, a default secret will be created."
  type = object({
    username = string
    password = string
    server   = string
    email    = string
  })
  default = null
}

##############################################################################
# WatsonX Service Variables
##############################################################################

variable "watsonx_ai_install" {
  description = "Enable watsonx.ai installation"
  type        = bool
  default     = false
}

variable "watsonx_data_install" {
  description = "Enable watsonx.data installation"
  type        = bool
  default     = false
}

variable "watson_assistant_install" {
  description = "Enable Watson Assistant installation"
  type        = bool
  default     = false
}

variable "watson_discovery_install" {
  description = "Enable Watson Discovery installation"
  type        = bool
  default     = false
}