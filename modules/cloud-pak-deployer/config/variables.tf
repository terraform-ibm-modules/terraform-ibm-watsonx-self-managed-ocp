variable "cluster_name" {
  description = "Name of Red Hat OpenShift cluster to install watsonx onto"
  type        = string
}

variable "cpd_version" {
  default     = "5.1.1"
  description = "Cloud Pak for Data version to install.  Only version 5.x.x is supported, latest versions can be found [here](https://www.ibm.com/docs/en/cloud-paks/cp-data?topic=versions-cloud-pak-data)."
  type        = string
}

variable "openshift_version" {
  default     = "4.16"
  description = "OpenShift version"
  type        = string
}

variable "install_odf_cluster_addon" {
  description = "Whether ODF addon is being installed. When true, uses explicit 'odf' storage type instead of 'auto'."
  type        = bool
  default     = false
}
