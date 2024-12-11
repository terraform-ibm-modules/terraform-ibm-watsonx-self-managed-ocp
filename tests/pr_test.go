// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"testing"
)

// Ensure every example directory has a corresponding test
//const exampleDir = "solutions/deploy"

/*
func setupOptions(t *testing.T, prefix string, dir string) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: dir,
		Prefix:       prefix,
	})
	return options
}
*/

// Consistency test for the basic example
func TestRunBasicExample(t *testing.T) {
	/*
		t.Parallel()

		options := setupOptions(t, "mod-template-basic", exampleDir)

		output, err := options.RunTestConsistency()
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	*/
}

func TestRunAdvancedExample(t *testing.T) {
	/*
		t.Parallel()

		options := setupOptions(t, "mod-template-adv", exampleDir)

		output, err := options.RunTestConsistency()
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	*/
}

// Upgrade test (using advanced example)
func TestRunUpgradeExample(t *testing.T) {
	/*
		t.Parallel()
		options := setupOptions(t, "mod-template-adv-upg", exampleDir)

		output, err := options.RunTestUpgrade()
		if !options.UpgradeTestSkipped {
			assert.Nil(t, err, "This should not have errored")
			assert.NotNil(t, output, "Expected some output")
		}
	*/
}
