> Para o passo a passo comentado da oficina (conceitos + prática), veja o
> [WORKSHOP.md](./WORKSHOP.md). Este arquivo é a referência rápida, só com
> comandos.

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

* `gitops/argocd/config/appsofapps/preview-environment.yaml` — `ApplicationSet` do ArgoCD com o gerador `pullRequest.github`. Para cada PR aberta no repo com a label `preview`, cria uma `Application`/namespace `pre-env-<branch-slug>-<numero>` fazendo deploy do chart abaixo.
* `apps/apps/go-web/helm/` — chart Helm da app de exemplo (`go-web`), parametrizado por `namespace`, `image.repository` e `image.tag`.
* `.github/workflows/build-push-docker.yml` — builda e publica `ghcr.io/<seu-usuario>/go-web:pr-<numero>-<head-short-sha>` (mais `pr-<numero>` sozinho, tag flutuante só de conveniência) no GitHub Container Registry quando a PR com a label `preview` toca `apps/apps/go-web/src/*`, usando o `GITHUB_TOKEN` automático do Actions (sem secret manual). É a tag por commit que o `ApplicationSet` usa — precisa mudar a cada push, senão o `Deployment` não tem diff pra sincronizar e o pod antigo continua no ar.

## Rodando em um fork (oficina/workshop)

Os manifests apontam por padrão para `marcellmartini/devops-tools` e `ghcr.io/marcellmartini/go-web`. Depois de dar fork, rode:

```shell
$ ./scripts/setup-fork.sh <seu-usuario-github>
```

Isso reaponta `repoURL`, o `owner` do generator do preview e a imagem do go-web para o seu fork. Revise com `git diff`, commite e dê push antes de continuar.

## Testar localmente com kind ou minikube

1. Subir um cluster local:
   ```shell
   # kind
   $ kind create cluster --config k8s/clusters/kind/kind_cluster.yml

   # ou minikube
   $ minikube start --driver=docker --nodes 4
   ```

2. Instalar o MetalLB (necessário no kind para simular `LoadBalancer`; no minikube prefira `minikube tunnel`). A rede docker do kind é alocada dinamicamente, então gere o pool de IPs antes de aplicar:
   ```shell
   $ ./scripts/setup-metallb-pool.sh
   $ kubectl apply -k k8s/metallb/
   ```

3. Instalar o ArgoCD:
   ```shell
   $ kubectl apply -k gitops/argocd/install/
   ```

4. Criar o secret do GitHub exigido pelo gerador `pullRequest` do `preview-environment.yaml` (também evita bater no rate-limit da API do GitHub sem token — 60 req/h contra o poll a cada 15s do generator):
   ```shell
   $ kubectl create secret generic github-token -n argocd \
       --from-literal=token=<PAT com escopo repo>
   ```

5. Bootstrap via app-of-apps — aplica só o app-of-apps, que descobre e sincroniza sozinho `go-web-application` e `preview-environment`:
   ```shell
   $ kubectl apply -f gitops/argocd/config/appsofapps/appsofapps.yaml
   ```

6. Disparar uma preview: abrir uma PR real no GitHub (no seu fork) com a label `preview` alterando `apps/apps/go-web/src/*`. O workflow builda e publica `ghcr.io/<seu-usuario>/go-web:pr-<numero>` e, em até 15s, o `ApplicationSet` cria a `Application`/namespace `pre-env-<branch>-<numero>`.
   > Nota: pacotes do GHCR nascem privados. Depois do primeiro push da imagem, torne o pacote `go-web` público em `github.com/<seu-usuario>?tab=packages` → pacote `go-web` → Package settings → Change visibility, senão o cluster não consegue puxar a imagem (`ImagePullBackOff`).

7. Observar (porta `8082` para não colidir com o port-forward do ArgoCD em `8080`):
   ```shell
   $ kubectl get applications -n argocd
   $ kubectl get ns | grep pre-env-
   $ kubectl port-forward svc/go-web-service -n pre-env-<branch>-<numero> 8082:80
   ```

**Limitação:** o gerador é `pullRequest.github`, então exige uma PR real no repositório do GitHub — hoje não há um gerador local/`list` equivalente para testar 100% offline.
