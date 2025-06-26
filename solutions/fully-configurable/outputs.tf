output "cloud_pak_deployer_image" {
  description = "The Cloud Pak Deployer image used."
  value       = module.watsonx_self_managed_ocp.cloud_pak_deployer_image
}

output "cloud_pak_deployer_secret" {
  description = "The secret used for accessing the Cloud Pak Deployer image."
  value       = module.watsonx_self_managed_ocp.cloud_pak_deployer_secret
  sensitive   = true
}

output "cluster_name" {
  description = "The name of the OpenShift cluster."
  value       = module.watsonx_self_managed_ocp.cluster_name
}

output "code_engine_project_name" {
  description = "The name of the code engine project that was created"
  value       = module.watsonx_self_managed_ocp.code_engine_project_name
}
