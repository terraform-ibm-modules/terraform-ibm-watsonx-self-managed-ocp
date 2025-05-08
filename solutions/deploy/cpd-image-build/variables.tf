variable "ibmcloud_api_key" {
  description = "The IBM Cloud API key to deploy resources."
  type        = string
  sensitive   = true
}

variable "prefix" {
  description = "The value that you would like to prefix to the name of the resources provisioned by this module. Explicitly set to null if you do not wish to use a prefix. This value is ignored if using one of the optional variables for explicit control over naming."
  type        = string
  default     = null
}

variable "region" {
  description = "Region where resources will be provisioned"
  type        = string
}

variable "resource_group" {
  description = "Resource groups to create or reference"
  type        = string
  default     = null
}

variable "resource_group_exists" {
  description = "Boolean value representing if the resource groups exists or not"
  type        = bool
  default     = false
}

variable "container_registry_namespace" {
  description = "The name of the container registry namespace"
  type        = string
  default     = null
}

variable "code_engine_project_name" {
  description = "The name of the code engine project to be created for the image build"
  type        = string
  default     = null
}

variable "code_engine_project_id" {
  description = "If you want to use an existing project, you can pass the code engine project id vs a new project being created."
  type        = string
  default     = null
}

variable "cloud_pak_deployer_release" {
  description = "The release of cloud pak deployer to build the image off of"
  type        = string
  default     = "latest"
}
