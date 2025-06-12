##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.2.0"
  existing_resource_group_name = var.existing_resource_group_name
}


########################################################################################################################
# Watsonx Self Managed OCP module
########################################################################################################################

module "watsonx_self_managed_ocp" {
  source                     = "../.."
  prefix                     = var.prefix
  ibmcloud_api_key           = var.ibmcloud_api_key
  region                     = var.region
  resource_group             = module.resource_group.resource_group_id
  code_engine_project_name   = var.code_engine_project_name
  code_engine_project_id     = var.code_engine_project_id
  cloud_pak_deployer_image   = var.cloud_pak_deployer_image
  cloud_pak_deployer_release = var.cloud_pak_deployer_release
  cloud_pak_deployer_secret  = var.cloud_pak_deployer_secret
  cluster_name               = var.existing_cluster_name
  cluster_rg_id              = module.resource_group.resource_group_id
  install_odf_cluster_addon  = var.install_odf_cluster_addon
  odf_version                = var.odf_version
  odf_config                 = var.odf_config
  cpd_version                = var.cpd_version
  cpd_accept_license         = var.cpd_accept_license
  cpd_admin_password         = var.cpd_admin_password
  cpd_entitlement_key        = var.cpd_entitlement_key
  watsonx_ai_install         = var.watsonx_ai_install
  watsonx_ai_models          = var.watsonx_ai_models
  watsonx_data_install       = var.watsonx_data_install
  watson_discovery_install   = var.watson_discovery_install
  watson_assistant_install   = var.watson_assistant_install
}
