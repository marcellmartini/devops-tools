# Deploy in Kubernetes
 
## Required Commands

1. [kubectl](https://kubernetes.io/docs/tasks/tools/)
2. curl
3. [jq](https://jqlang.github.io/jq/download/)

## Install

First, install the [ingress-nginx](../../ingress/nginx/) controller. Then, run the commands below:

```shell
export NODE_PORT=$(
    kubectl get svc \
    -n ingress-nginx ingress-nginx-controller \
    -o json |
    jq '.spec.ports[] |
        select(.name == "http") |
        .nodePort'
)

export HOST_IP="$(
    kubectl get nodes -o json |
    jq -r '.items[].status.addresses[].address' |
    sort |
    head -1
)"

sed -e "s/<cluster_ip>/${HOST_IP}/g" ./03-ingress.yml |
  tee ./03-ingress.yml

kubectl apply -f ./

curl "http://nginx.${HOST_IP}.nip.io:${NODE_PORT}"
```

## Clean UP

To clean up, run:

```shell
kubectl delete -f ./
```
