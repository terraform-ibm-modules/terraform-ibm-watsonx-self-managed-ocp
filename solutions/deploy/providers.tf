provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key

  region = var.region
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id = var.cluster_name
  config_dir      = local.kube_config_dir
}

provider "helm" {
  kubernetes {
    host  = data.ibm_container_cluster_config.cluster_config.host
    token = data.ibm_container_cluster_config.cluster_config.token
  }
}
