##############################################################################
# Resource Group
##############################################################################

module "cluster_resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.2.0"
  existing_resource_group_name = var.existing_cluster_resource_group_name
}

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.2.0"
  existing_resource_group_name = var.existing_resource_group_name
}

########################################################################################################################
# Watsonx Self Managed OCP module
########################################################################################################################

resource "random_password" "admin_password" {
  count            = var.cpd_admin_password == null ? 1 : 0
  length           = 32
  special          = true
  override_special = "-_"
  min_numeric      = 1
}

locals {
  # _- are invalid first characters
  # if - replace first char with J
  # elseif _ replace first char with K
  # else use asis
  generated_admin_password = (length(random_password.admin_password) > 0 ? (startswith(random_password.admin_password[0].result, "-") ? "J${substr(random_password.admin_password[0].result, 1, -1)}" : startswith(random_password.admin_password[0].result, "_") ? "K${substr(random_password.admin_password[0].result, 1, -1)}" : random_password.admin_password[0].result) : null)
  # admin password to use
  cpd_admin_password = var.cpd_admin_password == null ? local.generated_admin_password : var.cpd_admin_password
  prefix             = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
}

data "ibm_container_vpc_cluster" "cluster" {
  name              = var.existing_cluster_id
  resource_group_id = module.cluster_resource_group.resource_group_id
}

module "watsonx_self_managed_ocp" {
  source                                 = "../.."
  ibmcloud_api_key                       = var.ibmcloud_api_key
  region                                 = var.region
  resource_group_id                      = module.resource_group.resource_group_id
  code_engine_project_name               = "${local.prefix}${var.code_engine_project_name}"
  code_engine_project_id                 = var.code_engine_project_id
  cloud_pak_deployer_image               = var.cloud_pak_deployer_image
  cloud_pak_deployer_release             = var.cloud_pak_deployer_release
  cloud_pak_deployer_secret              = var.cloud_pak_deployer_secret
  cluster_name                           = data.ibm_container_vpc_cluster.cluster.name
  cluster_resource_group_id              = module.cluster_resource_group.resource_group_id
  install_odf_cluster_addon              = var.install_odf_cluster_addon
  odf_version                            = var.odf_version
  odf_config                             = var.odf_config
  cpd_version                            = var.cpd_version
  cpd_accept_license                     = var.cpd_accept_license
  cpd_admin_password                     = local.cpd_admin_password
  cpd_entitlement_key                    = var.cpd_entitlement_key
  watsonx_ai_install                     = var.watsonx_ai_install
  watsonx_ai_models                      = var.watsonx_ai_models
  watsonx_data_install                   = var.watsonx_data_install
  watson_discovery_install               = var.watson_discovery_install
  watson_assistant_install               = var.watson_assistant_install
  use_global_container_registry_location = var.use_global_container_registry_location
  container_registry_namespace           = "${local.prefix}${var.container_registry_namespace}"
  # No need to support suffix in DA as it has prefix functionality
  add_random_suffix_icr_namespace       = false
  add_random_suffix_code_engine_project = false
}

resource "null_resource" "wait_for_cloud_pak_deployer_complete" {
  provisioner "local-exec" {
    command = "${path.module}/../../scripts/wait_for_cpd_pod.sh"

    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
  triggers = {
    always_run = timestamp()
  }

  depends_on = [module.watsonx_self_managed_ocp]
}
