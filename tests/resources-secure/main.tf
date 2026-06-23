##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.6.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# VPC + Subnet (NO PUBLIC GATEWAY - secure by default)
########################################################################################################################

# Add a small delay to ensure resource group is fully propagated
resource "time_sleep" "wait_for_resource_group" {
  depends_on = [module.resource_group]
  
  create_duration = "30s"
}

resource "random_string" "vpc_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.prefix}-vpc-${random_string.vpc_suffix.result}"
  resource_group            = module.resource_group.resource_group_id
  address_prefix_management = "auto"
  tags                      = var.resource_tags
  
  depends_on = [time_sleep.wait_for_resource_group]
}

# Subnet without public gateway for secure private-only cluster
resource "ibm_is_subnet" "subnet_zone_1" {
  name                     = "${var.prefix}-subnet-1"
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = module.resource_group.resource_group_id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  # NO public_gateway attached - secure by default
}

########################################################################################################################
# OCP VPC cluster (single zone, private-only, no outbound traffic)
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
      workers_per_zone = 3 # Minimum 3 workers to install ODF and ensure high availability
      operating_system = "RHCOS"
    }
  ]
}

module "ocp_base" {
  source                              = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version                             = "3.87.1"
  resource_group_id                   = module.resource_group.resource_group_id
  region                              = var.region
  tags                                = var.resource_tags
  cluster_name                        = "${var.prefix}-cluster"
  force_delete_storage                = true
  vpc_id                              = ibm_is_vpc.vpc.id
  vpc_subnets                         = local.cluster_vpc_subnets
  worker_pools                        = local.worker_pools
  access_tags                         = []
  disable_outbound_traffic_protection = true # Allow outbound traffic for Code Engine to access GitHub for image build
  ocp_version                         = "4.19"
  verify_worker_network_readiness     = false # Disable network health check for secure private cluster
}