###############################################################################################
# Common inputs
###############################################################################################

variable "ibmcloud_api_key" {
  description = "The IBM Cloud API key to deploy resources."
  type        = string
  sensitive   = true
}

variable "cloud_pak_deployer_image" {
  description = "Cloud Pak Deployer image to use. If `null`, the image will be built using Code Engine and publish to a private Container Registry namespace."
  type        = string
  # TODO: update renovate to manage this version
  default = "quay.io/cloud-pak-deployer/cloud-pak-deployer:v3.2.1@sha256:311952546b0cbec425435269e9a1e7d8a4230dbcde6f257d1bd80461cb82f284"
}

variable "cluster_name" {
  description = "Name of an existing Red Hat OpenShift cluster to install watsonX onto"
  type        = string
}

variable "cluster_resource_group_id" {
  description = "The resource group ID of the cluster provided in `cluster_name`"
  type        = string
}

variable "cloud_pak_deployer_secret" {
  description = "Secret for accessing the Cloud Pak Deployer image. If `null`, a default secret will be created."
  type = object({
    username = string
    password = string
    server   = string
    email    = string
  })
  default = null
}

variable "cpd_accept_license" {
  description = "When set to 'true', it is understood that the user has read the terms of the Cloud Pak license(s) and agrees to the terms outlined."
  type        = bool
  default     = true
}

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

variable "cpd_version" {
  description = "Cloud Pak for Data version to install.  Only version 5.x.x is supported, latest versions can be found [here](https://www.ibm.com/docs/en/cloud-paks/cp-data?topic=versions-cloud-pak-data)."
  type        = string
  default     = "5.1.3"

  validation {
    error_message = "Cloud pak for data major version 5 is supported."
    condition     = split(".", var.cpd_version)[0] == "5"
  }
}

#  Only used in the watsonx.ai offering flavour
variable "watsonx_ai_install" {
  description = "Determine whether the watsonx.ai cartridge for the deployer will be installed"
  type        = bool
  default     = false
}

#  Only used in the watsonx.ai offering flavour
variable "watsonx_ai_models" {
  description = "List of watsonx.ai models to install. Information on the foundation models including pre-reqs can be found here - https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=install-foundation-models. Use the ModelID as input"
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

###############################################################################################
# ODF inputs
###############################################################################################

variable "install_odf_cluster_addon" {
  description = "Install the ODF cluster add-on."
  type        = bool
  default     = true
}

variable "odf_version" {
  description = "Version of OpenShift Data Foundation (ODF) add-on to install. Only applies if `install_odf_cluster_addon` is true."
  type        = string
  default     = "4.18.0"
}

variable "odf_config" {
  description = "Configuration for the ODF addon. Only applies if `install_odf_cluster_addon` is true."
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


###############################################################################################
# Below inputs are only used if building image (aka setting "cloud_pak_deployer_image" to null)
###############################################################################################

variable "resource_group_id" {
  type        = string
  description = "The ID of the resource group where Code Engine and Container Registry resources will be provisioned. Only applies if `cloud_pak_deployer_image` is `null`. If not set, Default resource group will be used."
  default     = null
}

variable "region" {
  description = "Region where Code Engine and Container Registry resources will be provisioned. Only applies if `cloud_pak_deployer_image` is `null`. To use the 'Global' Container Registry location set `use_global_container_registry_location` to true."
  type        = string
  default     = "us-south"
}

variable "use_global_container_registry_location" {
  description = "Set to true to create the Container Registry namespace in the 'Global' location. If set to false, the namespace will be created in the region provided in the `region` input value. Only applies if `cloud_pak_deployer_image` is `null`."
  type        = bool
  default     = false
}

variable "container_registry_namespace" {
  description = "The name of the Container Registry namespace to create. Only applies if `cloud_pak_deployer_image` is `null`. If `add_random_suffix_icr_namespace` is set to true, a randomly generated 4-character suffix will be added to this value."
  type        = string
  default     = "cpd"
}

variable "code_engine_project_name" {
  description = "The name of the Code Engine project to be created for the image build. Alternatively use `code_engine_project_id` to use existing project. Only applies if `cloud_pak_deployer_image` is `null`. If `add_random_suffix_code_engine_project` is set to true, a randomly generated 4-character suffix will be added to this value."
  type        = string
  default     = "cpd"
  validation {
    condition     = var.code_engine_project_name == null ? var.code_engine_project_id != null : true
    error_message = "A value must be passed for either 'code_engine_project_name' (to create new project) or 'code_engine_project_id' (to use existing project)."
  }
}

variable "code_engine_project_id" {
  description = "If you want to use an existing project, you can pass the Code Engine project ID. Alternatively use `code_engine_project_name` to create a new project. Only applies if `cloud_pak_deployer_image` is `null`."
  type        = string
  default     = null
}

variable "cloud_pak_deployer_release" {
  description = "The GIT release of Cloud Pak Deployer version to build from. Only applies if `cloud_pak_deployer_image` is `null`. View releases at: https://github.com/IBM/cloud-pak-deployer/releases."
  type        = string
  default     = "v3.2.1" # TODO: manage this version with renovate - https://github.com/terraform-ibm-modules/terraform-ibm-watsonx-self-managed-ocp/issues/36
}

variable "add_random_suffix_icr_namespace" {
  type        = bool
  description = "Whether to add a randomly generated 4-character suffix to the newly created ICR namespace."
  default     = true
}

variable "add_random_suffix_code_engine_project" {
  type        = bool
  description = "Whether to add a randomly generated 4-character suffix to the newly created Code Engine project. Only applies if `code_engine_project_id` is `null`."
  default     = true
}
