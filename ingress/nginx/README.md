# Commands

## Required Commands

1. [Go 1.21.5](https://go.dev/doc/install)
2. [minikube](https://minikube.sigs.k8s.io/docs/start/)
3. [kubectl](https://kubernetes.io/docs/tasks/tools/)
4. [OpenTofu](https://opentofu.org/docs/intro/install/)

# Install

## Create a cluster

Create a Kubernetes cluster using any tool. You'll find documentation to create 
a cluster with some tools in the [clusters](../../k8s/clusters/) directory.

## Install the nginx ingress

These steps will use Helm and the chart version 4.10.1 to install ingress-nginx.

```shell
export INGRESS_DIR="./example/ingress-nginx"

tofu -chdir="${INGRESS_DIR}" init

tofu -chdir="${INGRESS_DIR}" plan

tofu -chdir="${INGRESS_DIR}" apply
```

# Tests
 
## Manually Deploying a New Service and Access it Externally

you can deploy any [application](../../apps/) in this repoitory.

## Using terratest

Run the command below:

```shell
go test -timeout 2m -failfast ./test
```

# Helm Values

If you want a full list of values that you can set while installing with Helm, 
first confirm that the Helm repo is installed:

```shell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx-controller
```

Then, show all values:

```shell
helm show values ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --version 4.10.1
```
        
# Clean UP

```shell
tofu -chdir="${INGRESS_DIR}" destroy

minikube delete
```

# Reference

1. [ingress-nginx Doc](https://github.com/kubernetes/ingress-nginx/blob/main/docs/deploy/index.md#quick-start)
2. [ingress-nginx chart doc](https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx#ingress-nginx)
3. [Ingress-nginx Controller site](https://kubernetes.github.io/ingress-nginx/)
4. [terraform helm provider](https://registry.terraform.io/providers/hashicorp/helm/latest)
    1. [helm_relase resource](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) 
5. [K0S Project nginx ingress controller](https://docs.k0sproject.io/stable/examples/nginx-ingress/)
6. [K8S minikube page](https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/)
7. [Test Infra with Terratest](https://github.com/gruntwork-io/terratest)
   
