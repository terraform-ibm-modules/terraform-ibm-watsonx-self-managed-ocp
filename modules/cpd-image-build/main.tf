##############################################################################
# Locals
##############################################################################

data "ibm_resource_group" "group" {
  count      = var.resource_group_id == null ? 1 : 0
  is_default = "true"
}

locals {
  resource_group_id                 = var.resource_group_id == null ? data.ibm_resource_group.group[0].id : var.resource_group_id
  container_registry_namespace_name = var.add_random_suffix_icr_namespace ? "${var.container_registry_namespace}-${random_string.random[0].result}" : var.container_registry_namespace
  ce_project_name                   = var.code_engine_project_id != null ? data.ibm_code_engine_project.code_engine_project[0].name : (var.add_random_suffix_code_engine_project ? "${var.code_engine_project_name}-${random_string.random[0].result}" : var.code_engine_project_name)
  # Global registry uses the multi-region endpoint; regional uses the region-specific one.
  # The namespace itself is always created — only the image URL differs.
  output_image = var.use_global_container_registry_location ? "private.icr.io/${local.container_registry_namespace_name}/deployer:${var.cloud_pak_deployer_release}" : "private.${var.region}.icr.io/${local.container_registry_namespace_name}/deployer:${var.cloud_pak_deployer_release}"
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
# Look up existing CE project name
##############################################################################

data "ibm_code_engine_project" "code_engine_project" {
  count      = var.code_engine_project_id != null ? 1 : 0
  project_id = var.code_engine_project_id
}

##############################################################################
# Container registry namespace — always created regardless of registry location.
# use_global_container_registry_location only controls the image URL endpoint,
# not whether the namespace exists.
##############################################################################

resource "ibm_cr_namespace" "cr_namespace" {
  name              = local.container_registry_namespace_name
  resource_group_id = local.resource_group_id
}

##############################################################################
# Code Engine project + build
##############################################################################

# Use the project's own resource group so
# the CE module does not attempt to create a project in the wrong group.
locals {
  ce_resource_group_id = var.code_engine_project_id != null ? data.ibm_code_engine_project.code_engine_project[0].resource_group_id : local.resource_group_id
}

module "code_engine" {
  source              = "terraform-ibm-modules/code-engine/ibm"
  version             = "4.9.9"
  ibmcloud_api_key    = var.ibmcloud_api_key
  project_name        = var.code_engine_project_id == null ? (var.add_random_suffix_code_engine_project ? "${var.code_engine_project_name}-${random_string.random[0].result}" : var.code_engine_project_name) : null
  existing_project_id = var.code_engine_project_id
  resource_group_id   = local.ce_resource_group_id

  # When using the global registry, also create the registry secret in the CE
  # project so the build module can reference it by name via output_secret.
  # For regional builds the build submodule creates the secret automatically.
  secrets = {
    "registry-secret" = { # pragma: allowlist secret
      format = "registry"
      data = {
        "password" : coalesce(var.container_registry_api_key, var.ibmcloud_api_key),
        "server" : var.use_global_container_registry_location ? "private.icr.io" : "private.${var.region}.icr.io",
        "username" : "iamapikey"
      }
    }
  }

  builds = {
    "cpd-build" = {
      source_url      = "https://github.com/IBM/cloud-pak-deployer"
      source_revision = var.cloud_pak_deployer_release
      strategy_type   = "dockerfile"
      region          = var.region
      output_image    = local.output_image
      output_secret   = "registry-secret" # pragma: allowlist secret
    }
  }

  depends_on = [ibm_cr_namespace.cr_namespace]
}
