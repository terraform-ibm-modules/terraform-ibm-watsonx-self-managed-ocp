// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
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

func setupFullyConfigurableOptions(t *testing.T, prefix string) (*testschematic.TestSchematicOptions, *terraform.Options) {

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

	// Force region to us-south
	region := "us-south"

	// Copy Terraform folder to temp dir
	realTerraformDir := "./resources"
	tempTerraformDir, err := files.CopyTerraformFolderToTemp(
		realTerraformDir, fmt.Sprintf("%s-%s", prefix, strings.ToLower(random.UniqueId())),
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
	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)

	// Apply Terraform resources
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)
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
				"null_resource.wait_for_cloud_pak_deployer_complete",
			},
		},

		IgnoreDestroys: testhelper.Exemptions{
			List: []string{
				"null_resource.wait_for_cloud_pak_deployer_complete",
			},
		},
	})

	// Set Terraform variables for Schematics
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "cpd_entitlement_key", Value: *cpdEntitlementKey, DataType: "string", Secure: true},
		{Name: "existing_cluster_id", Value: terraform.Output(t, existingTerraformOptions, "cluster_id"), DataType: "string"},
		{Name: "existing_cluster_resource_group_name", Value: terraform.Output(t, existingTerraformOptions, "cluster_resource_group_name"), DataType: "string"},
		{Name: "prefix", Value: prefix, DataType: "string"},
		{Name: "provider_visibility", Value: "public", DataType: "string"},
		{Name: "region", Value: region, DataType: "string"},
	}

	return options, existingTerraformOptions
}

func TestRunFullyConfigurableSolutionInSchematics(t *testing.T) {
	t.Parallel()
	prefix := fmt.Sprintf("wt-s-%s", strings.ToLower(random.UniqueId()))
	options, existingTerraformOptions := setupFullyConfigurableOptions(t, prefix)
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
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}

// TestAgentsSolutionUpgradeInSchematics runs an upgrade schematic test for the Observability Agents solution.
func TestRunFullyConfigurableSolutionInSchematicsUpgrade(t *testing.T) {
	t.Parallel()

	// Use the shared setup function to prepare agent schematic options and Terraform prereqs
	prefix := fmt.Sprintf("wt-u-%s", strings.ToLower(random.UniqueId()))
	options, existingTerraformOptions := setupFullyConfigurableOptions(t, prefix)

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
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
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
