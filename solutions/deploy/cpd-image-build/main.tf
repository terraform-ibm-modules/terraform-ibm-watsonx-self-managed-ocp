locals {
  resource_group_name = var.resource_group == null ? "${var.prefix}-cpd" : var.resource_group

  container_registry_namespace    = var.container_registry_namespace != null ? var.container_registry_namespace : "${var.prefix}-cpd-${random_string.random.result}"
  container_registry_server       = lookup(local.registry_server_map, var.region, null) != null ? local.registry_server_map[var.region] : "private.icr.io"
  container_registry_output_image = "${local.container_registry_server}/${local.container_registry_namespace}/deployer:${var.cloud_pak_deployer_release}"

  code_engine_project_name = var.code_engine_project_name != null ? var.code_engine_project_name : "${var.prefix}-cpd-${random_string.random.result}"

  registry_server_map = {
    au-syd   = "private.au.icr.io"
    br-sao   = "private.br.icr.io"
    ca-tor   = "private.ca.icr.io"
    eu-de    = "private.de.icr.io"
    eu-es    = "private.es.icr.io"
    jp-tok   = "private.jp.icr.io"
    eu-gb    = "private.uk.icr.io"
    us-south = "private.us.icr.io"
  }

  resource_group_id = var.code_engine_project_id != null ? data.ibm_code_engine_project.code_engine_project[0].resource_group_id : module.resource_group[0].resource_group_id
}

##############################################################################
# Generate a random seed since some resources need unique names
##############################################################################
resource "random_string" "random" {
  length  = 8
  lower   = true
  upper   = false
  special = false
}

data "ibm_code_engine_project" "code_engine_project" {
  count      = var.code_engine_project_id != null ? 1 : 0
  project_id = var.code_engine_project_id
}

module "resource_group" {
  count   = var.code_engine_project_id == null ? 1 : 0
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.6"

  resource_group_name          = var.resource_group_exists ? null : local.resource_group_name
  existing_resource_group_name = var.resource_group_exists ? var.resource_group : null
}

##############################################################################
# Container registry resources
##############################################################################
resource "ibm_cr_namespace" "cr_namespace" {
  name              = local.container_registry_namespace
  resource_group_id = local.resource_group_id
}

##############################################################################
# Code engine resources
##############################################################################
module "code_engine" {
  source              = "terraform-ibm-modules/code-engine/ibm"
  version             = "4.2.2"
  project_name        = var.code_engine_project_id == null ? local.code_engine_project_name : null
  existing_project_id = var.code_engine_project_id
  resource_group_id   = local.resource_group_id
  secrets = {
    "registry-secret" = {
      format = "registry"
      data = {
        "password" : var.ibmcloud_api_key,
        "server" : local.container_registry_server,
        "username" : "iamapikey"
      }
    }
  }
}

module "code_engine_build" {
  source  = "terraform-ibm-modules/code-engine/ibm//modules/build"
  version = "4.2.2"

  name            = "cpd-build"
  project_id      = module.code_engine.project_id
  output_image    = local.container_registry_output_image
  output_secret   = "registry-secret" # pragma: allowlist secret
  source_url      = "https://github.com/IBM/cloud-pak-deployer"
  source_revision = var.cloud_pak_deployer_release
  strategy_type   = "dockerfile"

  depends_on = [module.code_engine]
}

resource "shell_script" "build_run" {
  lifecycle_commands {
    create = file("${path.module}/scripts/image-build.sh")
    delete = ""
    update = ""
  }

  environment = {
    REGION     = var.region
    PROJECT_ID = module.code_engine.project_id
  }

  depends_on = [module.code_engine_build]
}
