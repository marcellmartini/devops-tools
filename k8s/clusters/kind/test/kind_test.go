package test

import (
	"io/ioutil"
	"log"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/stretchr/testify/assert"
	"gopkg.in/yaml.v2"
	"k8s.io/apimachinery/pkg/util/rand"
)

type kindYaml struct {
	APIVersion string `yaml:"apiVersion"`
	Kind       string `yaml:"kind"`
	Nodes      []node `yaml:"nodes"`
}

type node struct {
	Role string `yaml:"role"`
}

func (ky *kindYaml) getConfig(path string) *kindYaml {
	yf, err := ioutil.ReadFile(path)
	if err != nil {
		log.Printf("yamlFile.Get err #%v ", err)
	}

	err = yaml.Unmarshal(yf, ky)
	if err != nil {
		log.Fatalf("Unmarshal: %v", err)
	}

	return ky
}

func TestKindClusterCriation(t *testing.T) {
	t.Parallel()

	clusterName := "test-" + rand.String(8)
	kindConfigFile := "../kind_cluster.yml"
	clusterCreate := shell.Command{
		Command: "kind",
		Args: []string{
			"create",
			"cluster",
			"--config",
			kindConfigFile,
			"--name",
			clusterName,
		},
	}
	clusterDelete := shell.Command{
		Command: "kind",
		Args: []string{
			"delete",
			"cluster",
			"--name",
			clusterName,
		},
	}

	out := shell.RunCommandAndGetOutput(t, clusterCreate)
	defer shell.RunCommand(t, clusterDelete)

	assert.Contains(t, out, "You can now use your cluster with", "kubectl cluster-info --context kind-"+clusterName)

	ky := kindYaml{}
	ky.getConfig(kindConfigFile)

	options := k8s.NewKubectlOptions("", "", "default")
	k8s.WaitUntilAllNodesReady(t, options, 30, 3*time.Second)
	assert.True(t, k8s.AreAllNodesReady(t, options))
	assert.EqualValues(t, len(ky.Nodes), len(k8s.GetNodes(t, options)))
}
