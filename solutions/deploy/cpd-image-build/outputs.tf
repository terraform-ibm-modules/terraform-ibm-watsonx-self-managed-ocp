output "resource_group" {
  description = "The resource group that was used for the resources within"
  value       = local.resource_group_name
}

output "container_registry_namespace" {
  description = "The name of the container registry namespace"
  value       = local.container_registry_namespace
}

output "container_registry_server" {
  description = "The url of the container registry"
  value       = local.container_registry_server
}

output "container_registry_output_image" {
  description = "The path to the cpd container that was built"
  value       = local.container_registry_output_image
}

output "code_engine_project_name" {
  description = "The name of the code engine project that was created"
  value       = local.code_engine_project_name
}

output "container_build_status" {
  description = "Status of the container build"
  value       = restapi_object.buildstatus.api_data.status
}
