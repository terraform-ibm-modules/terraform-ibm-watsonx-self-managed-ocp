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
