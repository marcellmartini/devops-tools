package minikube

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/stretchr/testify/assert"
)

func TestIsMinikubeE(t *testing.T) {
	t.Parallel()

	options := k8s.NewKubectlOptions("", "", "")
	isMinikube, err := k8s.IsMinikubeE(t, options)
	assert.NoError(t, err)
	assert.True(t, isMinikube)
}
