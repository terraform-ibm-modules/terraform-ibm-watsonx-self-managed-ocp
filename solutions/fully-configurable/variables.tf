variable "ibmcloud_api_key" {
  description = "The IBM Cloud API key to deploy resources."
  type        = string
  sensitive   = true
}

variable "prefix" {
  description = "A unique identifier for resources that is prepended to resources that are provisioned. Must begin with a lowercase letter and end with a lowercase letter or number. Must be 16 or fewer characters."
  type        = string
  default     = "cp4d"
  validation {
    error_message = "Prefix must begin with a letter and contain only lowercase letters, numbers, and - characters. Prefixes must end with a lowercase letter or number and be 16 or fewer characters."
    condition     = can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix)) && length(var.prefix) <= 16
  }
}

variable "region" {
  description = "Region where resources will be created. To find your VPC region, use `ibmcloud is regions` command to find available regions."
  type        = string
  nullable    = false
  default     = "us-south"
}

variable "code_engine_project_name" {
  description = "If `cloud_pak_deployer_image` is `null`, it will build the image with code engine and store it within a private ICR registry. Provide a name if you want to set the name. If not defined, default will be `{prefix}-cpd-{random-suffix}`."
  type        = string
  default     = null
}

variable "code_engine_project_id" {
  description = "If you want to use an existing project, you can pass the code engine project ID and the Cloud Pak Deployer build will be built within the existing project instead of creating a new one."
  type        = string
  default     = null
}

variable "cloud_pak_deployer_image" {
  description = "Cloud Pak Deployer image to use. If `null`, the image will be built using Code Engine."
  type        = string
  default     = "quay.io/cloud-pak-deployer/cloud-pak-deployer"
}

variable "cloud_pak_deployer_release" {
  description = "Release of Cloud Pak Deployer version to use. View releases at: https://github.com/IBM/cloud-pak-deployer/releases."
  type        = string
  default     = "v3.1.8"
}

variable "cloud_pak_deployer_secret" {
  description = "Secret for accessing the Cloud Pak Deployer image. If `null`, a default secret will be created # pragma: allowlist secret. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-watsonx-self-managed-ocp/tree/main/solutions/fully-configurable/DA-types.md)."
  type = object({
    username = string
    password = string
    server   = string
    email    = string
  })
  default = null
}

variable "existing_cluster_name" {
  description = "Name of an existing Red Hat OpenShift cluster to create and install watsonx onto."
  type        = string
}

variable "existing_resource_group_name" {
  description = "Resource group id of the cluster"
  type        = string
  validation {
    error_message = "`existing_resource_group_name` cannot be null if `existing_cluster_name` is not null."
    condition     = var.existing_cluster_name == null || var.existing_resource_group_name != null
  }
}

variable "install_odf_cluster_addon" {
  description = "Install the ODF cluster addon."
  type        = bool
  default     = true
  nullable    = false
}

variable "odf_version" {
  description = "Version of ODF to install."
  type        = string
  default     = "4.16.0"
  validation {
    error_message = "ODF version must be in the format 'x.y.z'."
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.odf_version))
  }
  nullable = false
}

variable "odf_config" {
  description = "Configuration for the ODF addon. Example add on options can be found [here](https://cloud.ibm.com/docs/openshift?topic=openshift-deploy-odf-classic&interface=cli#install-odf-cli-classic)"
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
  description = "When set to `true`, it is understood that the user has read the terms of the Cloud Pak license(s) and agrees to the terms outlined."
  type        = bool
  default     = true
  nullable    = false
}

variable "cpd_admin_password" {
  description = "Password for the Cloud Pak for Data admin user."
  sensitive   = true
  type        = string
  nullable    = false
  default     = "passw0rd" # pragma: allowlist secret
}

variable "cpd_entitlement_key" {
  description = "Cloud Pak for Data entitlement key for access to the IBM Entitled Registry. Can be fetched from https://myibm.ibm.com/products-services/containerlibrary."
  sensitive   = true
  type        = string
  nullable    = false
}

variable "cpd_version" {
  description = "Cloud Pak for Data version to install.  Only version 5.x.x is supported, latest versions can be found [here](https://www.ibm.com/docs/en/cloud-paks/cp-data?topic=versions-cloud-pak-data)."
  type        = string
  validation {
    error_message = "Cloud pak for data major version 5 is supported."
    condition     = split(".", var.cpd_version)[0] == "5"
  }
  default  = "5.0.3"
  nullable = false
}

#  Only used in the watsonx.ai offering flavour
variable "watsonx_ai_install" {
  description = "Determine whether the watsonx.ai cartridge for the deployer will be installed"
  type        = bool
  default     = false
  nullable    = false
}

#  Only used in the watsonx.ai offering flavour
variable "watsonx_ai_models" {
  description = "List of watsonx.ai models to install.  Information on the foundation models including pre-reqs can be found here - https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=install-foundation-models.  Use the ModelID as input"
  type        = list(string)
  default     = ["ibm-granite-13b-instruct-v2"]
  nullable    = false
}

#  Only used in the watsonx.data offering flavour
variable "watsonx_data_install" {
  description = "Determine whether the watsonx.data cartridge for the deployer will be installed"
  type        = bool
  default     = false
  nullable    = false
}

variable "watson_discovery_install" {
  description = "If watsonx.ai is being installed, also install watson discovery"
  type        = bool
  default     = false
  nullable    = false
}

variable "watson_assistant_install" {
  description = "If watsonx.ai is being installed, also install watson assistant"
  type        = bool
  default     = false
  nullable    = false
}
