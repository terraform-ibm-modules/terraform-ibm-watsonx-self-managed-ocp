output "cluster_name" {
  description = "The name of the OpenShift cluster."
  value       = module.ocp_base.cluster_name
}

output "cluster_id" {
  value       = module.ocp_base.cluster_id
  description = "Cluster ID."
}

output "cluster_resource_group_id" {
  value       = module.ocp_base.resource_group_id
  description = "Cluster resource group ID."
}

output "cluster_resource_group_name" {
  value       = module.resource_group.resource_group_name
  description = "Cluster resource group name."
}
