# Commands

## Required Commands

1. minikube
2. kubectl
3. tofu
4. jq

## Install

### Create a cluster 

Create a cluster k8s with any tool. You'll find docs to create a cluster with
some tools in [clusters](../../k8s/clusters/) directory.

### Install the nginx ingress

```shell
tofu -chdir=terraform init

tofu -chdir=terraform plan

tofu -chdir=terraform apply
```
 
## Test instalation

### Using terratest 

Run the command below:

```shell
go test -timeout 2m -failfast ./terraform/test
```

### Deploy a new service and access it externally 

Run the commands below:

```shell
export NODE_PORT=$(kubectl get svc \
    -n ingress-nginx ingress-nginx-controller \
    -o json |
    jq '.spec.ports[] |
        select(.name == "http") |
        .nodePort')

export HOST_IP="$(
        kubectl get nodes -o json |
        jq -r '.items[].status.addresses[0].address' |
        sort |
        head -1
)"

sed -e "s/<cluster_ip>/${HOST_IP}/g" ./terraform/example/03-ingress.yml |
  tee ./terraform/example/03-ingress.yml

kubectl apply -f ./terraform/example

curl "http://nginx.${HOST_IP}.nip.io:${NODE_PORT}"
```

## Helm Values

If you want a full list of values that you can set, while installing with Helm,
first confirm that the helm repo is installed:

```shell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx-controller
```

Then, show all values:

```shell
helm show values ingress-nginx --repo https://kubernetes.github.io/ingress-nginx-controller
```
        
## Clean UP

```shell
tofu -chdir=terraform destroy

minikube delete
```

## Reference

1. [ingress-nginx Doc](https://github.com/kubernetes/ingress-nginx/blob/main/docs/deploy/index.md#quick-start)
2. [ingress-nginx chart doc](https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx#ingress-nginx)
3. [Ingress-nginx Controller site](https://kubernetes.github.io/ingress-nginx/)
4. [terraform helm provider](https://registry.terraform.io/providers/hashicorp/helm/latest)
    1. [helm_relase resource](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) 
5. [K0S Project nginx ingress controller](https://docs.k0sproject.io/stable/examples/nginx-ingress/)
6. [K8S minikube page](https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/)
   
