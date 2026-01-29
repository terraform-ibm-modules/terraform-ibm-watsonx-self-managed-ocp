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
  version = "1.4.7"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
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
  resource_group            = module.resource_group.resource_group_id
  address_prefix_management = "auto"
  tags                      = var.resource_tags
}

resource "ibm_is_public_gateway" "gateway" {
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
      pool_name        = "default"     # Unique name for the general-purpose worker pool
      machine_type     = "bx3d.64x320" # CPU-based machine type
      operating_system = "REDHAT_8_64"
      workers_per_zone = 3 # Minimum 3 workers to install ODF and ensure high availability
    },
    {
      subnet_prefix    = "default"
      pool_name        = "gpu-pool"       # Unique name for the GPU-enabled worker pool
      machine_type     = "gx3.64x320.4l4" # GPU-based machine type
      operating_system = "REDHAT_8_64"
      workers_per_zone = 2 # Minimum 2 workers per zone for high availability
    }
  ]
}

module "ocp_base" {
  count                               = var.existing_cluster_name == null ? 1 : 0
  source                              = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version                             = "3.78.6"
  resource_group_id                   = module.resource_group.resource_group_id
  region                              = var.region
  tags                                = var.resource_tags
  cluster_name                        = var.prefix
  force_delete_storage                = true
  vpc_id                              = ibm_is_vpc.vpc.id
  vpc_subnets                         = local.cluster_vpc_subnets
  worker_pools                        = local.worker_pools
  disable_outbound_traffic_protection = true # set as True to enable outbound traffic to allow image to be pulled from quay.io
}

##############################################################################
# Deploy watsonx-self-managed-ocp
##############################################################################

module "watsonx_self_managed_ocp" {
  source                    = "git::https://github.com/terraform-ibm-modules/terraform-ibm-watsonx-self-managed-ocp?ref=update-binaries-watsonx"
  ibmcloud_api_key          = var.ibmcloud_api_key
  region                    = var.region
  cluster_name              = local.cluster_name
  cluster_resource_group_id = module.resource_group.resource_group_id
  cpd_admin_password        = var.cpd_admin_password
  cpd_entitlement_key       = var.cpd_entitlement_key
}
