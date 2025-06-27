variable "ibmcloud_api_key" {
  description = "The IBM Cloud API key to deploy resources."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Region where Code Engine and Container Registry resources will be provisioned. To use the 'Global' Container Registry location set `use_global_container_registry_location` to true."
  type        = string
  default     = "us-south"
}

variable "resource_group_id" {
  type        = string
  description = "The ID of the resource group to create resource in. If not set, Default resource group will be used."
  default     = null
}

variable "use_global_container_registry_location" {
  description = "Set to true to create the Container Registry namespace in the 'Global' location. If set to false, the namespace will be created in the region provided in the `region` input value."
  type        = bool
  default     = false
}

variable "container_registry_namespace" {
  description = "The name of the Container Registry namespace to create. If `add_random_suffix_icr_namespace` is set to true, a randomly generated 4-character suffix will be added to this value."
  type        = string
  default     = "cpd"
}

variable "code_engine_project_name" {
  description = "The name of the Code Engine project to be created for the image build. Alternatively use `code_engine_project_id` to use existing project. If `add_random_suffix_code_engine_project` is set to true, a randomly generated 4-character suffix will be added to this value."
  type        = string
  default     = "cpd"
  validation {
    condition     = var.code_engine_project_name == null ? var.code_engine_project_id != null : true
    error_message = "A value must be passed for either 'code_engine_project_name' (to create new project) or 'code_engine_project_id' (to use existing project)."
  }
}

variable "code_engine_project_id" {
  description = "If you want to use an existing project, you can pass the Code Engine project ID. Alternatively use `code_engine_project_name` to create a new project."
  type        = string
  default     = null
}

variable "cloud_pak_deployer_release" {
  description = "The GIT release of Cloud Pak Deployer version to build from. View releases at: https://github.com/IBM/cloud-pak-deployer/releases."
  type        = string
  default     = "v3.1.8" # TODO: manage this version with renovate - https://github.com/terraform-ibm-modules/terraform-ibm-watsonx-self-managed-ocp/issues/36
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
