// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"crypto/rand"
	"encoding/base64"
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
func TestRunStandardSolution(t *testing.T) {
	t.Parallel()
	// ------------------------------------------------------------------------------------
	// Provision ROK's first
	// ------------------------------------------------------------------------------------

	prefix := fmt.Sprintf("cp-ex-%s", strings.ToLower(random.UniqueId()))
	realTerraformDir := "./resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))
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

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)
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
			t.Error("TestRunStandardUpgradeSolution Failed - geretain-software-entitlement-key not found in secrets manager")
			panic(cpdEntitlementKeyErr)
		}

		options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
			Testing:      t,
			TerraformDir: instanceFlavorDir,
			// Do not hard fail the test if the implicit destroy steps fail to allow a full destroy of resource to occur
			ImplicitRequired: false,
			TerraformVars: map[string]any{
				"prefix":                       prefix,
				"region":                       region,
				"existing_cluster_name":        terraform.Output(t, existingTerraformOptions, "cluster_name"),
				"existing_resource_group_name": terraform.Output(t, existingTerraformOptions, "cluster_resource_group_name"),
				"cloud_pak_deployer_image":     "quay.io/cloud-pak-deployer/cloud-pak-deployer",
				"cpd_admin_password":           GetRandomAdminPassword(t),
				"cpd_entitlement_key":          *cpdEntitlementKey,
				"install_odf_cluster_addon":    true,
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
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}

func TestRunStandardUpgradeSolution(t *testing.T) {
	t.Parallel()

	prefix := fmt.Sprintf("cp-up-%s", strings.ToLower(random.UniqueId()))
	realTerraformDir := "./resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))
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

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)
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
			t.Error("TestRunStandardUpgradeSolution Failed - geretain-software-entitlement-key not found in secrets manager")
			panic(cpdEntitlementKeyErr)
		}

		options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
			Testing:      t,
			TerraformDir: instanceFlavorDir,
			// Do not hard fail the test if the implicit destroy steps fail to allow a full destroy of resource to occur
			ImplicitRequired: false,
			TerraformVars: map[string]any{
				"prefix":                       prefix,
				"region":                       region,
				"existing_cluster_name":        terraform.Output(t, existingTerraformOptions, "cluster_name"),
				"existing_resource_group_name": terraform.Output(t, existingTerraformOptions, "cluster_resource_group_name"),
				"cloud_pak_deployer_image":     "quay.io/cloud-pak-deployer/cloud-pak-deployer",
				"cpd_admin_password":           GetRandomAdminPassword(t),
				"cpd_entitlement_key":          *cpdEntitlementKey,
				"install_odf_cluster_addon":    true,
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
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}

func GetRandomAdminPassword(t *testing.T) string {
	// Generate a 15 char long random string for the admin_pass
	randomBytes := make([]byte, 13)
	_, randErr := rand.Read(randomBytes)
	require.Nil(t, randErr) // do not proceed if we can't gen a random password

	randomPass := "A1" + base64.URLEncoding.EncodeToString(randomBytes)[:13]

	return randomPass
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
