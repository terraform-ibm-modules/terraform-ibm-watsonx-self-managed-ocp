variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API Key."
  sensitive   = true
}

variable "region" {
  type        = string
  description = "Region to provision all resources created by this example."
  default     = "us-south"
}

variable "prefix" {
  type        = string
  description = "Prefix to append to all resources created by this example."
  default     = "cp-da"
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources."
  default     = ["cp-ocp"]
}

variable "resource_group" {
  type        = string
  description = "The name of an existing resource group to provision resources in. If not specified, a new resource group is created with the `prefix` variable."
  default     = null
}
