package pod

import (
	"crypto/tls"
	"fmt"
	"path/filepath"
	"strings"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/stretchr/testify/require"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
)

func TestKubernetesHelloWorldExample(t *testing.T) {
	t.Parallel()

	kubeResourcePath, err := filepath.Abs("pod-with-service.yaml")
	require.NoError(t, err)

	uniqueID := strings.ToLower(random.UniqueId())
	options := k8s.NewKubectlOptions("", "", uniqueID)
	k8s.CreateNamespace(t, options, uniqueID)
	defer k8s.DeleteNamespace(t, options, uniqueID)

	k8s.KubectlApply(t, options, kubeResourcePath)
	defer k8s.KubectlDelete(t, options, kubeResourcePath)

	k8s.WaitUntilServiceAvailable(t, options, "hello-world-service", 30, 1*time.Second)

	// Open a tunnel to pod from any available port locally
	tunnel := k8s.NewTunnel(options, k8s.ResourceTypeService, "hello-world-service", 0, 80)
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
