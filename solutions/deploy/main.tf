locals {
  kube_config_dir   = local.schematics_workspace.persistent_dir_exists ? local.schematics_workspace.persistent_dir_path : path.module
  kube_config_path  = data.ibm_container_cluster_config.cluster_config.config_file_path
  oc                = "oc --kubeconfig ${local.kube_config_path}"
  openshift_version = join(".", slice(split(".", data.ibm_container_vpc_cluster.cluster_info.kube_version), 0, 2)) # Only use major and minor — no patch
  paths = {
    scripts = "${path.module}/scripts"
  }
  schematics_workspace = {
    persistent_dir_exists = data.external.schematics.result.schematics_tmp_dir_exists ? true : false
    persistent_dir_path   = "/tmp/.schematics"
  }
}

# Retrieve the openshift cluster info
data "ibm_container_vpc_cluster" "cluster_info" {
  name = var.cluster_name
}

module "build_cpd_image" {
  count                      = var.cloud_pak_deployer_image == null ? 1 : 0
  source                     = "./cpd-image-build"
  ibmcloud_api_key           = var.ibmcloud_api_key
  prefix                     = var.prefix
  region                     = var.region
  code_engine_project_name   = var.code_engine_project_name
  code_engine_project_id     = var.code_engine_project_id
  resource_group             = var.resource_group
  resource_group_exists      = var.resource_group_exists
  cloud_pak_deployer_release = var.cloud_pak_deployer_release
}

resource "ibm_container_addons" "odf_cluster_addon" {
  count             = var.install_odf_cluster_addon ? 1 : 0
  cluster           = var.cluster_name
  manage_all_addons = false
  addons {
    name            = "openshift-data-foundation"
    version         = var.odf_version
    parameters_json = jsonencode(var.odf_config)
  }
}

module "watsonx_ai" {
  source                   = "./watsonx-ai"
  depends_on               = [null_resource.oc_login, ibm_container_addons.odf_cluster_addon]
  watson_assistant_install = var.watson_assistant_install
  watson_discovery_install = var.watson_discovery_install
  watsonx_ai_install       = var.watsonx_ai_install
  watsonx_ai_models        = var.watsonx_ai_models
}

module "watsonx_data" {
  source               = "./watsonx-data"
  depends_on           = [null_resource.oc_login, ibm_container_addons.odf_cluster_addon]
  watsonx_data_install = var.watsonx_data_install
}

module "cloud_pak_deployer" {
  depends_on = [module.watsonx_ai, module.watsonx_data, module.build_cpd_image]
  source     = "./cloud-pak-deployer"
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
  { username : "iamapikey", password : var.ibmcloud_api_key, server : module.build_cpd_image[0].container_registry_server } : null)

  cluster_name                = var.cluster_name
  cpd_accept_license          = var.cpd_accept_license
  cpd_admin_password          = var.cpd_admin_password
  cpd_entitlement_key         = var.cpd_entitlement_key
  kube_config_path            = local.kube_config_path
  schematics_workspace        = local.schematics_workspace
  wait_for_cpd_job_completion = var.wait_for_cpd_job_completion
}

# Cloud Pak Deployer configuration file local variable(s) only
module "config" {
  source            = "./cloud-pak-deployer/config"
  cluster_name      = var.cluster_name
  cpd_version       = var.cpd_version
  openshift_version = local.openshift_version
}

# Log into the OpenShift cluster as administrator
resource "null_resource" "oc_login" {
  triggers = {
    always_run       = timestamp()
    kube_config_path = local.kube_config_path
    oc               = local.oc
  }
  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      ${self.triggers.oc} login --token="${data.ibm_container_cluster_config.cluster_config.token}" --server="${data.ibm_container_cluster_config.cluster_config.host}"
      if [[ $? -ne 0 ]]; then exit 1; fi
    EOF
    # quiet   = true
  }
}
