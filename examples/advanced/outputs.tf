##############################################################################
# Outputs
##############################################################################

output "cluster_id" {
  description = "ID of the OpenShift cluster"
  value       = var.existing_cluster_name == null ? module.ocp_base[0].cluster_id : null
}

output "cluster_name" {
  description = "Name of the OpenShift cluster"
  value       = local.cluster_name
}

output "resource_group_id" {
  description = "Resource group ID"
  value       = module.resource_group.resource_group_id
}

output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.resource_group_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = ibm_is_vpc.vpc.id
}

output "cloud_pak_deployer_image_used" {
  description = "The Cloud Pak Deployer image that was used (either provided or built)"
  value       = module.watsonx_self_managed_ocp.cloud_pak_deployer_image
}

output "code_engine_project_name" {
  description = "The name of the Code Engine project (if image was built)"
  value       = module.watsonx_self_managed_ocp.code_engine_project_name
}
