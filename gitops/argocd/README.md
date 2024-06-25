# Software needed

* kubectl
* kustomize
* minikube

# Install helm client and update repos
Follow the [Instructions on helm site](https://helm.sh/docs/intro/install/)

```shell
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
```

# Commands make argo work locally

## Create a cluster with minikube
<version> is the version you want to install

the `--kubernetes-version` could be omitted if want install the latest version

```shell
$ minikube start --kubernetes-version=<version> --driver=docker --nodes 4
```

## Use the director of terraform to deploy argocd
```shell

```

## (Optional) import argocd repo to helm
```shell
$ helm repo add argocd https://argoproj.github.io/argo-helm
$ helm repo update
```

## Verificar o status da instalação do ArgoCD
```shell
$ helm status argocd -n argocd
$ kubectl get pods -n argocd
```

## Para acessar interface do Argocd
```shell
$ kubectl port-forward service/argocd-server -n argocd 8080:443
```

## Pegar senha do admin
```shell
$ kubectl -n argocd get secrets argocd-initial-admin-secret -o yaml |
    awk '/password/ {print $2}' |
    base64 -d
```

## Workflow com gitops
```
                                    / push do hub image  \
dev -> git app repo -> build image -> update gitops repo -> argocd deploy -> kubernetes
```

##
```shell
```
