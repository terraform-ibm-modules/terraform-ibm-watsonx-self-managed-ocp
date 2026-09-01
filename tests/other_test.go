// Tests in this file are NOT run in the PR pipeline. They are run in the continuous testing pipeline along with the ones in pr_test.go
package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

func TestRunAdvancedExample(t *testing.T) {
	t.Parallel()

	// Pull entitlement key from secrets manager
	cpdEntitlementKey, cpdEntitlementKeyErr := GetSecretsManagerKey(
		permanentResources["secretsManagerGuid"].(string),
		permanentResources["secretsManagerRegion"].(string),
		cpdEntitlementKeySecretId,
	)
	if !assert.NoError(t, cpdEntitlementKeyErr) {
		t.Error("TestRunAdvancedExample Failed - geretain-software-entitlement-key not found in secrets manager")
		panic(cpdEntitlementKeyErr)
	}

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: "examples/advanced",
		Prefix:       "cp-adv",
		TerraformVars: map[string]interface{}{
			"cpd_admin_password":  common.GetRandomPasswordWithPrefix(),
			"cpd_entitlement_key": *cpdEntitlementKey,
		},
	})

	options.IgnoreUpdates = testhelper.Exemptions{
		List: []string{
			"module.watsonx_self_managed_ocp.module.cloud_pak_deployer.helm_release.cloud_pak_deployer_helm_release",
		},
	}

	options.IgnoreDestroys = testhelper.Exemptions{
		List: []string{
			"module.watsonx_self_managed_ocp.module.cloud_pak_deployer.helm_release.cloud_pak_deployer_helm_release",
		},
	}

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}
