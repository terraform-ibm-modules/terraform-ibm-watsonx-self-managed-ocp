variable "ibmcloud_api_key" {
  description = "APIkey that's associated with the account to use"
  type        = string
  sensitive   = true
}

variable "prefix" {
  description = "A unique identifier for resources that is prepended to resources that are provisioned. Must begin with a lowercase letter and end with a lowercase letter or number. Must be 16 or fewer characters."
  type        = string

  validation {
    error_message = "Prefix must begin and end with a letter and contain only letters, numbers, and - characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
  }
}

variable "region" {
  description = "Region where resources wills be created. To find your VPC region, use `ibmcloud is regions` command to find available regions."
  type        = string
}

variable "cloud_pak_deployer_image" {
  description = "Cloud Pak Deployer image location. If not defined, it will build the image via code engine"
  type        = string
  default     = null
}

variable "cloud_pak_deployer_release" {
  description = "Release of Cloud Pak Deployer version to use. View releases at: https://github.com/IBM/cloud-pak-deployer/releases."
  type        = string
  default     = "v3.1.1"
}

variable "cloud_pak_deployer_secret" {
  description = "Image pull secret for the cloud pak deployer image"
  type = object({
    username = string
    password = string
    server   = string
    email    = optional(string)
  })

  default = null
}

variable "cluster_name" {
  description = "Name of Red Hat OpenShift cluster to install watsonx onto"
  type        = string
}

variable "install_odf_cluster_addon" {
  description = "Install the odf cluster addon"
  type        = bool
  default     = true
}

variable "odf_version" {
  description = "Version of ODF to install"
  type        = string
  default     = "4.16.0"
}

variable "odf_config" {
  description = "Version of ODF to install"
  type        = map(string)
  default = {
    "odfDeploy"                       = "true"
    "workerNodes"                     = "all"
    "workerPool"                      = ""
    "resourceProfile"                 = "balanced"
    "billingType"                     = "essentials"
    "osdSize"                         = "512Gi"
    "osdStorageClassName"             = "ibmc-vpc-block-metro-10iops-tier"
    "numOfOsd"                        = "1"
    "ocsUpgrade"                      = "false"
    "enableNFS"                       = "false"
    "hpcsEncryption"                  = "false"
    "hpcsInstanceId"                  = ""
    "hpcsServiceName"                 = ""
    "hpcsSecretName"                  = ""
    "hpcsBaseUrl"                     = ""
    "hpcsTokenUrl"                    = ""
    "clusterEncryption"               = "false"
    "encryptionInTransit"             = "false"
    "addSingleReplicaPool"            = "false"
    "ignoreNoobaa"                    = "true"
    "disableNoobaaLB"                 = "false"
    "prepareForDisasterRecovery"      = "false"
    "useCephRBDAsDefaultStorageClass" = "false"
    "osdDevicePaths"                  = ""
    "taintNodes"                      = "false"
  }
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

variable "cpd_version" {
  description = "Cloud Pak for Data version to install.  Only version 5.x.x is supported"
  type        = string

  validation {
    error_message = "Cloud pak for data major version 5 is supported."
    condition     = split(".", var.cpd_version)[0] == "5"
  }

  default = "5.0.3"
}

#  Only used in the watsonx.ai offering flavour
variable "watsonx_ai_install" {
  description = "Determine whether the watsonx.ai cartridge for the deployer will be installed"
  type        = bool
  default     = false
}

#  Only used in the watsonx.ai offering flavour
variable "watsonx_ai_models" {
  description = "List of watsonx.ai models to install.  Information on the foundation models including pre-reqs can be found here - https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=install-foundation-models.  Use the ModelID as input"
  type        = list(string)
  default     = ["ibm-granite-13b-instruct-v2"]
}

#  Only used in the watsonx.data offering flavour
variable "watsonx_data_install" {
  description = "Determine whether the watsonx.data cartridge for the deployer will be installed"
  type        = bool
  default     = false
}

variable "watson_discovery_install" {
  description = "If watsonx.ai is being installed, also install watson discovery"
  type        = bool
  default     = false
}

variable "watson_assistant_install" {
  description = "If watsonx.ai is being installed, also install watson assistant"
  type        = bool
  default     = false
}

variable "wait_for_cpd_job_completion" {
  description = "Wait for the cloud-pak-deployer to complete before continuing"
  type        = bool
  default     = true
}
