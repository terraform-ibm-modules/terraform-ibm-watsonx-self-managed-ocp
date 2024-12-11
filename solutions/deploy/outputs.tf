output "cloud_pak_deployer_config_path" {
  description = "Path to the required config for the Cloud Pak Deployer"
  value       = module.cloud_pak_deployer.cloud_pak_deployer_config_path
}

output "kube_config_path" {
  description = "Path to the kube config file being used"
  value       = local.kube_config_path
}
