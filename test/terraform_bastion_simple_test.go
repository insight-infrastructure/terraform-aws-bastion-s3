package test

import (
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"log"
	"os"
	"path"
	"testing"
)

func TestTerraformPlaybookPublic(t *testing.T)  {
	t.Parallel()

	exampleFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/bastion-simple")
	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	cwd, err :=  os.Getwd()
	if err != nil {
		log.Println(err)
	}

	fixturesDir := path.Join(cwd, "fixtures")

	terraformOptions := &terraform.Options{
		TerraformDir: exampleFolder,
		Vars: map[string]interface{}{
			"aws_region":    awsRegion,
			"local_public_key": path.Join(fixturesDir, "keys/testing.pub"),
		},
	}

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "setup", func() {
		terraform.InitAndApply(t, terraformOptions)
	})

}
