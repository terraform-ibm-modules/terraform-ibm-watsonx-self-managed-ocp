output "cloud_pak_deployer_image" {
  description = "The Cloud Pak Deployer image used."
  value       = var.cloud_pak_deployer_image != null ? var.cloud_pak_deployer_image : module.build_cpd_image[0].container_registry_output_image
}

output "cloud_pak_deployer_secret" {
  description = "The secret used for accessing the Cloud Pak Deployer image."
  value       = var.cloud_pak_deployer_secret != null ? var.cloud_pak_deployer_secret : (var.cloud_pak_deployer_image == null ? { username : "iamapikey", password : var.ibmcloud_api_key, server : module.build_cpd_image[0].container_registry_server, email : "none" } : null)
  sensitive   = true
}

output "cluster_name" {
  description = "The name of the OpenShift cluster."
  value       = var.cluster_name
}

output "code_engine_project_name" {
  description = "The name of the code engine project that was created"
  value       = var.cloud_pak_deployer_image == null ? module.build_cpd_image.code_engine_project_name : null
}
