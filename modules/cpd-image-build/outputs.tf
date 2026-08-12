output "container_registry_namespace" {
  description = "The name of the container registry namespace"
  value       = local.container_registry_namespace_name
}

output "container_registry_server" {
  description = "The url of the container registry"
  # Extract just the registry server.
  value = split("/", module.code_engine.build["cpd-build"].output_image)[0]
}

output "container_registry_output_image" {
  description = "The path to the cpd container that was built"
  value       = module.code_engine.build["cpd-build"].output_image
}

output "code_engine_project_name" {
  description = "The name of the code engine project that was used"
  value       = local.ce_project_name
}

output "code_engine_project_id" {
  description = "The ID of the code engine project that used"
  value       = module.code_engine.project_id
}
