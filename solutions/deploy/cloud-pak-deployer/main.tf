locals {
  cloud_pak_deployer = {
    cluster_role_binding_name        = "cloud-pak-deployer-sa-rbac"
    cluster_role_name                = "cluster-admin"
    config_map_name                  = "cloud-pak-deployer-config"
    config_path                      = "${var.schematics_workspace.persistent_dir_exists ? "${var.schematics_workspace.persistent_dir_path}/" : ""}${path.module}/config/config.yaml"
    image                            = var.cloud_pak_deployer_image
    job_label                        = "cloud-pak-deployer"
    job_name                         = "cloud-pak-deployer"
    namespace_name                   = "cloud-pak-deployer"
    persistent_volume_claim_name     = "cloud-pak-deployer-status"
    script_accept_license_flag       = var.cpd_accept_license ? "--accept-all-licenses" : ""
    security_context_constraint_name = "privileged"
    service_account_name             = "cloud-pak-deployer-sa"
  }
  cpd = {
    entitlement_key_secret_key_name = "cp-entitlement-key"        # data key inside secret # checkov:skip=CKV_SECRET_6:Base64 High Entropy String
    entitlement_key_secret_name     = "cloud-pak-entitlement-key" # kubernetes resource name
  }
  oc = "oc --kubeconfig ${var.kube_config_path}"
  paths = {
    definitions = "${var.schematics_workspace.persistent_dir_exists ? "${var.schematics_workspace.persistent_dir_path}/" : ""}${path.module}/definitions"
    templates   = "${path.module}/templates"
  }
  yaml_files = {
    job_uninstall_cpd = "job-uninstall-cpd.yaml.tftpl"
  }
  image_secret_map = var.cloud_pak_deployer_secret != null ? { name = "cpd-docker-cfg" } : {}
}

# Generate configuration file
# https://ibm.github.io/cloud-pak-deployer/50-advanced/run-on-openshift/build-image-and-run-deployer-on-openshift/#create-configuration
resource "local_file" "config" {
  content  = replace(yamlencode(var.cloud_pak_deployer_config), "\"", "")
  filename = local.cloud_pak_deployer.config_path
}

resource "local_file" "deployer_definitions" {
  for_each = local.yaml_files
  content = templatefile("${local.paths.templates}/${each.value}", {
    cloud_pak_deployer_config_map_name              = local.cloud_pak_deployer.config_map_name
    cloud_pak_deployer_image                        = local.cloud_pak_deployer.image
    cloud_pak_deployer_job_label                    = local.cloud_pak_deployer.job_label
    cloud_pak_deployer_job_name                     = local.cloud_pak_deployer.job_name
    cloud_pak_deployer_namespace_name               = local.cloud_pak_deployer.namespace_name
    cloud_pak_deployer_persistent_volume_claim_name = local.cloud_pak_deployer.persistent_volume_claim_name
    cloud_pak_deployer_service_account_name         = local.cloud_pak_deployer.service_account_name
    cloud_pak_deployer_image_secret                 = local.image_secret_map == null || local.image_secret_map == {} ? "" : join(",", [for key, value in local.image_secret_map : "- ${key}: ${value}"])
  })
  filename = "${local.paths.definitions}/${each.value}"
}

resource "kubernetes_namespace_v1" "cloud_pak_deployer_namespace" {
  metadata {
    name = local.cloud_pak_deployer.namespace_name
  }
}


resource "kubernetes_secret" "cpd_entitlement_key_secret" {
  depends_on = [
    kubernetes_namespace_v1.cloud_pak_deployer_namespace
  ]

  metadata {
    name      = local.cpd.entitlement_key_secret_name
    namespace = local.cloud_pak_deployer.namespace_name
  }

  data = {
    (local.cpd.entitlement_key_secret_key_name) = var.cpd_entitlement_key
  }
}

resource "kubernetes_service_account_v1" "cloud_pak_deployer_service_account" {
  depends_on = [
    kubernetes_namespace_v1.cloud_pak_deployer_namespace
  ]

  metadata {
    name      = local.cloud_pak_deployer.service_account_name
    namespace = local.cloud_pak_deployer.namespace_name
  }
}

resource "null_resource" "cloud_pak_deployer_security_context_constraint" {
  depends_on = [
    kubernetes_service_account_v1.cloud_pak_deployer_service_account
  ]

  triggers = {
    namespace_name                   = local.cloud_pak_deployer.namespace_name
    security_context_constraint_name = local.cloud_pak_deployer.security_context_constraint_name
    service_account_name             = local.cloud_pak_deployer.service_account_name
    oc                               = local.oc
  }
  provisioner "local-exec" {
    command = "${self.triggers.oc} adm policy add-scc-to-user ${self.triggers.security_context_constraint_name} -z ${self.triggers.service_account_name} -n ${self.triggers.namespace_name}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "${self.triggers.oc} adm policy remove-scc-from-user ${self.triggers.security_context_constraint_name} -z ${self.triggers.service_account_name} -n ${self.triggers.namespace_name}"
  }
}

resource "kubernetes_cluster_role_binding_v1" "cloud_pak_deployer_cluster_role_binding" {
  depends_on = [
    kubernetes_namespace_v1.cloud_pak_deployer_namespace,
    kubernetes_service_account_v1.cloud_pak_deployer_service_account
  ]

  metadata {
    name = local.cloud_pak_deployer.cluster_role_binding_name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = local.cloud_pak_deployer.cluster_role_name
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.cloud_pak_deployer.service_account_name
    namespace = local.cloud_pak_deployer.namespace_name
  }
}

