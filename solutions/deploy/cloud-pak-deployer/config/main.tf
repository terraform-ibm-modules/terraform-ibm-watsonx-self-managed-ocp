locals {
  cloud_pak_deployer_config_base = {
    "global_config" = {
      cloud_platform  = "existing-ocp"
      confirm_destroy = "True"
      # env_id           = var.cluster_name
      environment_name = "cpdenv"
    }
    "openshift" = [
      {
        cluster_name = var.cluster_name
        domain_name  = var.cluster_name
        name         = var.cluster_name
        ocp_version  = var.openshift_version
        openshift_storage = [
          {
            storage_name = "auto-storage"
            storage_type = "auto"
          }
        ],
        gpu = {
          install = "False"
        },
        openshift_ai = {
          install = "False",
          channel = "fast"
        }
      }
    ]
    "cp4d" = [
      {
        cp4d_version           = var.cpd_version
        openshift_cluster_name = var.cluster_name
        project                = "cpd"
        sequential_install     = "True"
        cartridges = [
          {
            name = "cp-foundation"
            license_service = {
              state            = "disabled"
              threads_per_core = 2
            }
          },
          {
            name = "lite"
          }
        ]
      }
    ]
  }
}
