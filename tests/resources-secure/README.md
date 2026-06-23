# Secure Private Cluster Test Resources

This directory contains Terraform configuration for provisioning a **secure private-only OpenShift cluster** used in the ICR image build test.

## Key Security Features

- **No Public Gateway**: Subnets do not have public gateways attached, preventing direct internet access
- **Outbound Traffic Protection Enabled**: `disable_outbound_traffic_protection = false` ensures the cluster cannot initiate outbound connections
- **Private-only Configuration**: Designed to test deployment in highly secure, air-gapped environments

## Purpose

This configuration is used by [`TestRunICRImageBuildWithSecurePrivateCluster`](../pr_test.go:248) to verify that:
1. The Cloud Pak Deployer image can be built and published to IBM Cloud Container Registry (ICR)
2. The deployment works correctly when `cloud_pak_deployer_image` is set to `null`
3. All operations function properly in a secure, private-only cluster environment

## Differences from Standard Test Resources

Compared to [`tests/resources/`](../resources/), this configuration:
- Removes the `ibm_is_public_gateway` resource
- Does not attach a public gateway to subnets
- Sets `disable_outbound_traffic_protection = false` (vs `true` in standard resources)

## Usage

This directory is automatically used by the test framework. The test copies these files to a temporary directory before execution.
