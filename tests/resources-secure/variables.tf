variable "ibmcloud_api_key" {
  description = "IBM Cloud API key"
  type        = string
  sensitive   = true
}

variable "prefix" {
  description = "Prefix to add to all resources created by this module"
  type        = string
}

variable "region" {
  description = "IBM Cloud region where resources will be created"
  type        = string
  default     = "us-south"
}

variable "resource_group" {
  description = "Existing resource group name. If null, a new resource group will be created"
  type        = string
  default     = null
}

variable "resource_tags" {
  description = "List of tags to apply to resources"
  type        = list(string)
  default     = []
}