resource "kubernetes_secret" "docker_cfg_secret" {
  count = var.cloud_pak_deployer_secret != null ? 1 : 0
  depends_on = [
    kubernetes_namespace_v1.cloud_pak_deployer_namespace
  ]

  metadata {
    name      = "cpd-docker-cfg"
    namespace = local.cloud_pak_deployer.namespace_name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (var.cloud_pak_deployer_secret.server) = {
          "username" = var.cloud_pak_deployer_secret.username
          "password" = var.cloud_pak_deployer_secret.password
          "email"    = lookup(var.cloud_pak_deployer_secret, "email", "")
          "auth"     = base64encode("${var.cloud_pak_deployer_secret.username}:${var.cloud_pak_deployer_secret.password}")
        }
      }
    })
  }
}

resource "kubernetes_config_map_v1" "cloud_pak_deployer_configmap" {
  depends_on = [
    kubernetes_namespace_v1.cloud_pak_deployer_namespace
  ]

  metadata {
    name      = local.cloud_pak_deployer.config_map_name
    namespace = local.cloud_pak_deployer.namespace_name
  }

  data = {
    "cpd-config.yaml" = local_file.config.content
  }
}

resource "kubernetes_persistent_volume_claim_v1" "cloud_pak_deployer_persistent_volume_claim" {
  depends_on = [kubernetes_namespace_v1.cloud_pak_deployer_namespace]

  metadata {
    name      = local.cloud_pak_deployer.persistent_volume_claim_name
    namespace = local.cloud_pak_deployer.namespace_name
  }
  spec {
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    access_modes = ["ReadWriteOnce"]
  }

  wait_until_bound = true
}

resource "kubernetes_job_v1" "cloud_pak_deployer_job" {
  depends_on = [
    kubernetes_namespace_v1.cloud_pak_deployer_namespace,
    kubernetes_secret.cpd_entitlement_key_secret,
    kubernetes_service_account_v1.cloud_pak_deployer_service_account,
    null_resource.cloud_pak_deployer_security_context_constraint,
    kubernetes_cluster_role_binding_v1.cloud_pak_deployer_cluster_role_binding,
    kubernetes_secret.docker_cfg_secret,
    kubernetes_config_map_v1.cloud_pak_deployer_configmap,
    kubernetes_persistent_volume_claim_v1.cloud_pak_deployer_persistent_volume_claim
  ]

  metadata {
    labels = {
      App = local.cloud_pak_deployer.job_label
    }
    name      = local.cloud_pak_deployer.job_name
    namespace = local.cloud_pak_deployer.namespace_name
  }
  spec {
    parallelism   = 1
    completions   = 1
    backoff_limit = 0
    template {
      metadata {
        name = local.cloud_pak_deployer.job_name
        labels = {
          App = local.cloud_pak_deployer.job_label
        }
      }
      spec {
        dynamic "image_pull_secrets" {
          for_each = local.image_secret_map

          content {
            name = image_pull_secrets.value
          }
        }

        container {
          name                       = local.cloud_pak_deployer.job_name
          image                      = local.cloud_pak_deployer.image
          image_pull_policy          = "Always"
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          env {
            name  = "CONFIG_DIR"
            value = "/Data/cpd-config"
          }
          env {
            name  = "STATUS_DIR"
            value = "/Data/cpd-status"
          }
          env {
            name = "CP_ENTITLEMENT_KEY"
            value_from {
              secret_key_ref {
                name = local.cpd.entitlement_key_secret_name
                key  = local.cpd.entitlement_key_secret_key_name
              }
            }
          }
          volume_mount {
            name       = "config-volume"
            mount_path = "/Data/cpd-config/config"
          }
          volume_mount {
            name       = "status-volume"
            mount_path = "/Data/cpd-status"
          }
          command = ["/bin/sh", "-xc"]
          args    = ["/cloud-pak-deployer/cp-deploy.sh vault set -vs cp4d_admin_cpd_${replace(var.cluster_name, "-", "_")} -vsv ${var.cpd_admin_password} && /cloud-pak-deployer/cp-deploy.sh env apply -vvvv ${local.cloud_pak_deployer.script_accept_license_flag}"]
        }
        restart_policy = "Never"
        security_context {
          run_as_user = 0
        }
        service_account_name = local.cloud_pak_deployer.service_account_name
        volume {
          name = "config-volume"
          config_map {
            name = local.cloud_pak_deployer.config_map_name
          }
        }
        volume {
          name = "status-volume"
          persistent_volume_claim {
            claim_name = local.cloud_pak_deployer.persistent_volume_claim_name
          }
        }
      }
    }
  }
  wait_for_completion = var.wait_for_cpd_job_completion
  timeouts {
    create = "5h"
  }
  lifecycle {
    replace_triggered_by = [
      local_file.config,
      kubernetes_config_map_v1.cloud_pak_deployer_configmap
    ]
  }
}

resource "shell_script" "uninstall" {
  depends_on = [kubernetes_job_v1.cloud_pak_deployer_job]

  lifecycle_commands {
    create = ""
    delete = file("${path.module}/scripts/uninstall.sh")
  }

  environment = {
    JOB_NAME                   = yamldecode(local_file.deployer_definitions["job_uninstall_cpd"].content).metadata.name
    JOB_UNINSTALL_CPD_FILENAME = local_file.deployer_definitions["job_uninstall_cpd"].filename
    NAMESPACE_NAME             = local.cloud_pak_deployer.namespace_name
    OC                         = local.oc
  }
}
