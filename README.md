# Watsonx (Self-Managed) on Red Hat OpenShift

[![Stable (With quality checks)](https://img.shields.io/badge/Status-Stable%20(With%20quality%20checks)-green)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-watsonx-self-managed-ocp?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-watsonx-self-managed-ocp/releases/latest)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

Deploy Watsonx services on an existing Red Hat OpenShift cluster.

Cluster must meet the minimum requirements to deploy Cloud Pak for Data [Learn more](https://www.ibm.com/docs/en/cloud-paks/cp-data/5.1.x?topic=overview-cloud-pak-data).

The following services are currently supported:
- watsonx.ai
- Watson Assistant
- Watson Discovery
- Watson Data

![Architecture diagram](../../reference-architecture/deployable-architecture-cp4d.svg)

<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGIN OVERVIEW HOOK -->
## Overview
* [terraform-ibm-watsonx-self-managed-ocp](#terraform-ibm-watsonx-self-managed-ocp)
* [Submodules](./modules)
    * [cpd-image-build](./modules/cpd-image-build)
* [Examples](./examples)
    * [Basic example](./examples/basic)
* [Contributing](#contributing)
<!-- END OVERVIEW HOOK -->

## terraform-ibm-watsonx-self-managed-ocp

### Usage

```hcl
module "watsonx_self_managed_ocp" {
  source                    = "terraform-ibm-modules/watsonx-self-managed-ocp/ibm"
  version                   = "X.X.X" # Replace "X.X.X" with a release version to lock into a specific release
  ibmcloud_api_key          = "xxxxxxxxxxxxxxxxx"   # pragma: allowlist secret
  cluster_name              = "my-ocp-cluster"
  cluster_resource_group_id = "xxxxxxxxxxxxxxxxxx"
  cpd_admin_password        = "XXXXXXXX"
  cpd_entitlement_key       = "XXXXXXXX"
}
```

### Required IAM access policies

You need the following permissions to run this module.

* Account Management
  * **All Resource Groups** service
    * `Viewer` platform access
* IAM Services
  * **Kubernetes Service**
    * `Administrator` platform access
    * `Manager` service access
  * **VPC Infrastructure**
    * `Administrator` platform access
    * `Manager` service access
  * **Container Registry** (if building image)
    * `Administrator` platform access
    * `Manager` service access
  * **Code Engine service** (if building image)
    * `Editor` platform access
    * `Writer` service access

For more information on access and permissions, see [IBM Cloud IAM service roles and actions](https://cloud.ibm.com/docs/account?topic=account-iam-service-roles-actions).

<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >=1.79.1, <2.0.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_build_cpd_image"></a> [build\_cpd\_image](#module\_build\_cpd\_image) | ./modules/cpd-image-build | n/a |
| <a name="module_cloud_pak_deployer"></a> [cloud\_pak\_deployer](#module\_cloud\_pak\_deployer) | ./modules/cloud-pak-deployer | n/a |
| <a name="module_config"></a> [config](#module\_config) | ./modules/cloud-pak-deployer/config | n/a |
| <a name="module_watsonx_ai"></a> [watsonx\_ai](#module\_watsonx\_ai) | ./modules/watsonx-ai | n/a |
| <a name="module_watsonx_data"></a> [watsonx\_data](#module\_watsonx\_data) | ./modules/watsonx-data | n/a |

### Resources

| Name | Type |
|------|------|
| [ibm_container_addons.odf_cluster_addon](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/resources/container_addons) | resource |
| [ibm_container_vpc_cluster.cluster_info](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_vpc_cluster) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_random_suffix_code_engine_project"></a> [add\_random\_suffix\_code\_engine\_project](#input\_add\_random\_suffix\_code\_engine\_project) | Whether to add a randomly generated 4-character suffix to the newly created Code Engine project. Only applies if `code_engine_project_id` is `null`. | `bool` | `true` | no |
| <a name="input_add_random_suffix_icr_namespace"></a> [add\_random\_suffix\_icr\_namespace](#input\_add\_random\_suffix\_icr\_namespace) | Whether to add a randomly generated 4-character suffix to the newly created ICR namespace. | `bool` | `true` | no |
| <a name="input_cloud_pak_deployer_image"></a> [cloud\_pak\_deployer\_image](#input\_cloud\_pak\_deployer\_image) | Cloud Pak Deployer image to use. If `null`, the image will be built using Code Engine and publish to a private Container Registry namespace. | `string` | `"quay.io/cloud-pak-deployer/cloud-pak-deployer:v3.2.1@sha256:311952546b0cbec425435269e9a1e7d8a4230dbcde6f257d1bd80461cb82f284"` | no |
| <a name="input_cloud_pak_deployer_release"></a> [cloud\_pak\_deployer\_release](#input\_cloud\_pak\_deployer\_release) | The GIT release of Cloud Pak Deployer version to build from. Only applies if `cloud_pak_deployer_image` is `null`. View releases at: https://github.com/IBM/cloud-pak-deployer/releases. | `string` | `"v3.2.1"` | no |
| <a name="input_cloud_pak_deployer_secret"></a> [cloud\_pak\_deployer\_secret](#input\_cloud\_pak\_deployer\_secret) | Secret for accessing the Cloud Pak Deployer image. If `null`, a default secret will be created. | <pre>object({<br/>    username = string<br/>    password = string<br/>    server   = string<br/>    email    = string<br/>  })</pre> | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of an existing Red Hat OpenShift cluster to install watsonX onto | `string` | n/a | yes |
| <a name="input_cluster_resource_group_id"></a> [cluster\_resource\_group\_id](#input\_cluster\_resource\_group\_id) | The resource group ID of the cluster provided in `cluster_name` | `string` | n/a | yes |
| <a name="input_code_engine_project_id"></a> [code\_engine\_project\_id](#input\_code\_engine\_project\_id) | If you want to use an existing project, you can pass the Code Engine project ID. Alternatively use `code_engine_project_name` to create a new project. Only applies if `cloud_pak_deployer_image` is `null`. | `string` | `null` | no |
| <a name="input_code_engine_project_name"></a> [code\_engine\_project\_name](#input\_code\_engine\_project\_name) | The name of the Code Engine project to be created for the image build. Alternatively use `code_engine_project_id` to use existing project. Only applies if `cloud_pak_deployer_image` is `null`. If `add_random_suffix_code_engine_project` is set to true, a randomly generated 4-character suffix will be added to this value. | `string` | `"cpd"` | no |
| <a name="input_container_registry_namespace"></a> [container\_registry\_namespace](#input\_container\_registry\_namespace) | The name of the Container Registry namespace to create. Only applies if `cloud_pak_deployer_image` is `null`. If `add_random_suffix_icr_namespace` is set to true, a randomly generated 4-character suffix will be added to this value. | `string` | `"cpd"` | no |
| <a name="input_cpd_accept_license"></a> [cpd\_accept\_license](#input\_cpd\_accept\_license) | When set to 'true', it is understood that the user has read the terms of the Cloud Pak license(s) and agrees to the terms outlined. | `bool` | `true` | no |
| <a name="input_cpd_admin_password"></a> [cpd\_admin\_password](#input\_cpd\_admin\_password) | Password for the Cloud Pak for Data admin user. | `string` | n/a | yes |
| <a name="input_cpd_entitlement_key"></a> [cpd\_entitlement\_key](#input\_cpd\_entitlement\_key) | Cloud Pak for Data entitlement key for access to the IBM Entitled Registry. Can be fetched from https://myibm.ibm.com/products-services/containerlibrary. | `string` | n/a | yes |
| <a name="input_cpd_version"></a> [cpd\_version](#input\_cpd\_version) | Cloud Pak for Data version to install.  Only version 5.x.x is supported, latest versions can be found [here](https://www.ibm.com/docs/en/cloud-paks/cp-data?topic=versions-cloud-pak-data). | `string` | `"5.1.3"` | no |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | The IBM Cloud API key to deploy resources. | `string` | n/a | yes |
| <a name="input_install_odf_cluster_addon"></a> [install\_odf\_cluster\_addon](#input\_install\_odf\_cluster\_addon) | Install the ODF cluster add-on. | `bool` | `true` | no |
| <a name="input_odf_config"></a> [odf\_config](#input\_odf\_config) | Configuration for the ODF addon. Only applies if `install_odf_cluster_addon` is true. | `map(string)` | <pre>{<br/>  "addSingleReplicaPool": "false",<br/>  "billingType": "essentials",<br/>  "clusterEncryption": "false",<br/>  "disableNoobaaLB": "false",<br/>  "enableNFS": "false",<br/>  "encryptionInTransit": "false",<br/>  "hpcsBaseUrl": "",<br/>  "hpcsEncryption": "false",<br/>  "hpcsInstanceId": "",<br/>  "hpcsSecretName": "",<br/>  "hpcsServiceName": "",<br/>  "hpcsTokenUrl": "",<br/>  "ignoreNoobaa": "true",<br/>  "numOfOsd": "1",<br/>  "ocsUpgrade": "false",<br/>  "odfDeploy": "true",<br/>  "osdDevicePaths": "",<br/>  "osdSize": "512Gi",<br/>  "osdStorageClassName": "ibmc-vpc-block-metro-10iops-tier",<br/>  "resourceProfile": "balanced",<br/>  "taintNodes": "false",<br/>  "useCephRBDAsDefaultStorageClass": "false",<br/>  "workerNodes": "all",<br/>  "workerPool": ""<br/>}</pre> | no |
| <a name="input_odf_version"></a> [odf\_version](#input\_odf\_version) | Version of OpenShift Data Foundation (ODF) add-on to install. Only applies if `install_odf_cluster_addon` is true. | `string` | `"4.18.0"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region where Code Engine and Container Registry resources will be provisioned. Only applies if `cloud_pak_deployer_image` is `null`. To use the 'Global' Container Registry location set `use_global_container_registry_location` to true. | `string` | `"us-south"` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The ID of the resource group where Code Engine and Container Registry resources will be provisioned. Only applies if `cloud_pak_deployer_image` is `null`. If not set, Default resource group will be used. | `string` | `null` | no |
| <a name="input_use_global_container_registry_location"></a> [use\_global\_container\_registry\_location](#input\_use\_global\_container\_registry\_location) | Set to true to create the Container Registry namespace in the 'Global' location. If set to false, the namespace will be created in the region provided in the `region` input value. Only applies if `cloud_pak_deployer_image` is `null`. | `bool` | `false` | no |
| <a name="input_watson_assistant_install"></a> [watson\_assistant\_install](#input\_watson\_assistant\_install) | If watsonx.ai is being installed, also install watson assistant | `bool` | `false` | no |
| <a name="input_watson_discovery_install"></a> [watson\_discovery\_install](#input\_watson\_discovery\_install) | If watsonx.ai is being installed, also install watson discovery | `bool` | `false` | no |
| <a name="input_watsonx_ai_install"></a> [watsonx\_ai\_install](#input\_watsonx\_ai\_install) | Determine whether the watsonx.ai cartridge for the deployer will be installed | `bool` | `false` | no |
| <a name="input_watsonx_ai_models"></a> [watsonx\_ai\_models](#input\_watsonx\_ai\_models) | List of watsonx.ai models to install. Information on the foundation models including pre-reqs can be found here - https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=install-foundation-models. Use the ModelID as input | `list(string)` | <pre>[<br/>  "ibm-granite-13b-instruct-v2"<br/>]</pre> | no |
| <a name="input_watsonx_data_install"></a> [watsonx\_data\_install](#input\_watsonx\_data\_install) | Determine whether the watsonx.data cartridge for the deployer will be installed | `bool` | `false` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloud_pak_deployer_image"></a> [cloud\_pak\_deployer\_image](#output\_cloud\_pak\_deployer\_image) | The Cloud Pak Deployer image used. |
| <a name="output_cloud_pak_deployer_secret"></a> [cloud\_pak\_deployer\_secret](#output\_cloud\_pak\_deployer\_secret) | The secret used for accessing the Cloud Pak Deployer image. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the OpenShift cluster. |
| <a name="output_code_engine_project_name"></a> [code\_engine\_project\_name](#output\_code\_engine\_project\_name) | The name of the code engine project that was created |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
