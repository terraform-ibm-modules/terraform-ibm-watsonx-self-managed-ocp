// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"context"
	"fmt"
	"io/fs"
	"log"
	"os"
	"path/filepath"
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

// Use existing resource group
const resourceGroup = "geretain-test-resources"

var permanentResources map[string]any

// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

type tarIncludePatterns struct {
	excludeDirs []string

	includeFiletypes []string

	includeDirs []string
}

func getTarIncludePatternsRecursively(dir string, dirsToExclude []string, fileTypesToInclude []string) ([]string, error) {
	r := tarIncludePatterns{dirsToExclude, fileTypesToInclude, nil}
	err := filepath.WalkDir(dir, func(path string, entry fs.DirEntry, err error) error {
		return walk(&r, path, entry, err)
	})
	if err != nil {
		fmt.Println("error")
		return r.includeDirs, err
	}
	return r.includeDirs, nil
}

func walk(r *tarIncludePatterns, s string, d fs.DirEntry, err error) error {
	if err != nil {
		return err
	}
	if d.IsDir() {
		for _, excludeDir := range r.excludeDirs {
			if strings.Contains(s, excludeDir) {
				return nil
			}
		}
		if s == ".." {
			r.includeDirs = append(r.includeDirs, "*.tf")
			return nil
		}
		for _, includeFiletype := range r.includeFiletypes {
			r.includeDirs = append(r.includeDirs, strings.ReplaceAll(s+"/*"+includeFiletype, "../", ""))
		}
	}
	return nil
}

func TestMain(m *testing.M) {
	// Read the YAML file contents
	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

func setupFullyConfigurableOptions(t *testing.T, prefix string, region string) (*testschematic.TestSchematicOptions, *terraform.Options) {

	excludeDirs := []string{
		".terraform",
		".docs",
		".github",
		".git",
		".idea",
		"common-dev-assets",
		"examples",
		"tests",
		"reference-architectures",
	}
	includeFiletypes := []string{
		".tf",
		".yaml",
		".py",
		".tpl",
		".sh",
		".json",
	}

	tarIncludePatterns, recurseErr := getTarIncludePatternsRecursively("..", excludeDirs, includeFiletypes)
	// if error producing tar patterns (very unexpected) fail test immediately
	require.NoError(t, recurseErr, "Schematic Test had unexpected error traversing directory tree")
	// The kubeconfig directories must exist in the TAR (they only contain a README.md) because
	// ibm_container_cluster_config downloads the kubeconfig into them
	tarIncludePatterns = append(tarIncludePatterns, "kubeconfig/README.md", instanceFlavorDir+"/kubeconfig/README.md")

	// Copy Terraform folder to temp dir
	realTerraformDir := "./resources"
	tempTerraformDir, err := files.CopyTerraformFolderToTemp(
		realTerraformDir, fmt.Sprintf("%s-%s", prefix, strings.ToLower(random.UniqueID())),
	)
	require.NoError(t, err, "Failed to copy Terraform folder to temp")

	// Check IBM Cloud API Key
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	logger.Log(t, "Tempdir:", tempTerraformDir)

	// Setup Terraform options
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix": prefix,
			"region": region,
		},
		Upgrade: true,
	})

	// Select or create workspace
	terraform.WorkspaceSelectOrNewContext(t, context.Background(), existingTerraformOptions, prefix)

	// Apply Terraform resources
	_, existErr := terraform.InitAndApplyContextE(t, context.Background(), existingTerraformOptions)
	if existErr != nil {
		t.Fatalf("Init and Apply of temp Terraform resources failed: %v", existErr)
		return nil, nil
	}

	// Retrieve Cloud Pak entitlement key
	cpdEntitlementKey, err := GetSecretsManagerKey(
		permanentResources["secretsManagerGuid"].(string),
		permanentResources["secretsManagerRegion"].(string),
		cpdEntitlementKeySecretId,
	)
	require.NoError(t, err, "TestRunFullyConfigurableSolution Failed - geretain-software-entitlement-key not found in secrets manager")

	// Create Schematics options
	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing:                t,
		Prefix:                 "ocp-ai",
		TemplateFolder:         instanceFlavorDir,
		TarIncludePatterns:     tarIncludePatterns,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
		Region:                 region,
		IgnoreUpdates: testhelper.Exemptions{
			List: []string{
				"module.watsonx_self_managed_ocp.module.cloud_pak_deployer.helm_release.cloud_pak_deployer_helm_release",
			},
		},
		IgnoreAdds: testhelper.Exemptions{
			List: []string{
				"terraform_data.wait_for_cloud_pak_deployer_complete",
			},
		},

		IgnoreDestroys: testhelper.Exemptions{
			List: []string{
				"terraform_data.wait_for_cloud_pak_deployer_complete",
			},
		},
	})

	// Set Terraform variables for Schematics
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "cpd_entitlement_key", Value: *cpdEntitlementKey, DataType: "string", Secure: true},
		{Name: "existing_cluster_id", Value: terraform.OutputContext(t, context.Background(), existingTerraformOptions, "cluster_id"), DataType: "string"},
		{Name: "existing_cluster_resource_group_name", Value: terraform.OutputContext(t, context.Background(), existingTerraformOptions, "cluster_resource_group_name"), DataType: "string"},
		{Name: "prefix", Value: prefix, DataType: "string"},
		{Name: "provider_visibility", Value: "public", DataType: "string"},
		{Name: "region", Value: region, DataType: "string"},
	}

	return options, existingTerraformOptions
}

