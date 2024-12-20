variable "cloud_pak_deployer_config" {
  description = "Object definition of the Cloud Pak Deployer configuration"
  type        = any
}

variable "cloud_pak_deployer_image" {
  default     = null
  description = "The cloud pak deployer image location"
  type        = string
}

variable "cloud_pak_deployer_secret" {
  description = "Image pull secret for the cloud pak deployer image"
  type = object({
    username = string
    password = string
    server   = string
    email    = optional(string)
  })
  sensitive = true

  default = null
}


variable "cluster_name" {
  description = "Name of Red Hat OpenShift cluster to install watsonx onto"
  type        = string
}

variable "cpd_accept_license" {
  default     = false
  description = "When set to 'true', it is understood that the user has read the terms of the Cloud Pak license(s) and agrees to the terms outlined"
  type        = bool
}

variable "cpd_admin_password" {
  description = "Password to be used by the admin user to access the Cloud Pak for Data UI."
  sensitive   = true
  type        = string
}

variable "cpd_entitlement_key" {
  description = "Cloud Pak for Data entitlement key for access to the IBM Entitled Registry. Can be fetched from https://myibm.ibm.com/products-services/containerlibrary."
  sensitive   = true
  type        = string
}

variable "kube_config_path" {
  description = "Path to the kube config file being used"
  type        = string
}

variable "schematics_workspace" {
  description = "Object containing general information on the IBM Cloud Schematics Workspace this automation may be running on"
  type        = any
}

variable "wait_for_cpd_job_completion" {
  description = "Wait for the cloud-pak-deployer to complete before continuing"
  type        = bool
  default     = true
}
