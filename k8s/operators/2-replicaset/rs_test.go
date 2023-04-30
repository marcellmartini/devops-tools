package replicaset

import (
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
)

func TestKubernetesReplicaSet(t *testing.T) {
	t.Parallel()

	kubeResourcePath := "replicaset.yaml"

	uniqueID := strings.ToLower(random.UniqueId())
	options := k8s.NewKubectlOptions("", "", uniqueID)
	k8s.CreateNamespace(t, options, uniqueID)
	defer k8s.DeleteNamespace(t, options, uniqueID)

	k8s.KubectlApply(t, options, kubeResourcePath)
	defer k8s.KubectlDelete(t, options, kubeResourcePath)

	k8s.WaitUntilPodAvailable(t, options, "nginx", 60, 1*time.Second)

	tunnel := k8s.NewTunnel(options, k8s.ResourceTypePod, "meu-pod", 0, 80)
	defer tunnel.Close()
	tunnel.ForwardPort(t)

}
