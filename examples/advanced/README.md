# Advanced example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<p>
  <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=watsonx-self-managed-ocp-advanced-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-watsonx-self-managed-ocp/tree/main/examples/advanced">
    <img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics">
  </a><br>
  ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
</p>
<!-- END SCHEMATICS DEPLOY HOOK -->


This advanced example demonstrates all configuration options available in the watsonx-self-managed-ocp module, including:

## Features Demonstrated

### 1. Flexible Cluster Configuration
- **New Cluster Creation**: Provisions a new Red Hat OpenShift cluster with configurable worker pools
- **Existing Cluster Support**: Can deploy to an existing cluster by setting `existing_cluster_name`
- **Network Configuration**: Supports both public and private-only VPC configurations

### 2. ICR Image Build Use Case
This example is particularly useful for demonstrating the **automatic image build and publish to IBM Container Registry (ICR)** feature:

- Set `cloud_pak_deployer_image = null` to trigger automatic image building
- Set `create_public_gateway = false` for a secure private-only cluster
- Set `disable_outbound_traffic_protection = true` to allow Code Engine to build images
- The module will automatically:
  - Build the Cloud Pak Deployer image using IBM Code Engine
  - Publish the image to IBM Container Registry (ICR)
  - Deploy watsonx using the built image from ICR

### 3. WatsonX Services
- Configurable installation of watsonx.ai
- Configurable installation of watsonx.data
- Optional Watson Assistant
- Optional Watson Discovery

### 4. Custom Image Configuration
- Use pre-built images from external registries (default)
- Trigger automatic image build by setting `cloud_pak_deployer_image = null`
- Provide custom image secrets if needed

## Usage

### Standard Deployment (Pre-built Image)
```hcl
module "watsonx_advanced" {
  source = "terraform-ibm-modules/watsonx-self-managed-ocp/ibm//examples/advanced"
  
  ibmcloud_api_key    = var.ibmcloud_api_key
  prefix              = "my-watsonx"
  region              = "us-south"
  cpd_admin_password  = var.cpd_admin_password
  cpd_entitlement_key = var.cpd_entitlement_key
  
  # Use default pre-built image
  # cloud_pak_deployer_image is set to default value
}
```

### ICR Image Build Deployment (Secure Private Cluster)
```hcl
module "watsonx_advanced" {
  source = "terraform-ibm-modules/watsonx-self-managed-ocp/ibm//examples/advanced"
  
  ibmcloud_api_key    = var.ibmcloud_api_key
  prefix              = "my-watsonx"
  region              = "us-south"
  cpd_admin_password  = var.cpd_admin_password
  cpd_entitlement_key = var.cpd_entitlement_key
  
  # Secure private cluster configuration
  create_public_gateway               = false  # No public gateway
  disable_outbound_traffic_protection = true   # Required for Code Engine
  
  # Trigger automatic image build and publish to ICR
  cloud_pak_deployer_image = null
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| ibm | >= 1.71.3, < 2.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ibmcloud_api_key | The IBM Cloud API key | `string` | n/a | yes |
| cpd_admin_password | Password for Cloud Pak for Data admin user | `string` | n/a | yes |
| cpd_entitlement_key | Cloud Pak for Data entitlement key | `string` | n/a | yes |
| prefix | Unique identifier prepended to resources | `string` | `"ocp-cp4d"` | no |
| region | IBM Cloud region | `string` | `"us-south"` | no |
| create_public_gateway | Create public gateway for VPC | `bool` | `true` | no |
| disable_outbound_traffic_protection | Disable outbound traffic protection | `bool` | `true` | no |
| cloud_pak_deployer_image | Cloud Pak Deployer image (null = auto-build) | `string` | `"quay.io/..."` | no |
| existing_cluster_name | Name of existing cluster | `string` | `null` | no |
| watsonx_ai_install | Install watsonx.ai | `bool` | `false` | no |
| watsonx_data_install | Install watsonx.data | `bool` | `false` | no |
| watson_assistant_install | Install Watson Assistant | `bool` | `false` | no |
| watson_discovery_install | Install Watson Discovery | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | ID of the OpenShift cluster |
| cluster_name | Name of the OpenShift cluster |
| cpd_url | URL to access Cloud Pak for Data |
| cpd_admin_password | Password for CPD admin user |
| cloud_pak_deployer_image_used | The image that was used (provided or built) |

## Notes

- When `cloud_pak_deployer_image = null`, the module builds the image using IBM Code Engine and publishes to ICR
- For secure private clusters, set `create_public_gateway = false` and `disable_outbound_traffic_protection = true`
- The `disable_outbound_traffic_protection` setting is required for Code Engine to access GitHub and build images
- All operations use IBM Cloud private endpoints when deploying to private clusters
