provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
  visibility       = var.provider_visibility
}

locals {
  paths = {
    scripts = "${path.module}/scripts"
    binaries_path = "/tmp"
  }
}

data "external" "schematics" {
  program = ["bash", "${local.paths.scripts}/get-schematics-tmp-dir.sh ${local.binaries_path}"]
}

locals {
  schematics_workspace = {
    persistent_dir_exists = data.external.schematics.result.schematics_tmp_dir_exists ? true : false
    persistent_dir_path   = "/tmp/.schematics"
  }
  kube_config_dir = local.schematics_workspace.persistent_dir_exists ? local.schematics_workspace.persistent_dir_path : "${path.module}/kubeconfig"
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id = var.existing_cluster_id
  config_dir      = local.kube_config_dir
}

data "ibm_iam_auth_token" "tokendata" {}

provider "shell" {
  sensitive_environment = {
    TOKEN = data.ibm_iam_auth_token.tokendata.iam_access_token
  }
}

provider "helm" {
  kubernetes = {
    host  = data.ibm_container_cluster_config.cluster_config.host
    token = data.ibm_container_cluster_config.cluster_config.token
  }
}
