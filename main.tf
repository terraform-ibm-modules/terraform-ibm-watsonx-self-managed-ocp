##############################################################################
# Build the image in Code Engine if one is not passed and publish to ICR
##############################################################################

module "build_cpd_image" {
  count                                  = var.cloud_pak_deployer_image == null ? 1 : 0
  source                                 = "./modules/cpd-image-build"
  ibmcloud_api_key                       = var.ibmcloud_api_key
  region                                 = var.region
  code_engine_project_name               = var.code_engine_project_name
  code_engine_project_id                 = var.code_engine_project_id
  resource_group_id                      = var.resource_group_id
  use_global_container_registry_location = var.use_global_container_registry_location
  cloud_pak_deployer_release             = var.cloud_pak_deployer_release
  container_registry_namespace           = var.container_registry_namespace
  add_random_suffix_icr_namespace        = var.add_random_suffix_icr_namespace
  add_random_suffix_code_engine_project  = var.add_random_suffix_code_engine_project
}

##############################################################################
# Install OCP ODF cluster addon
##############################################################################

resource "ibm_container_addons" "odf_cluster_addon" {
  count             = var.install_odf_cluster_addon ? 1 : 0
  cluster           = var.cluster_name
  manage_all_addons = false
  resource_group_id = var.cluster_resource_group_id
  addons {
    name            = "openshift-data-foundation"
    version         = var.odf_version
    parameters_json = jsonencode(var.odf_config)
  }
}

##############################################################################
# watsonx-ai
##############################################################################

module "watsonx_ai" {
  source                   = "./modules/watsonx-ai"
  depends_on               = [ibm_container_addons.odf_cluster_addon]
  watson_assistant_install = var.watson_assistant_install
  watson_discovery_install = var.watson_discovery_install
  watsonx_ai_install       = var.watsonx_ai_install
  watsonx_ai_models        = var.watsonx_ai_models
}

##############################################################################
# watsonx-data
##############################################################################

module "watsonx_data" {
  source               = "./modules/watsonx-data"
  depends_on           = [ibm_container_addons.odf_cluster_addon]
  watsonx_data_install = var.watsonx_data_install
}

##############################################################################
# Cloud Pak deployer
##############################################################################

module "cloud_pak_deployer" {
  depends_on = [
    module.watsonx_ai,
    module.watsonx_data,
    module.build_cpd_image
  ]
  source = "./modules/cloud-pak-deployer"
  cloud_pak_deployer_config = merge(
    module.config.cloud_pak_deployer_config_base,
    {
      cp4d = [merge(
        module.config.cloud_pak_deployer_config_base["cp4d"][0],
        {
          cartridges = concat(
            module.config.cloud_pak_deployer_config_base["cp4d"][0]["cartridges"],
            module.watsonx_ai.watsonx_ai_cloud_pak_deployer_config.cartridges,
            module.watsonx_data.watsonx_data_cloud_pak_deployer_config.cartridges
          )
        }
      )]
    }
  )
  cloud_pak_deployer_image = var.cloud_pak_deployer_image != null ? var.cloud_pak_deployer_image : module.build_cpd_image[0].container_registry_output_image

  cloud_pak_deployer_secret = var.cloud_pak_deployer_secret != null ? var.cloud_pak_deployer_secret : (var.cloud_pak_deployer_image == null ?
  { username : "iamapikey", password : var.ibmcloud_api_key, server : module.build_cpd_image[0].container_registry_server, email : "none" } : null)

  cluster_name        = var.cluster_name
  cpd_accept_license  = var.cpd_accept_license
  cpd_admin_password  = var.cpd_admin_password
  cpd_entitlement_key = var.cpd_entitlement_key
}

# Retrieve the openshift cluster info
data "ibm_container_vpc_cluster" "cluster_info" {
  name              = var.cluster_name
  resource_group_id = var.cluster_resource_group_id
}
locals {
  openshift_version = join(".", slice(split(".", data.ibm_container_vpc_cluster.cluster_info.kube_version), 0, 2)) # Only use major and minor — no patch
}

# Cloud Pak Deployer configuration file local variable(s) only
module "config" {
  source            = "./modules/cloud-pak-deployer/config"
  cluster_name      = var.cluster_name
  cpd_version       = var.cpd_version
  openshift_version = local.openshift_version
}
