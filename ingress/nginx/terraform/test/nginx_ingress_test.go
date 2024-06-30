package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"gotest.tools/assert"
)

func TestNginxIngress(t *testing.T) {
	t.Parallel()

	//
	// install nginx-ingress using terraform
	//
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
	})

	terraform.InitAndApply(t, terraformOptions)
	defer terraform.Destroy(t, terraformOptions)

	chartName := terraform.Output(t, terraformOptions, "chart_name")
	assert.Equal(t, "ingress-nginx", chartName)

	charStatus := terraform.Output(t, terraformOptions, "chart_status")
	assert.Equal(t, "deployed", charStatus)
}
