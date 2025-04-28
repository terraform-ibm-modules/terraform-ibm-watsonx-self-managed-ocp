provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key

  region = var.region
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id = var.cluster_name
  config_dir      = local.kube_config_dir
}

data "ibm_iam_auth_token" "tokendata" {}

provider "shell" {
  sensitive_environment = {
    TOKEN = data.ibm_iam_auth_token.tokendata.iam_access_token
  }
}

provider "helm" {
  kubernetes {
    host  = data.ibm_container_cluster_config.cluster_config.host
    token = data.ibm_container_cluster_config.cluster_config.token
  }
}
