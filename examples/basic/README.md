# Basic example

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
