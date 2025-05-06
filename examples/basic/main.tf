##############################################################################
locals {
  cluster_name  = var.existing_cluster_name != null ? var.existing_cluster_name : module.ocp_base[0].cluster_name
  cluster_rg_id = var.existing_cluster_rg_id != null ? var.existing_cluster_rg_id : module.resource_group[0].resource_group_id
}
###############################################################################

##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  count   = var.existing_cluster_rg_id == null ? 1 : 0
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.2.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name = "${var.prefix}-resource-group"
}

########################################################################################################################
# VPC + Subnet + Public Gateway
#
# NOTE: This is a very simple VPC with single subnet in a single zone with a public gateway enabled, that will allow
# all traffic ingress/egress by default.
# For production use cases this would need to be enhanced by adding more subnets and zones for resiliency, and
# ACLs/Security Groups for network security.
########################################################################################################################

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.prefix}-vpc"
  resource_group            = local.cluster_rg_id
  address_prefix_management = "auto"
  tags                      = var.resource_tags
}

resource "ibm_is_public_gateway" "gateway" {
  name           = "${var.prefix}-gateway-1"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = local.cluster_rg_id
  zone           = "${var.region}-1"
}

resource "ibm_is_subnet" "subnet_zone_1" {
  name                     = "${var.prefix}-subnet-1"
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = local.cluster_rg_id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway.id
}

########################################################################################################################
# OCP VPC cluster (single zone)
########################################################################################################################

locals {
  cluster_vpc_subnets = {
    default = [
      {
        id         = ibm_is_subnet.subnet_zone_1.id
        cidr_block = ibm_is_subnet.subnet_zone_1.ipv4_cidr_block
        zone       = ibm_is_subnet.subnet_zone_1.zone
      }
    ]
  }

  worker_pools = [
    {
      subnet_prefix    = "default"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = "bx2.16x64"
      operating_system = "REDHAT_8_64"
      workers_per_zone = 3 # minimum of 2 is allowed when using single zone
    }
  ]
}

module "ocp_base" {
  count                               = var.existing_cluster_name == null ? 1 : 0
  source                              = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version                             = "3.46.14"
  resource_group_id                   = local.cluster_rg_id
  region                              = var.region
  tags                                = var.resource_tags
  cluster_name                        = var.prefix
  force_delete_storage                = true
  vpc_id                              = ibm_is_vpc.vpc.id
  vpc_subnets                         = local.cluster_vpc_subnets
  worker_pools                        = local.worker_pools
  disable_outbound_traffic_protection = true # set as True to enable outbound traffic
}

##############################################################################
# Deploy cloudpak_data
##############################################################################

module "cloudpak_data" {
  source                    = "../../solutions/deploy"
  ibmcloud_api_key          = var.ibmcloud_api_key
  prefix                    = var.prefix
  region                    = var.region
  cluster_name              = local.cluster_name
  cluster_rg_id             = local.cluster_rg_id
  cloud_pak_deployer_image  = "quay.io/cloud-pak-deployer/cloud-pak-deployer"
  cpd_admin_password        = "Passw0rd" #pragma: allowlist secret
  cpd_entitlement_key       = "entitlementKey"
  install_odf_cluster_addon = var.install_odf_cluster_addon
}
