##############################################################################
# ROKS Landing zone
##############################################################################

module "roks_landing_zone" {
  source           = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone.git//patterns/roks-quickstart?ref=v6.6.1"
  ibmcloud_api_key = var.ibmcloud_api_key
  prefix           = var.prefix
  region           = var.region
  resource_tags    = var.resource_tags
}

##############################################################################
# Deploy cloudpak_data
##############################################################################
module "cloudpak_data" {
  source                    = "../../solutions/deploy"
  ibmcloud_api_key          = var.ibmcloud_api_key
  prefix                    = var.prefix
  region                    = var.region
  cluster_name              = module.roks_landing_zone.workload_cluster_id
  cloud_pak_deployer_image  = "quay.io/cloud-pak-deployer/cloud-pak-deployer"
  cpd_admin_password        = "Passw0rd" #pragma: allowlist secret
  cpd_entitlement_key       = "entitlementKey"
  install_odf_cluster_addon = var.install_odf_cluster_addon
}
