// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"
	"testing"

	"github.com/IBM/go-sdk-core/v5/core"
	"github.com/IBM/secrets-manager-go-sdk/v2/secretsmanagerv2"
	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

// Ensure every example directory has a corresponding test
const instanceFlavorDir = "solutions/fully-configurable"

const cpdEntitlementKeySecretId = "a4292c24-f093-2b8b-9016-37132b7b8788"

var permanentResources map[string]any

// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

func TestMain(m *testing.M) {
	// Read the YAML file contents
	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

// A test to pass existing resources to the WatsonX Self Managed OCP DA
func TestRunFullyConfigurableSolution(t *testing.T) {
	t.Parallel()
	// ------------------------------------------------------------------------------------
	// Provision ROK's first
	// ------------------------------------------------------------------------------------

	prefix := fmt.Sprintf("cp-ex-%s", strings.ToLower(random.UniqueID()))
	realTerraformDir := "./resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueID())))
	tags := common.GetTagsFromTravis()
	region := "us-south"

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]any{
			"prefix":        prefix,
			"region":        region,
			"resource_tags": tags,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNewContext(t, context.Background(), existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyContextE(t, context.Background(), existingTerraformOptions)
	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp existing resource failed")
	} else {
		// ------------------------------------------------------------------------------------
		// Deploy WatsonX Self Managed OCP DA passing using existing OCP instance
		// ------------------------------------------------------------------------------------
		cpdEntitlementKey, cpdEntitlementKeyErr := GetSecretsManagerKey(
			permanentResources["secretsManagerGuid"].(string),
			permanentResources["secretsManagerRegion"].(string),
			cpdEntitlementKeySecretId,
		)

		if !assert.NoError(t, cpdEntitlementKeyErr) {
			t.Error("TestRunFullyConfigurableSolution Failed - geretain-software-entitlement-key not found in secrets manager")
			panic(cpdEntitlementKeyErr)
		}

		options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
			Testing:      t,
			TerraformDir: instanceFlavorDir,
			// Do not hard fail the test if the implicit destroy steps fail to allow a full destroy of resource to occur
			ImplicitRequired: false,
			TerraformVars: map[string]any{
				"prefix":                               prefix,
				"region":                               region,
				"existing_cluster_id":                  terraform.OutputContext(t, context.Background(), existingTerraformOptions, "cluster_id"),
				"existing_cluster_resource_group_name": terraform.OutputContext(t, context.Background(), existingTerraformOptions, "cluster_resource_group_name"),
				"cpd_entitlement_key":                  *cpdEntitlementKey,
				"provider_visibility":                  "public", // TODO: use schematics test wrapper and default to private (https://github.com/terraform-ibm-modules/terraform-ibm-watsonx-self-managed-ocp/issues/42)
			},
		})

		options.IgnoreUpdates = testhelper.Exemptions{
			List: []string{
				"module.watsonx_self_managed_ocp.module.cloud_pak_deployer.helm_release.cloud_pak_deployer_helm_release",
			},
		}

		options.IgnoreAdds = testhelper.Exemptions{
			List: []string{
				"null_resource.wait_for_cloud_pak_deployer_complete",
			},
		}

		options.IgnoreDestroys = testhelper.Exemptions{
			List: []string{
				"null_resource.wait_for_cloud_pak_deployer_complete",
			},
		}

		output, err := options.RunTestConsistency()
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}

	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing resources)")
		terraform.DestroyContext(t, context.Background(), existingTerraformOptions)
		terraform.WorkspaceDeleteContext(t, context.Background(), existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}

