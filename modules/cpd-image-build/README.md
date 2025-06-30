# Cloud Pak Data (CPD) image build module

A module to build and publish the Cloud Pak Data (CPD) image to container registry.

### Usage

```hcl
module "build_image" {
  source                       = "terraform-ibm-modules/watsonx-self-managed-ocp/ibm//modules/cpd-image-build"
  version                      = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  ibmcloud_api_key             = "XXXXXXXXXXXX" # replace with apikey value
  region                       = "us-south
  resource_group_id            = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX" # replace with resource group ID
  container_registry_namespace = "my-namespace"
  code_engine_project_name     = "my-project"
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >=1.79.1, <2.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.4.3, < 4.0.0 |
| <a name="requirement_shell"></a> [shell](#requirement\_shell) | >= 1.7.10, <2.0.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_code_engine"></a> [code\_engine](#module\_code\_engine) | terraform-ibm-modules/code-engine/ibm | 4.4.1 |
| <a name="module_code_engine_build"></a> [code\_engine\_build](#module\_code\_engine\_build) | terraform-ibm-modules/code-engine/ibm//modules/build | 4.4.1 |

### Resources

| Name | Type |
|------|------|
| [ibm_cr_namespace.cr_namespace](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/cr_namespace) | resource |
| [random_string.random](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [shell_script.build_run](https://registry.terraform.io/providers/scottwinkler/shell/latest/docs/resources/script) | resource |
| [ibm_code_engine_project.code_engine_project](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/code_engine_project) | data source |
| [ibm_resource_group.group](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/resource_group) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_random_suffix_code_engine_project"></a> [add\_random\_suffix\_code\_engine\_project](#input\_add\_random\_suffix\_code\_engine\_project) | Whether to add a randomly generated 4-character suffix to the newly created Code Engine project. Only applies if `code_engine_project_id` is `null`. | `bool` | `true` | no |
| <a name="input_add_random_suffix_icr_namespace"></a> [add\_random\_suffix\_icr\_namespace](#input\_add\_random\_suffix\_icr\_namespace) | Whether to add a randomly generated 4-character suffix to the newly created ICR namespace. | `bool` | `true` | no |
| <a name="input_cloud_pak_deployer_release"></a> [cloud\_pak\_deployer\_release](#input\_cloud\_pak\_deployer\_release) | The GIT release of Cloud Pak Deployer version to build from. View releases at: https://github.com/IBM/cloud-pak-deployer/releases. | `string` | `"v3.1.8"` | no |
| <a name="input_code_engine_project_id"></a> [code\_engine\_project\_id](#input\_code\_engine\_project\_id) | If you want to use an existing project, you can pass the Code Engine project ID. Alternatively use `code_engine_project_name` to create a new project. | `string` | `null` | no |
| <a name="input_code_engine_project_name"></a> [code\_engine\_project\_name](#input\_code\_engine\_project\_name) | The name of the Code Engine project to be created for the image build. Alternatively use `code_engine_project_id` to use existing project. If `add_random_suffix_code_engine_project` is set to true, a randomly generated 4-character suffix will be added to this value. | `string` | `"cpd"` | no |
| <a name="input_container_registry_namespace"></a> [container\_registry\_namespace](#input\_container\_registry\_namespace) | The name of the Container Registry namespace to create. If `add_random_suffix_icr_namespace` is set to true, a randomly generated 4-character suffix will be added to this value. | `string` | `"cpd"` | no |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | The IBM Cloud API key to deploy resources. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region where Code Engine and Container Registry resources will be provisioned. To use the 'Global' Container Registry location set `use_global_container_registry_location` to true. | `string` | `"us-south"` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The ID of the resource group to create resource in. If not set, Default resource group will be used. | `string` | `null` | no |
| <a name="input_use_global_container_registry_location"></a> [use\_global\_container\_registry\_location](#input\_use\_global\_container\_registry\_location) | Set to true to create the Container Registry namespace in the 'Global' location. If set to false, the namespace will be created in the region provided in the `region` input value. | `bool` | `false` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_code_engine_project_id"></a> [code\_engine\_project\_id](#output\_code\_engine\_project\_id) | The ID of the code engine project that used |
| <a name="output_code_engine_project_name"></a> [code\_engine\_project\_name](#output\_code\_engine\_project\_name) | The name of the code engine project that was used |
| <a name="output_container_registry_namespace"></a> [container\_registry\_namespace](#output\_container\_registry\_namespace) | The name of the container registry namespace |
| <a name="output_container_registry_output_image"></a> [container\_registry\_output\_image](#output\_container\_registry\_output\_image) | The path to the cpd container that was built |
| <a name="output_container_registry_server"></a> [container\_registry\_server](#output\_container\_registry\_server) | The url of the container registry |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
