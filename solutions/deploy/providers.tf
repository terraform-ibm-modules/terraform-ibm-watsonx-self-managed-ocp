provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key

  region = var.region
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id = var.cluster_name
  config_dir      = local.kube_config_dir
}

provider "kubernetes" {
  host  = data.ibm_container_cluster_config.cluster_config.host
  token = data.ibm_container_cluster_config.cluster_config.token
}

data "ibm_iam_auth_token" "tokendata" {}

provider "restapi" {
  uri                  = "https://api.${var.region}.codeengine.cloud.ibm.com/"
  debug                = true
  write_returns_object = true
  headers = {
    Authorization = data.ibm_iam_auth_token.tokendata.iam_access_token
  }
}
