variable "cluster_name" {
  description = "Name of Red Hat OpenShift cluster to install watsonx onto"
  type        = string
}

variable "cpd_version" {
  default     = "5.1.1"
  description = "Cloud Pak for Data version to install"
  type        = string
}

variable "openshift_version" {
  default     = "4.16"
  description = "OpenShift version"
  type        = string
}
