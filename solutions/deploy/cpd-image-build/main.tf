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

module "resource_group" {
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
  resource_group_id = module.resource_group.resource_group_id
}

##############################################################################
# Code engine resources
##############################################################################
resource "ibm_code_engine_project" "ce_project" {
  name              = local.code_engine_project_name
  resource_group_id = module.resource_group.resource_group_id
}

resource "ibm_code_engine_secret" "registry_secret" {
  project_id = ibm_code_engine_project.ce_project.id
  name       = "registry-secret"
  format     = "registry"

  data = {
    password = var.ibmcloud_api_key
    server   = local.container_registry_server
    username = "iamapikey"
  }
}

resource "ibm_code_engine_build" "code_engine_build_instance" {
  project_id      = ibm_code_engine_project.ce_project.project_id
  name            = "cpd-build"
  output_image    = local.container_registry_output_image
  output_secret   = ibm_code_engine_secret.registry_secret.name
  source_url      = "https://github.com/argeiger/cpd-test"
  source_revision = var.cloud_pak_deployer_release
  strategy_type   = "dockerfile"
}

resource "restapi_object" "buildrun" {
  path = "/v2/projects/${ibm_code_engine_project.ce_project.project_id}/build_runs"
  data = jsonencode(
    {
      build_name = ibm_code_engine_build.code_engine_build_instance.name
      timeout    = 3600
    }
  )
  id_attribute = "name"
}

resource "time_sleep" "wait_for_build" {
  create_duration = "2m"

  depends_on = [
    restapi_object.buildrun
  ]
}

resource "restapi_object" "buildstatus" {
  path = "/v2/projects/${ibm_code_engine_project.ce_project.project_id}/build_runs"
  data = jsonencode(
    {
      build_name = ibm_code_engine_build.code_engine_build_instance.name
    }
  )
  id_attribute = "name"

  depends_on = [time_sleep.wait_for_build]
}
