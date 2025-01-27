// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

// Ensure every example directory has a corresponding test
const defaultExampleTerraformDir = "examples/basic"

func setupOptions(t *testing.T, prefix string, dir string) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: dir,
		Prefix:       prefix,
		IgnoreAdds: testhelper.Exemptions{ // Ignore for consistency check
			List: []string{},
		},
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: []string{
				"module.cloudpak_data.module.cloud_pak_deployer.helm_release.cloud_pak_deployer_helm_release",
			},
		},
		IgnoreDestroys: testhelper.Exemptions{ // Ignore for consistency check
			List: []string{},
		},
	})
	return options
}

// Consistency test for the basic example
func TestRunBasicExample(t *testing.T) {

	t.Parallel()

	options := setupOptions(t, "cp4d", defaultExampleTerraformDir)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")

}

// Upgrade test (using advanced example)
func TestRunUpgradeExample(t *testing.T) {
	t.Parallel()
	options := setupOptions(t, "cp4dup", defaultExampleTerraformDir)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
