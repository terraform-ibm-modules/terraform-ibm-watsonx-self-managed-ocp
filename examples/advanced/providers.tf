provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

# Schematics workspace detection for persistent directory
locals {
  paths = {
    scripts = "${path.module}/scripts"
  }
}

data "external" "schematics" {
  program = ["bash", "${local.paths.scripts}/get-schematics-tmp-dir.sh"]
}

locals {
  schematics_workspace = {
    persistent_dir_exists = data.external.schematics.result.schematics_tmp_dir_exists == "true" ? true : false
    persistent_dir_path   = "/tmp/.schematics"
  }
  kube_config_dir = local.schematics_workspace.persistent_dir_exists ? local.schematics_workspace.persistent_dir_path : "${path.module}/kubeconfig"
}

# Get cluster configuration
# For new clusters, this will be populated after ocp_base module creates the cluster
# For existing clusters, this fetches the config directly
data "ibm_container_cluster_config" "cluster_config" {
  depends_on      = [module.ocp_base]
  cluster_name_id = local.cluster_name
  config_dir      = local.kube_config_dir
}

# Configure Helm provider to deploy Cloud Pak Deployer
provider "helm" {
  kubernetes = {
    host  = data.ibm_container_cluster_config.cluster_config.host
    token = data.ibm_container_cluster_config.cluster_config.token
  }
}
