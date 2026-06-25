##############################################################################
# Locals
##############################################################################

locals {
  cluster_name = var.existing_cluster_name != null ? var.existing_cluster_name : module.ocp_base[0].cluster_name
}

##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.6.1"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# VPC + Subnet + Public Gateway (Optional)
#
# NOTE: This example supports both public and private configurations:
# - Set create_public_gateway = true for clusters with internet access
# - Set create_public_gateway = false for secure private-only clusters
########################################################################################################################

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.prefix}-vpc"
  resource_group            = module.resource_group.resource_group_id
  address_prefix_management = "auto"
  tags                      = var.resource_tags
}

resource "ibm_is_public_gateway" "gateway" {
  count          = var.create_public_gateway ? 1 : 0
  name           = "${var.prefix}-gateway-1"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = module.resource_group.resource_group_id
  zone           = "${var.region}-1"
}

resource "ibm_is_subnet" "subnet_zone_1" {
  name                     = "${var.prefix}-subnet-1"
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = module.resource_group.resource_group_id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = var.create_public_gateway ? ibm_is_public_gateway.gateway[0].id : null
}

########################################################################################################################
# OCP VPC cluster
#
# This cluster configuration supports both public and private setups:
# - Public: With public gateway, can pull images from external registries
# - Private: No public gateway, requires ICR image build via Code Engine
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
      pool_name        = "default"     # Unique name for the general-purpose worker pool
      machine_type     = "bx3d.64x320" # CPU-based machine type
      operating_system = "RHEL_9_64"   # RHEL 9 for OCP 4.19+
      workers_per_zone = 3             # Minimum 3 workers to install ODF and ensure high availability
    }
  ]
}

module "ocp_base" {
  count                               = var.existing_cluster_name == null ? 1 : 0
  source                              = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version                             = "3.88.2"
  resource_group_id                   = module.resource_group.resource_group_id
  region                              = var.region
  tags                                = var.resource_tags
  cluster_name                        = var.prefix
  force_delete_storage                = true
  vpc_id                              = ibm_is_vpc.vpc.id
  vpc_subnets                         = local.cluster_vpc_subnets
  worker_pools                        = local.worker_pools
  disable_outbound_traffic_protection = var.disable_outbound_traffic_protection
}

##############################################################################
# Deploy watsonx-self-managed-ocp
#
# This example demonstrates all configuration options:
# - Supports both pre-built images and automatic ICR image build
# - Configurable Cloud Pak Deployer version
# - Optional custom image secret
# - Flexible watsonx service deployment
##############################################################################

module "watsonx_self_managed_ocp" {
  source                    = "../.."
  ibmcloud_api_key          = var.ibmcloud_api_key
  region                    = var.region
  cluster_name              = local.cluster_name
  cluster_resource_group_id = module.resource_group.resource_group_id
  cpd_admin_password        = var.cpd_admin_password
  cpd_entitlement_key       = var.cpd_entitlement_key
  cloud_pak_deployer_image  = var.cloud_pak_deployer_image
  cloud_pak_deployer_secret = var.cloud_pak_deployer_secret
  watsonx_ai_install        = var.watsonx_ai_install
  watsonx_data_install      = var.watsonx_data_install
  watson_assistant_install  = var.watson_assistant_install
  watson_discovery_install  = var.watson_discovery_install
}