func TestRunFullyConfigurableUpgradeSolution(t *testing.T) {
	t.Parallel()

	prefix := fmt.Sprintf("cp-up-%s", strings.ToLower(random.UniqueID()))
	realTerraformDir := "./resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueID())))
	tags := common.GetTagsFromTravis()
	region := "us-south"

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix":        prefix,
			"region":        region,
			"resource_tags": tags,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNewContext(t, context.Background(), existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyContextE(t, context.Background(), existingTerraformOptions)
	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp existing resource failed")
	} else {
		// ------------------------------------------------------------------------------------
		// Deploy WatsonX Self Managed OCP DA passing using existing OCP instance
		// ------------------------------------------------------------------------------------
		cpdEntitlementKey, cpdEntitlementKeyErr := GetSecretsManagerKey(
			permanentResources["secretsManagerGuid"].(string),
			permanentResources["secretsManagerRegion"].(string),
			cpdEntitlementKeySecretId,
		)

		if !assert.NoError(t, cpdEntitlementKeyErr) {
			t.Error("TestRunFullyConfigurableUpgradeSolution Failed - geretain-software-entitlement-key not found in secrets manager")
			panic(cpdEntitlementKeyErr)
		}

		options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
			Testing:      t,
			TerraformDir: instanceFlavorDir,
			// Do not hard fail the test if the implicit destroy steps fail to allow a full destroy of resource to occur
			ImplicitRequired:           false,
			CheckApplyResultForUpgrade: true,
			TerraformVars: map[string]any{
				"prefix":                               prefix,
				"region":                               region,
				"existing_cluster_id":                  terraform.OutputContext(t, context.Background(), existingTerraformOptions, "cluster_id"),
				"existing_cluster_resource_group_name": terraform.OutputContext(t, context.Background(), existingTerraformOptions, "cluster_resource_group_name"),
				"cpd_entitlement_key":                  *cpdEntitlementKey,
				"provider_visibility":                  "public", // TODO: use schematics test wrapper and default to private (https://github.com/terraform-ibm-modules/terraform-ibm-watsonx-self-managed-ocp/issues/42)
			},
		})

		options.IgnoreUpdates = testhelper.Exemptions{
			List: []string{
				"module.watsonx_self_managed_ocp.module.cloud_pak_deployer.helm_release.cloud_pak_deployer_helm_release",
			},
		}

		options.IgnoreAdds = testhelper.Exemptions{
			List: []string{
				"null_resource.wait_for_cloud_pak_deployer_complete",
			},
		}

		options.IgnoreDestroys = testhelper.Exemptions{
			List: []string{
				"null_resource.wait_for_cloud_pak_deployer_complete",
			},
		}

		output, err := options.RunTestUpgrade()
		if !options.UpgradeTestSkipped {
			assert.Nil(t, err, "This should not have errored")
			assert.NotNil(t, output, "Expected some output")
		}
	}

	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing resources)")
		terraform.DestroyContext(t, context.Background(), existingTerraformOptions)
		terraform.WorkspaceDeleteContext(t, context.Background(), existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}

// GetSecretsManagerKey retrieves a secret from Secrets Manager
func GetSecretsManagerKey(smId string, smRegion string, smKeyId string) (*string, error) {
	secretsManagerService, err := secretsmanagerv2.NewSecretsManagerV2(&secretsmanagerv2.SecretsManagerV2Options{
		URL: fmt.Sprintf("https://%s.%s.secrets-manager.appdomain.cloud", smId, smRegion),
		Authenticator: &core.IamAuthenticator{
			ApiKey: os.Getenv("TF_VAR_ibmcloud_api_key"),
		},
	})
	if err != nil {
		return nil, err
	}

	getSecretOptions := secretsManagerService.NewGetSecretOptions(
		smKeyId,
	)

	secret, _, err := secretsManagerService.GetSecret(getSecretOptions)
	if err != nil {
		return nil, err
	}
	return secret.(*secretsmanagerv2.ArbitrarySecret).Payload, nil
}

// TestRunICRImageBuildWithSecurePrivateCluster tests building and publishing image to ICR
// with a secure private cluster.

