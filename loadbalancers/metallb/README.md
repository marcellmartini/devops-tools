# Commands

## Required Commands

1. minikube
2. kubectl
3. tofu

## Install

### Create a cluster 

Create a cluster k8s with any tool. You'll find docs to create a cluster with
some tools in [clusters](../../k8s/clusters/) directory.

### Install the metallb ingress

```shell
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
kubectl apply -f ippool.yml
kubectl apply -f l2advertisement.yml
```
 
## Test instalation

```shell
```

## Helm Values
To know which are the default values of the helm chart, run the command below:

```shell
helm show values metallb --repo https://metallb.github.io/metallb
```
        
## Clean UP

```shell
tofu -chdir=terraform destroy

minikube delete
```

## Reference
1. [MetalLB Install](https://metallb.io/installation/#installation-with-helm)

