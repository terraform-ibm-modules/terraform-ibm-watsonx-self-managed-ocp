// Tests in this file are NOT run in the PR pipeline. They are run in the continuous testing pipeline along with the ones in pr_test.go
package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

func TestRunBasicExample(t *testing.T) {
	t.Parallel()

	// Pull entitlement key from secrets manager
	cpdEntitlementKey, cpdEntitlementKeyErr := GetSecretsManagerKey(
		permanentResources["secretsManagerGuid"].(string),
		permanentResources["secretsManagerRegion"].(string),
		cpdEntitlementKeySecretId,
	)
	if !assert.NoError(t, cpdEntitlementKeyErr) {
		t.Error("TestRunStandardUpgradeSolution Failed - geretain-software-entitlement-key not found in secrets manager")
		panic(cpdEntitlementKeyErr)
	}

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: "examples/basic",
		Prefix:       "wx-basic",
		TerraformVars: map[string]interface{}{
			"cpd_admin_password":  GetRandomAdminPassword(t),
			"cpd_entitlement_key": *cpdEntitlementKey,
		},
	})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}
