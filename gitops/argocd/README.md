# Software needed

* kubectl
* kustomize
* minikube

# Commands make argo work locally

## Create a cluster with minikube
<version> is the version you want to install

the `--kubernetes-version` could be omitted if want install the latest version

```shell
$ minikube start --kubernetes-version=<version> --driver=docker --nodes 4
```

## Instalar argocd
To install argocd, just use kubectl with -k pointing to the install dir

```shell
$ kubectl apply -k ./install
```

## Verificar o status da instalação do ArgoCD
```shell
$ kubectl get pods -n argocd
```

## Para acessar interface do Argocd
```shell
$ kubectl port-forward service/argocd-server -n argocd 8080:443 &
```

## Pegar senha do admin
```shell
$ kubectl -n argocd get secrets argocd-initial-admin-secret -o yaml |
    awk '/password/ {print $2}' |
    base64 -d
```
