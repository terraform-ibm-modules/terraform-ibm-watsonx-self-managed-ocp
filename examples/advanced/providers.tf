provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

# Get cluster configuration
# For new clusters, this will be populated after ocp_base module creates the cluster
# For existing clusters, this fetches the config directly
data "ibm_container_cluster_config" "cluster_config" {
  depends_on      = [module.ocp_base]
  cluster_name_id = local.cluster_name
  config_dir      = "/tmp"
}

# Configure Helm provider to deploy Cloud Pak Deployer
provider "helm" {
  kubernetes = {
    host  = data.ibm_container_cluster_config.cluster_config.host
    token = data.ibm_container_cluster_config.cluster_config.token
  }
}
