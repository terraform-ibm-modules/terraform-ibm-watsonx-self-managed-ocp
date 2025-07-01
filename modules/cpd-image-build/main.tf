##############################################################################
# Locals
##############################################################################

data "ibm_resource_group" "group" {
  count      = var.resource_group_id == null ? 1 : 0
  is_default = "true"
}

locals {
  resource_group_id                 = var.resource_group_id == null ? data.ibm_resource_group.group[0].id : var.resource_group_id
  container_registry_server         = var.use_global_container_registry_location ? "private.icr.io" : lookup(local.registry_server_map, var.region, null) != null ? local.registry_server_map[var.region] : "private.icr.io"
  container_registry_output_image   = "${local.container_registry_server}/${var.container_registry_namespace}/deployer:${var.cloud_pak_deployer_release}"
  container_registry_namespace_name = var.add_random_suffix_icr_namespace ? "${var.container_registry_namespace}-${random_string.random[0].result}" : var.container_registry_namespace
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
  ce_project_name = var.code_engine_project_name != null ? var.add_random_suffix_code_engine_project ? "${var.code_engine_project_name}-${random_string.random[0].result}" : var.code_engine_project_name : data.ibm_code_engine_project.code_engine_project[0].name
}

##############################################################################
# Generate a random seed since some resources need unique names
##############################################################################

resource "random_string" "random" {
  count   = var.add_random_suffix_icr_namespace || var.add_random_suffix_code_engine_project ? 1 : 0
  length  = 4
  lower   = true
  upper   = false
  special = false
}

##############################################################################
# Container registry namespace
##############################################################################

resource "ibm_cr_namespace" "cr_namespace" {
  name              = local.container_registry_namespace_name
  resource_group_id = local.resource_group_id
}

##############################################################################
# Code engine resources
##############################################################################

data "ibm_code_engine_project" "code_engine_project" {
  count      = var.code_engine_project_id != null ? 1 : 0
  project_id = var.code_engine_project_id
}

module "code_engine" {
  source              = "terraform-ibm-modules/code-engine/ibm"
  version             = "4.4.1"
  project_name        = var.code_engine_project_id == null ? var.code_engine_project_name : null
  existing_project_id = var.code_engine_project_id
  resource_group_id   = var.code_engine_project_id != null ? data.ibm_code_engine_project.code_engine_project[0].resource_group_id : local.resource_group_id
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
  version = "4.4.1"

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