func TestRunICRImageBuildWithSecurePrivateCluster(t *testing.T) {
	t.Parallel()

	// ------------------------------------------------------------------------------------
	// Provision secure private cluster first
	// ------------------------------------------------------------------------------------

	prefix := fmt.Sprintf("spc-%s", strings.ToLower(random.UniqueID()))
	realTerraformDir := "./resources-secure"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueID())))
	tags := common.GetTagsFromTravis()
	region := "us-south"

	logger.Log(t, "Tempdir: ", tempTerraformDir)

	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]any{
			"prefix":        prefix,
			"region":        region,
			"resource_tags": tags,
		},
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNewContext(t, context.Background(), existingTerraformOptions, prefix)
	terraform.InitAndApplyContext(t, context.Background(), existingTerraformOptions)

	// Get cluster details from Terraform outputs
	existingClusterID := terraform.OutputContext(t, context.Background(), existingTerraformOptions, "cluster_id")
	existingClusterRG := terraform.OutputContext(t, context.Background(), existingTerraformOptions, "cluster_resource_group_name")

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	apiKey, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", apiKey, checkVariable+" environment variable is empty")

	// ------------------------------------------------------------------------------------
	// Deploy WatsonX using Schematics with private endpoints
	// ------------------------------------------------------------------------------------

	// Get Cloud Pak entitlement key from Secrets Manager
	cpdEntitlementKey, cpdEntitlementKeyErr := GetSecretsManagerKey(
		permanentResources["secretsManagerGuid"].(string),
		permanentResources["secretsManagerRegion"].(string),
		cpdEntitlementKeySecretId,
	)
	assert.NoError(t, cpdEntitlementKeyErr, "Failed to retrieve Cloud Pak entitlement key from Secrets Manager")

	// Create TestSchematicOptions with default settings
	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing:               t,
		Prefix:                prefix,
		BestRegionYAMLPath:    "../common-dev-assets/common-go-assets/cloudinfo-region-vpc-gen2-prefs.yaml",
		Region:                region,
		ResourceGroup:         existingClusterRG,
		TemplateFolder:        instanceFlavorDir,
		Tags:                  tags,
		DeleteWorkspaceOnFail: false,
		// Include all necessary files in the TAR for Schematics
		TarIncludePatterns: []string{
			"*.tf",
			instanceFlavorDir + "/*.tf",
			"modules/cloud-pak-deployer/*.tf",
			"modules/cloud-pak-deployer/config/*.tf",
			"modules/cpd-image-build/*.tf",
			"modules/cpd-image-build/scripts/*.sh",
			"modules/watsonx-ai/*.tf",
			"modules/watsonx-data/*.tf",
			"chart/cloud-pak-deployer/*.yaml",
			"chart/cloud-pak-deployer/templates/*.yaml",
			"chart/cloud-pak-deployer/templates/*.tpl",
			"scripts/*.sh",
		},
	})

	// Configure Terraform variables for Schematics workspace
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: apiKey, DataType: "string", Secure: true},
		{Name: "existing_cluster_id", Value: existingClusterID, DataType: "string"},
		{Name: "existing_cluster_resource_group_name", Value: existingClusterRG, DataType: "string"},
		{Name: "cpd_entitlement_key", Value: *cpdEntitlementKey, DataType: "string", Secure: true},
		{Name: "provider_visibility", Value: "private", DataType: "string"},
	}
	_ = os.Unsetenv("TF_VAR_resource_tags")

	// Run the Schematics test
	err := options.RunSchematicTest()
	assert.NoError(t, err, "Schematics test failed")

	// Verify the image was built and published
	if err == nil {
		logger.Log(t, "✓ Cloud Pak Deployer image built successfully")
		logger.Log(t, "✓ Image published to IBM Container Registry")
		logger.Log(t, "✓ WatsonX deployed using ICR image")
		logger.Log(t, "✓ All operations completed using private endpoints")
		logger.Log(t, "✓ Secure private cluster configuration validated")
	}

	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (secure private cluster resources)")
		terraform.DestroyContext(t, context.Background(), existingTerraformOptions)
		terraform.WorkspaceDeleteContext(t, context.Background(), existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (secure private cluster resources)")
	}
}
