##############################################################################
# Account Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = "The IBM Cloud API key to deploy resources."
  type        = string
  sensitive   = true
}

variable "prefix" {
  description = "A unique identifier for resources that is prepended to resources that are provisioned. Must begin with a lowercase letter and end with a lowercase letter or number. Must be 13 or fewer characters."
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
  default     = "au-syd"
}

variable "resource_tags" {
  type        = list(string)
  description = "List of resource tag to associate with all resource instances created by this example."
  default     = []
}

variable "install_odf_cluster_addon" {
  description = "Install the odf cluster addon"
  type        = bool
  default     = false
}

variable "existing_cluster_name" {
  description = "Existing cluster name"
  type        = string
  default     = null
}

variable "resource_group" {
  description = "Existing resource group name"
  type        = string
  default     = null
}