func TestRunFullyConfigurableSolutionInSchematics(t *testing.T) {
	t.Parallel()
	prefix := fmt.Sprintf("wt-s-%s", strings.ToLower(random.UniqueID()))
	options, existingTerraformOptions := setupFullyConfigurableOptions(t, prefix, "us-south")
	if options == nil || existingTerraformOptions == nil {
		t.Fatal("Failed to create watsonx schematic options (prerequisite Terraform deployment failed)")
	}

	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")

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

// TestAgentsSolutionUpgradeInSchematics runs an upgrade schematic test for the Observability Agents solution.
func TestRunFullyConfigurableSolutionInSchematicsUpgrade(t *testing.T) {
	t.Parallel()

	// Use the shared setup function to prepare agent schematic options and Terraform prereqs
	prefix := fmt.Sprintf("wt-u-%s", strings.ToLower(random.UniqueID()))
	options, existingTerraformOptions := setupFullyConfigurableOptions(t, prefix, "eu-de")

	if options == nil || existingTerraformOptions == nil {
		t.Fatal("Failed to create watsonx schematic options (prerequisite Terraform deployment failed)")
	}

	options.CheckApplyResultForUpgrade = true

	err := options.RunSchematicUpgradeTest()
	if !options.UpgradeTestSkipped {
		assert.NoError(t, err, "Upgrade test should complete without errors")
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

// TestRunICRImageBuildWithSecurePrivateCluster tests building and publishing a Cloud Pak Deployer
// image to ICR via Code Engine, using a secure private cluster (no public gateway).

func TestRunICRImageBuildWithSecurePrivateCluster(t *testing.T) {
	t.Parallel()

	// ------------------------------------------------------------------------------------
	// Phase 1: Pre-provision private cluster (no public gateway, bx2.16x64 workers)
	// ------------------------------------------------------------------------------------

	prefix := fmt.Sprintf("cp-adv-%s", strings.ToLower(random.UniqueID()))
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
			"prefix":                prefix,
			"region":                region,
			"resource_tags":         tags,
			"resource_group":        resourceGroup,
			"create_public_gateway": false,
		},
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNewContext(t, context.Background(), existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyContextE(t, context.Background(), existingTerraformOptions)
	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of private cluster resources failed")
	} else {
		// ------------------------------------------------------------------------------------
		// Phase 2: Deploy WatsonX via Schematics using the pre-provisioned private cluster
		// ------------------------------------------------------------------------------------

		cpdEntitlementKey, cpdEntitlementKeyErr := GetSecretsManagerKey(
			permanentResources["secretsManagerGuid"].(string),
			permanentResources["secretsManagerRegion"].(string),
			cpdEntitlementKeySecretId,
		)
		if !assert.NoError(t, cpdEntitlementKeyErr) {
			t.Error("TestRunICRImageBuildWithSecurePrivateCluster Failed - geretain-software-entitlement-key not found in secrets manager")
			panic(cpdEntitlementKeyErr)
		}

		existingClusterName := terraform.OutputContext(t, context.Background(), existingTerraformOptions, "cluster_name")
		existingResourceGroupName := terraform.OutputContext(t, context.Background(), existingTerraformOptions, "cluster_resource_group_name")

		advancedExampleDir := "examples/advanced"

		schematicOptions := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
			Testing:               t,
			Prefix:                prefix,
			BestRegionYAMLPath:    "../common-dev-assets/common-go-assets/cloudinfo-region-vpc-gen2-prefs.yaml",
			Region:                region,
			TemplateFolder:        advancedExampleDir,
			Tags:                  tags,
			DeleteWorkspaceOnFail: false,
			ResourceGroup:         existingResourceGroupName,
			// Include all necessary files in the TAR for Schematics
			TarIncludePatterns: []string{
				"*.tf",
				advancedExampleDir + "/*.tf",
				"modules/cloud-pak-deployer/*.tf",
				"modules/cloud-pak-deployer/config/*.tf",
				"modules/cpd-image-build/*.tf",
				"modules/watsonx-ai/*.tf",
				"modules/watsonx-data/*.tf",
				"chart/cloud-pak-deployer/*.yaml",
				"chart/cloud-pak-deployer/templates/*.yaml",
				"chart/cloud-pak-deployer/templates/*.tpl",
				"scripts/*.sh",
				"kubeconfig/README.md",
			},
			// Ignore Helm release updates for consistency check (timestamp() causes drift)
			IgnoreUpdates: testhelper.Exemptions{
				List: []string{
					"module.watsonx_self_managed_ocp.module.cloud_pak_deployer.helm_release.cloud_pak_deployer_helm_release",
				},
			},
			// Do not fail test if Helm release destroy times out (known Cloud Pak Deployer limitation)
			IgnoreDestroys: testhelper.Exemptions{
				List: []string{
					"module.watsonx_self_managed_ocp.module.cloud_pak_deployer.helm_release.cloud_pak_deployer_helm_release",
				},
			},
		})

		schematicOptions.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "ibmcloud_api_key", Value: schematicOptions.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
			{Name: "prefix", Value: prefix, DataType: "string"},
			{Name: "region", Value: region, DataType: "string"},
			{Name: "resource_group", Value: existingResourceGroupName, DataType: "string"},
			{Name: "existing_cluster_name", Value: existingClusterName, DataType: "string"},
			{Name: "cpd_entitlement_key", Value: *cpdEntitlementKey, DataType: "string", Secure: true},
			{Name: "cpd_admin_password", Value: "Test1234!", DataType: "string", Secure: true},
			{Name: "cloud_pak_deployer_image", Value: "__NULL__", DataType: "string"},
			{Name: "install_odf_cluster_addon", Value: "false", DataType: "bool"},
		}
		_ = os.Unsetenv("TF_VAR_resource_tags")

		err := schematicOptions.RunSchematicTest()
		assert.NoError(t, err, "Schematics test failed - this test validates the ICR image build use case with secure private cluster")
	}

	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing private cluster resources)")
		terraform.DestroyContext(t, context.Background(), existingTerraformOptions)
		terraform.WorkspaceDeleteContext(t, context.Background(), existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing private cluster resources)")
	}
}
