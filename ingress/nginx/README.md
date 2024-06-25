# Commands

## Required Commands

1. minikube
2. kubectl
3. tofu
4. jq

## Install

```shell
minikube start --nodes 4

tofu -chdir=terraform init

tofu -chdir=terraform plan

tofu -chdir=terraform apply
```
 
## Test instalation

```shell
export NODE_PORT=$(kubectl get svc \
    -n ingress-nginx ingress-nginx-controller \
    -o json |
    jq '.spec.ports[] |
        select(.name == "http") |
        .nodePort')

export HOST_IP="$(minikube ip)"

sed -e "s@<cluster_ip>@${HOST_IP}@g" ./terraform/example/03-ingress.yml |
  tee ./terraform/example/03-ingress.yml

kubectl apply -f ./terraform/example

curl http://nginx.${HOST_IP}.nip.io:${NODE_PORT}
```

## Helm Values
To know which are the default values of the helm chart, run the command below:

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
3. [terraform helm provider](https://registry.terraform.io/providers/hashicorp/helm/latest)
    1. [helm_relase resource](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) 
4. [terraform kubernetes provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest)
5. [K0S Project nginx ingress controller](https://docs.k0sproject.io/stable/examples/nginx-ingress/)
6. [K8S minikube page](https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/)
   
