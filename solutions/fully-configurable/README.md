<!-- Update this title with a descriptive name. Use sentence case. -->
# Watsonx (Self-Managed) on Red Hat OpenShift

<!--
Update status and "latest release" badges:
  1. For the status options, see https://terraform-ibm-modules.github.io/documentation/#/badge-status
  2. Update the "latest release" badge to point to the correct module's repo. Replace "terraform-ibm-module-template" in two places.
-->
[![Incubating (Not yet consumable)](https://img.shields.io/badge/status-Incubating%20(Not%20yet%20consumable)-red)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-watsonx-self-managed-ocp?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-watsonx-self-managed-ocp/releases/latest)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

<!--
Add a description of modules in this repo.
Expand on the repo short description in the .github/settings.yml file.

For information, see "Module names and descriptions" at
https://terraform-ibm-modules.github.io/documentation/#/implementation-guidelines?id=module-names-and-descriptions
-->

Deploy Watsonx services on an existing Red Hat OpenShift cluster.

You can:
- **Use an existing OpenShift cluster** by providing its name and resource group

Cluster must meet the minimum requirements to deploy Cloud Pak for Data [Learn more](https://www.ibm.com/docs/en/cloud-paks/cp-data/5.1.x?topic=overview-cloud-pak-data).

The following services are currently supported:
- watsonx.ai
- Watson Assistant
- Watson Discovery
- Watson Data

![Architecture diagram](../../reference-architecture/deployable-architecture-cp4d.svg)

<!-- The following content is automatically populated by the pre-commit hook -->
<!-- BEGIN OVERVIEW HOOK -->
## Overview
* [terraform-ibm-watsonx-self-managed-ocp](#terraform-ibm-watsonx-self-managed-ocp)
* [Contributing](#contributing)
<!-- END OVERVIEW HOOK -->


<!--
If this repo contains any reference architectures, uncomment the heading below and link to them.
(Usually in the `/reference-architectures` directory.)
See "Reference architecture" in the public documentation at
https://terraform-ibm-modules.github.io/documentation/#/implementation-guidelines?id=reference-architecture
-->
<!-- ## Reference architectures -->


<!-- Replace this heading with the name of the root level module (the repo name) -->
## terraform-ibm-watsonx-self-managed-ocp

### Usage

<!--
Add an example of the use of the module in the following code block.

Use real values instead of "var.<var_name>" or other placeholder values
unless real values don't help users know what to change.
-->

```hcl
module "watsonx_self_managed_ocp" {
  source                            = "terraform-ibm-modules/watsonx-self-managed-ocp/ibm"
  ibmcloud_api_key                  = "xXXxxxxXXXxxxx"  # pragma: allowlist secret
  prefix                            = "cp4d"
  region                            = "us-south"
  existing_cluster_name             = "cluster1"
  existing_resource_group_name      = "rg-cluster-1"
  cpd_admin_password                = "xXXxxxxXXXxxxx"  # pragma: allowlist secret
  cpd_entitlement_key               = "xXXxxxxXXXxxxx"  # pragma: allowlist secret
}
```

### Required access policies

<!-- PERMISSIONS REQUIRED TO RUN MODULE
If this module requires permissions, uncomment the following block and update
the sample permissions, following the format.
Replace the 'Sample IBM Cloud' service and roles with applicable values.
The required information can usually be found in the services official
IBM Cloud documentation.
To view all available service permissions, you can go in the
console at Manage > Access (IAM) > Access groups and click into an existing group
(or create a new one) and in the 'Access' tab click 'Assign access'.
-->

You need the following permissions to run this module:

- Service
    - **Resource group only**
        - `Viewer` access on the specific resource group
    - **Kubernetes** service
        - `Viewer` platform access
        - `Manager` service access
    - **Code Engine service
        - `Administrator` platform access
        - `Manager` service access
    - **Container Registry service
        - `Administrator` platform access
        - `Manager` service access


<!-- The following content is automatically populated by the pre-commit hook -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | >= 2.3.4 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.8.0, <3.0.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | 1.79.1 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1, < 4.0.0 |
| <a name="requirement_shell"></a> [shell](#requirement\_shell) | 1.7.10 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | terraform-ibm-modules/resource-group/ibm | 1.2.0 |
| <a name="module_watsonx_self_managed_ocp"></a> [watsonx\_self\_managed\_ocp](#module\_watsonx\_self\_managed\_ocp) | ../.. | n/a |

### Resources

| Name | Type |
|------|------|
| [null_resource.wait_for_cloud_pak_deployer_complete](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [external_external.schematics](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/ibm-cloud/ibm/1.79.1/docs/data-sources/container_cluster_config) | data source |
| [ibm_iam_auth_token.tokendata](https://registry.terraform.io/providers/ibm-cloud/ibm/1.79.1/docs/data-sources/iam_auth_token) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloud_pak_deployer_image"></a> [cloud\_pak\_deployer\_image](#input\_cloud\_pak\_deployer\_image) | Cloud Pak Deployer image to use. If `null`, the image will be built using Code Engine. | `string` | `"quay.io/cloud-pak-deployer/cloud-pak-deployer"` | no |
| <a name="input_cloud_pak_deployer_release"></a> [cloud\_pak\_deployer\_release](#input\_cloud\_pak\_deployer\_release) | Release of Cloud Pak Deployer version to use. View releases at: https://github.com/IBM/cloud-pak-deployer/releases. | `string` | `"v3.1.8"` | no |
| <a name="input_cloud_pak_deployer_secret"></a> [cloud\_pak\_deployer\_secret](#input\_cloud\_pak\_deployer\_secret) | Secret for accessing the Cloud Pak Deployer image. If `null`, a default secret will be created # pragma: allowlist secret. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-watsonx-self-managed-ocp/tree/main/solutions/fully-configurable/DA-types.md). | <pre>object({<br/>    username = string<br/>    password = string<br/>    server   = string<br/>    email    = string<br/>  })</pre> | `null` | no |
| <a name="input_code_engine_project_id"></a> [code\_engine\_project\_id](#input\_code\_engine\_project\_id) | If you want to use an existing project, you can pass the code engine project ID and the Cloud Pak Deployer build will be built within the existing project instead of creating a new one. | `string` | `null` | no |
| <a name="input_code_engine_project_name"></a> [code\_engine\_project\_name](#input\_code\_engine\_project\_name) | If `cloud_pak_deployer_image` is `null`, it will build the image with code engine and store it within a private ICR registry. Provide a name if you want to set the name. If not defined, default will be `{prefix}-cpd-{random-suffix}`. | `string` | `null` | no |
| <a name="input_cpd_accept_license"></a> [cpd\_accept\_license](#input\_cpd\_accept\_license) | When set to `true`, it is understood that the user has read the terms of the Cloud Pak license(s) and agrees to the terms outlined. | `bool` | `true` | no |
| <a name="input_cpd_admin_password"></a> [cpd\_admin\_password](#input\_cpd\_admin\_password) | Password for the Cloud Pak for Data admin user. | `string` | `"passw0rd"` | no |
| <a name="input_cpd_entitlement_key"></a> [cpd\_entitlement\_key](#input\_cpd\_entitlement\_key) | Cloud Pak for Data entitlement key for access to the IBM Entitled Registry. Can be fetched from https://myibm.ibm.com/products-services/containerlibrary. | `string` | n/a | yes |
| <a name="input_cpd_version"></a> [cpd\_version](#input\_cpd\_version) | Cloud Pak for Data version to install.  Only version 5.x.x is supported, latest versions can be found [here](https://www.ibm.com/docs/en/cloud-paks/cp-data?topic=versions-cloud-pak-data). | `string` | `"5.0.3"` | no |
| <a name="input_existing_cluster_name"></a> [existing\_cluster\_name](#input\_existing\_cluster\_name) | Name of an existing Red Hat OpenShift cluster to create and install watsonx onto. | `string` | n/a | yes |
| <a name="input_existing_resource_group_name"></a> [existing\_resource\_group\_name](#input\_existing\_resource\_group\_name) | Resource group id of the cluster | `string` | n/a | yes |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | The IBM Cloud API key to deploy resources. | `string` | n/a | yes |
| <a name="input_install_odf_cluster_addon"></a> [install\_odf\_cluster\_addon](#input\_install\_odf\_cluster\_addon) | Install the ODF cluster addon. | `bool` | `true` | no |
| <a name="input_odf_config"></a> [odf\_config](#input\_odf\_config) | Configuration for the ODF addon. Example add on options can be found [here](https://cloud.ibm.com/docs/openshift?topic=openshift-deploy-odf-classic&interface=cli#install-odf-cli-classic) | `map(string)` | <pre>{<br/>  "addSingleReplicaPool": "false",<br/>  "billingType": "essentials",<br/>  "clusterEncryption": "false",<br/>  "disableNoobaaLB": "false",<br/>  "enableNFS": "false",<br/>  "encryptionInTransit": "false",<br/>  "hpcsBaseUrl": "",<br/>  "hpcsEncryption": "false",<br/>  "hpcsInstanceId": "",<br/>  "hpcsSecretName": "",<br/>  "hpcsServiceName": "",<br/>  "hpcsTokenUrl": "",<br/>  "ignoreNoobaa": "true",<br/>  "numOfOsd": "1",<br/>  "ocsUpgrade": "false",<br/>  "odfDeploy": "true",<br/>  "osdDevicePaths": "",<br/>  "osdSize": "512Gi",<br/>  "osdStorageClassName": "ibmc-vpc-block-metro-10iops-tier",<br/>  "prepareForDisasterRecovery": "false",<br/>  "resourceProfile": "balanced",<br/>  "taintNodes": "false",<br/>  "useCephRBDAsDefaultStorageClass": "false",<br/>  "workerNodes": "all",<br/>  "workerPool": ""<br/>}</pre> | no |
| <a name="input_odf_version"></a> [odf\_version](#input\_odf\_version) | Version of ODF to install. | `string` | `"4.16.0"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | A unique identifier for resources that is prepended to resources that are provisioned. Must begin with a lowercase letter and end with a lowercase letter or number. Must be 16 or fewer characters. | `string` | `"cp4d"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region where resources will be created. To find your VPC region, use `ibmcloud is regions` command to find available regions. | `string` | `"us-south"` | no |
| <a name="input_watson_assistant_install"></a> [watson\_assistant\_install](#input\_watson\_assistant\_install) | If watsonx.ai is being installed, also install watson assistant | `bool` | `false` | no |
| <a name="input_watson_discovery_install"></a> [watson\_discovery\_install](#input\_watson\_discovery\_install) | If watsonx.ai is being installed, also install watson discovery | `bool` | `false` | no |
| <a name="input_watsonx_ai_install"></a> [watsonx\_ai\_install](#input\_watsonx\_ai\_install) | Determine whether the watsonx.ai cartridge for the deployer will be installed | `bool` | `false` | no |
| <a name="input_watsonx_ai_models"></a> [watsonx\_ai\_models](#input\_watsonx\_ai\_models) | List of watsonx.ai models to install.  Information on the foundation models including pre-reqs can be found here - https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=install-foundation-models.  Use the ModelID as input | `list(string)` | <pre>[<br/>  "ibm-granite-13b-instruct-v2"<br/>]</pre> | no |
| <a name="input_watsonx_data_install"></a> [watsonx\_data\_install](#input\_watsonx\_data\_install) | Determine whether the watsonx.data cartridge for the deployer will be installed | `bool` | `false` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloud_pak_deployer_image"></a> [cloud\_pak\_deployer\_image](#output\_cloud\_pak\_deployer\_image) | The Cloud Pak Deployer image used. |
| <a name="output_cloud_pak_deployer_secret"></a> [cloud\_pak\_deployer\_secret](#output\_cloud\_pak\_deployer\_secret) | The secret used for accessing the Cloud Pak Deployer image. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the OpenShift cluster. |
| <a name="output_code_engine_project_name"></a> [code\_engine\_project\_name](#output\_code\_engine\_project\_name) | The name of the code engine project that was created |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- Leave this section as is so that your module has a link to local development environment set-up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
