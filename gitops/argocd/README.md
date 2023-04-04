# Commands make argo work locali

## Create a cluster with minikube
```shell
$ minikube start --kubernetes-version=1.26.1 --driver=docker
```

## Use the director of terraform to deploy argocd
```shell
$ cd terraform
$ terraform init
$ terraform apply
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
