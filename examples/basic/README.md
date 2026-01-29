# Basic example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=watsonx-self-managed-ocp-basic-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-watsonx-self-managed-ocp/tree/main/examples/basic"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


<!--
The basic example should call the module(s) stored in this repository with a basic configuration.
Note, there is a pre-commit hook that will take the title of each example and include it in the repos main README.md.
The text below should describe exactly what resources are provisioned / configured by the example.
-->

This basic example demonstrates how to deploy IBM Cloud Pak for Data and optional watsonx services on a new Red Hat OpenShift cluster using this module.

It provisions the following resources:

- A new resource group (if not provided)
- A new VPC, subnet, and public gateway
- A new Red Hat OpenShift cluster with configurable worker pools
- IBM Cloud Pak for Data installation
- Optional watsonx services (watsonx.ai, watsonx.data, Watson Assistant, Watson Discovery)

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
