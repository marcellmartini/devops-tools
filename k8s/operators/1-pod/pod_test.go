package pod

import (
	"crypto/tls"
	"fmt"
	"strings"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
)

func TestKubernetesPod(t *testing.T) {
	t.Parallel()

	kubeResourcePath := "pod.yaml"

	uniqueID := strings.ToLower(random.UniqueId())
	options := k8s.NewKubectlOptions("", "", uniqueID)
	k8s.CreateNamespace(t, options, uniqueID)
	defer k8s.DeleteNamespace(t, options, uniqueID)

	k8s.KubectlApply(t, options, kubeResourcePath)
	defer k8s.KubectlDelete(t, options, kubeResourcePath)

	k8s.WaitUntilPodAvailable(t, options, "meu-pod", 60, 1*time.Second)

	// Open a tunnel to pod from any available port locally
	tunnel := k8s.NewTunnel(options, k8s.ResourceTypePod, "meu-pod", 0, 80)
	defer tunnel.Close()
	tunnel.ForwardPort(t)

	// Setup a TLS configuration to submit with the helper, a blank struct is acceptable
	tlsConfig := tls.Config{}

	// Try to access the nginx service on the local port, retrying until we get a good response for up to 5 minutes
	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		fmt.Sprintf("http://%s", tunnel.Endpoint()),
		&tlsConfig,
		60,
		5*time.Second,
		verifyNginxWelcomePage,
	)
}

func verifyNginxWelcomePage(statusCode int, body string) bool {
	if statusCode != 200 {
		return false
	}
	return strings.Contains(body, "Welcome to nginx")
}
