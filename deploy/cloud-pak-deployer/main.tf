locals {
  cloud_pak_deployer = {
    cluster_role_binding_name        = "cloud-pak-deployer-sa-rbac"
    cluster_role_name                = "cluster-admin"
    config_map_name                  = "cloud-pak-deployer-config"
    image                            = var.cloud_pak_deployer_image
    job_label                        = "cloud-pak-deployer"
    job_name                         = "cloud-pak-deployer"
    namespace_name                   = "cloud-pak-deployer"
    persistent_volume_claim_name     = "cloud-pak-deployer-status"
    script_accept_license_flag       = var.cpd_accept_license ? "--accept-all-licenses" : ""
    security_context_constraint_name = "privileged"
    service_account_name             = "cloud-pak-deployer-sa"
  }
}

resource "helm_release" "cloud_pak_deployer_helm_release" {
  name  = "cloud-pak-deployer"
  chart = "${path.module}/../../chart/cloud-pak-deployer"

  namespace         = local.cloud_pak_deployer.namespace_name
  create_namespace  = true
  timeout           = 600
  dependency_update = true
  force_update      = false
  cleanup_on_fail   = false
  wait              = true

  set {
    name  = "namespace"
    type  = "string"
    value = local.cloud_pak_deployer.namespace_name
  }

  set {
    name  = "cluster_name"
    type  = "string"
    value = replace(var.cluster_name, "-", "_")
  }

  set {
    name  = "deployer.configuration"
    type  = "string"
    value = replace(yamlencode(var.cloud_pak_deployer_config), "\"", "")
  }

  set {
    name  = "deployer.job_name_suffix"
    type  = "string"
    value = formatdate("hhmmss", timestamp())
  }

  set {
    name  = "deployer.accept_license_flag"
    type  = "string"
    value = local.cloud_pak_deployer.script_accept_license_flag
  }

  set {
    name  = "deployer.image"
    type  = "string"
    value = local.cloud_pak_deployer.image
  }

  set {
    name  = "createImagePullSecret"
    value = var.cloud_pak_deployer_secret != null ? true : false
  }

  set {
    name  = "imageCredentials.registry"
    type  = "string"
    value = var.cloud_pak_deployer_secret != null ? lookup(var.cloud_pak_deployer_secret, "server", "") : ""
  }

  set {
    name  = "imageCredentials.username"
    type  = "string"
    value = var.cloud_pak_deployer_secret != null ? lookup(var.cloud_pak_deployer_secret, "username", "") : ""
  }

  set {
    name  = "imageCredentials.email"
    type  = "string"
    value = var.cloud_pak_deployer_secret != null ? lookup(var.cloud_pak_deployer_secret, "email", "") : ""
  }

  set_sensitive {
    name  = "deployer.entitlement_key"
    type  = "string"
    value = var.cpd_entitlement_key
  }

  set_sensitive {
    name  = "deployer.admin_password"
    type  = "string"
    value = var.cpd_admin_password
  }

  set_sensitive {
    name  = "imageCredentials.password"
    type  = "string"
    value = var.cloud_pak_deployer_secret != null ? lookup(var.cloud_pak_deployer_secret, "password", "") : ""
  }
}
