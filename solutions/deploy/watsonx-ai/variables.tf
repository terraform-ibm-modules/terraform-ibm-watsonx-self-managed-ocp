variable "watsonx_ai_install" {
  default     = false
  description = "Determine whether the watsonx.ai cartridge for the deployer will be installed"
  type        = bool
}

variable "watsonx_ai_models" {
  default     = ["ibm-granite-13b-instruct-v2"]
  description = "List of watsonx.ai models to install.  Information on the foundation models including pre-reqs can be found here - https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=install-foundation-models.  Use the ModelID as input"
  type        = list(string)
}

variable "watson_discovery_install" {
  default     = false
  description = "If watsonx.ai is being installed, also install watson discovery"
  type        = bool
}

variable "watson_assistant_install" {
  default     = false
  description = "If watsonx.ai is being installed, also install watson assistant"
  type        = bool
}
