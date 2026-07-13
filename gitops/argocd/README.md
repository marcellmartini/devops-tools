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

# Preview environments

O exemplo de preview environment (deploy efêmero por Pull Request) vive em:

* `gitops/argocd/config/appsofapps/preview-environment.yaml` — `ApplicationSet` do ArgoCD com o gerador `pullRequest.github`. Para cada PR aberta no repo com a label `preview`, cria uma `Application`/namespace `pre-env-<branch>-<numero>` fazendo deploy do chart abaixo.
* `apps/apps/go-web/helm/` — chart Helm da app de exemplo (`go-web`), parametrizado por `namespace` e `image.tag`.
* `.github/workflows/build-push-docker.yml` — builda e publica `marcellmartini/go-web:pr-<numero>` no Docker Hub quando a PR toca `apps/apps/go-web/src/*`, alimentando a tag usada pelo ApplicationSet.

## Testar localmente com kind ou minikube

1. Subir um cluster local:
   ```shell
   # kind
   $ kind create cluster --config k8s/clusters/kind/kind_cluster.yml

   # ou minikube
   $ minikube start --driver=docker --nodes 4
   ```

2. Instalar o MetalLB (necessário no kind para simular `LoadBalancer`; no minikube prefira `minikube tunnel`):
   ```shell
   $ kubectl apply -k k8s/metallb/
   ```

3. Instalar o ArgoCD:
   ```shell
   $ kubectl apply -k gitops/argocd/install/
   ```

4. Criar o secret do GitHub exigido pelo gerador `pullRequest` do `preview-environment.yaml`:
   ```shell
   $ kubectl create secret generic github-token -n argocd \
       --from-literal=token=<PAT com escopo repo>
   ```

5. Aplicar os manifests de `appsofapps` (app-of-apps + go-web + preview ApplicationSet):
   ```shell
   $ kubectl apply -f gitops/argocd/config/appsofapps/
   ```
   > Nota: `appsofapps.yaml` ainda aponta `spec.source.path: apps/apps/`, mas `go-web-application.yaml` e `preview-environment.yaml` vivem em `gitops/argocd/config/appsofapps/` — o app-of-apps não vai (re)descobrir esses dois sozinho enquanto esse `path` não for atualizado. Por isso o `apply -f` no diretório inteiro, aplicando os três manifests diretamente.

6. Disparar uma preview: abrir uma PR no GitHub com a label `preview` alterando `apps/apps/go-web/src/*`. O workflow builda a imagem `pr-<numero>` e, em até 15s, o `ApplicationSet` cria a `Application`/namespace `pre-env-<branch>-<numero>`.

7. Observar:
   ```shell
   $ kubectl get applications -n argocd
   $ kubectl get ns | grep pre-env-
   $ kubectl port-forward svc/go-web-app -n pre-env-<branch>-<numero> 8080:80
   ```

**Limitação:** o gerador é `pullRequest.github`, então exige uma PR real no repositório do GitHub — hoje não há um gerador local/`list` equivalente para testar 100% offline.
