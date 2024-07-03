package test

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"gotest.tools/assert"
)

// An example of how to test the ingress nginx installation using a Terraform module
func TestInstallIngressNginxNodePort(t *testing.T) {
	t.Parallel()

	moduleName := "ingress-nginx"

	// Make a copy of the module to a temporary directory.
	// This is useful if you want to run the same module in parallel multiple times.
	exampleFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "module")

	// Create a random suffix to avoid errors when the module is used to
	// deploy multiple times.
	randomSuffix := strings.ToLower(random.UniqueId())

	// Each test uses its own namespace
	expectedNamespace := fmt.Sprintf("%s-%s", moduleName, randomSuffix)
	releaseName := fmt.Sprintf("%s-%s", moduleName, randomSuffix)
	ingressClassName := fmt.Sprintf("%s-%s", "nginx", randomSuffix)

	// Configure the options with default retryable errors to handle the
	// most common retryable errors encountered in testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: exampleFolder,

		Vars: map[string]interface{}{
			// variable namespace
			"namespace":    expectedNamespace,

			// variable release_name
			"release_name": releaseName,

			// variable attributes
			// Type:
			//   in Tofu     : list(map(string))
			//   in Terratest: []map[string]string
			"attributes": []map[string]string{
				{
					"name":  "controller.service.type",
					"value": "NodePort",
				},
				{
					"name":  "controller.ingressClassResource.name",
					"value": ingressClassName,
				},
			},
		},
	})

	// Run Init and Apply
	terraform.InitAndApply(t, terraformOptions)

	// Destroy at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Validate if the chart_name is correct
	chartName := terraform.Output(t, terraformOptions, "chart_name")
	assert.Equal(t, releaseName, chartName)

	// Validate the chart was deployed correctly
	chartStatus := terraform.Output(t, terraformOptions, "chart_status")
	assert.Equal(t, "deployed", chartStatus)

	kubectlOptions := k8s.NewKubectlOptions("", "", expectedNamespace)

	// The namespace was created by the module ...
	// ... and needs to be deleted manually after the test finishes.
	defer k8s.DeleteNamespace(t, kubectlOptions, expectedNamespace)

	serviceName := fmt.Sprintf("%s-controller", releaseName)
	// Wait to get the service information
	k8s.WaitUntilServiceAvailable(t, kubectlOptions, serviceName, 10, 1*time.Second)

	// Check if the service was deployed correctly
	service := k8s.GetService(t, kubectlOptions, serviceName)
	assert.Equal(t, service.Name, serviceName)
}
