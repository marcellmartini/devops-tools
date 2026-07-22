# Oficina: GitOps com ArgoCD e Preview Environments

Este guia é o roteiro completo da oficina: explica os conceitos por trás de
cada peça do repositório e guia o passo a passo prático até você ver, na sua
própria máquina, uma Pull Request real disparando o deploy automático de um
ambiente efêmero via ArgoCD.

Para uma referência rápida (só os comandos, sem explicação), veja o
[README.md](./README.md) desta pasta.

## Objetivo

Ao final da oficina você vai ter:

1. Um cluster Kubernetes local (kind ou minikube) rodando ArgoCD.
2. Uma aplicação de exemplo (`go-web`) sendo gerenciada via GitOps — o cluster
   reflete o que está no Git, não o contrário.
3. Uma Pull Request no seu fork que, ao ser aberta, faz o ArgoCD criar
   automaticamente um namespace e um deploy só para aquela PR — e que some
   sozinho quando a PR fecha.

## Pré-requisitos

* Docker
* `kubectl`
* `kustomize`
* `kind` ou `minikube`
* Uma conta no GitHub e um fork deste repositório

---

# Parte 1 — Conceitos

## 1.1 ArgoCD: `Application`

A unidade básica do ArgoCD é a `Application`: um CRD que diz "sincronize o
que está em `source.path` (dentro de `source.repoURL`, na revisão
`source.targetRevision`) para `destination.namespace` neste cluster".

Exemplo real do repo (`gitops/argocd/config/appsofapps/go-web-application.yaml`):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  source:
    repoURL: https://github.com/marcellmartini/devops-tools.git
    path: apps/apps/go-web/helm/
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true      # remove do cluster o que sumiu do Git
      selfHeal: true    # desfaz mudanças manuais feitas direto no cluster
```

Repare que **não há `targetRevision` fixo** — quando esse campo é omitido, o
ArgoCD usa o branch padrão do repositório (`main`). Isso é proposital: assim,
depois que você der fork, o ArgoCD já aponta para o `main` do *seu* fork sem
precisar de configuração extra.

`prune: true` + `selfHeal: true` é o que torna isso "GitOps de verdade": o
cluster nunca fica com deriva (drift) do que está declarado no Git — qualquer
`kubectl edit` manual é revertido automaticamente, e qualquer recurso removido
do Git é removido do cluster.

## 1.2 O padrão app-of-apps

Gerenciar uma `Application` por vez não escala. O padrão **app-of-apps**
resolve isso: uma `Application` "raiz" cujo `source.path` aponta para um
diretório cheio de outras `Applications` (e `ApplicationSets`). O ArgoCD
sincroniza a raiz, descobre os manifests filhos, e passa a gerenciar cada um
deles também.

No repo, essa raiz é `gitops/argocd/config/appsofapps/appsofapps.yaml`,
apontando para `gitops/argocd/config/appsofapps/` — pasta que contém a si
mesma, o `go-web-application.yaml` e o `preview-environment.yaml` (a próxima
seção). Aplicar **só o arquivo da raiz** é o suficiente para bootstrapar tudo
o resto — é por isso que o passo de bootstrap do workshop é um único
`kubectl apply -f`.

## 1.3 `ApplicationSet` e generators

Uma `Application` é estática: um source, um destination. Um `ApplicationSet`
gera **várias** `Applications` a partir de um `template`, usando um
*generator* como fonte de variáveis. Generators comuns: `list` (lista fixa),
`git` (diretórios/arquivos num repo), `cluster` (um `Application` por cluster
registrado) e, o que usamos aqui, `pullRequest` — um `Application` por Pull
Request aberta em um repositório do GitHub. É essa combinação
(`ApplicationSet` + `pullRequest.github`) que implementa preview environments
neste repo, detalhada na seção 1.5.

## 1.4 Kustomize vs. Helm — por que os dois

O repo usa as duas ferramentas de templating do Kubernetes, cada uma onde faz
mais sentido:

* **Kustomize** (`kubectl apply -k`) para coisas que só precisam de patches
  pontuais sobre manifests de terceiros: a instalação do próprio ArgoCD
  (`gitops/argocd/install/`, que baixa o `install.yaml` oficial do projeto
  ArgoCD e aplica um patch de `Service`) e o MetalLB (`k8s/metallb/`, mesma
  lógica com o manifest oficial do MetalLB).
* **Helm** para a aplicação que é *nossa* e precisa de parâmetros variáveis
  por ambiente (`apps/apps/go-web/helm/`) — namespace, tag de imagem, etc.
  mudam a cada preview environment, o que o Kustomize faz de forma mais
  artesanal (overlays) do que o `values.yaml` do Helm.

Cada `Application` do ArgoCD escolhe uma das duas simplesmente apontando
`source.path` para uma pasta com `kustomization.yaml` ou com `Chart.yaml`.

## 1.5 A aplicação de exemplo: `go-web`

`apps/apps/go-web/` tem duas partes:

* `src/` — um servidor HTTP em Go de ~15 linhas (`main.go`), só para ter algo
  real para buildar e implantar.
* `helm/` — o chart. `values.yaml` parametriza tudo que muda entre os
  deploys:

  ```yaml
  namespace: dev
  image:
    repository: ghcr.io/marcellmartini/go-web
    tag: 'dev'
  ```

  `templates/deployment.yaml` e `templates/service.yaml` consomem esses
  valores. O mesmo chart, sem nenhuma mudança de código, serve tanto o deploy
  permanente (`go-web-application.yaml`, sempre com a tag `dev`) quanto cada
  preview environment — que sobrescreve `namespace` e `image.tag` na hora via
  `source.helm.parameters` (mais detalhes na seção 1.5).

## 1.6 Rede local: kind vs. minikube, e por que existe MetalLB

Um `Service` do tipo `LoadBalancer` normalmente depende de um cloud provider
(AWS, GCP...) para receber um IP externo real. Localmente isso não existe, e
os dois clusters resolvem de formas diferentes:

* **minikube** tem `minikube tunnel`, que simula um load balancer
  automaticamente — não precisa de mais nada.
* **kind** não tem equivalente embutido, então instalamos o **MetalLB**: ele
  monitora `Services` do tipo `LoadBalancer` e atribui a eles um IP de um pool
  configurado (`k8s/metallb/ippool.yml`), anunciado na rede local via
  `L2Advertisement` (`k8s/metallb/l2advertisement.yaml`) — ARP/NDP falando
  "esse IP é meu", sem depender de BGP ou hardware especial.

O detalhe chato: a rede docker que o `kind` cria (chamada `kind`) tem uma
subnet **alocada dinamicamente** pelo Docker — muda de máquina para máquina, e
até de execução para execução se você já tiver outras redes docker no host.
Por isso `k8s/metallb/ippool.yml` no repo é só um placeholder; antes de
aplicar, `scripts/setup-metallb-pool.sh` lê a subnet real
(`docker network inspect kind`) e regenera o arquivo com um range que de fato
existe na sua rede.

## 1.7 Pipeline de imagem: do código ao GHCR

Duas GitHub Actions cuidam de publicar a imagem do `go-web`, ambas usando o
GitHub Container Registry (`ghcr.io`) com o `GITHUB_TOKEN` automático do
Actions — **nenhum secret manual precisa ser criado por você**:

* `.github/workflows/build-push-docker.yml` — dispara em `pull_request` que
  toca `apps/apps/go-web/src/*`. Publica
  `ghcr.io/<seu-usuario>/go-web:pr-<numero>`. É esse workflow que alimenta os
  preview environments.
* `.github/workflows/main-build.yml` — dispara em `push` para `main`.
  Publica `ghcr.io/<seu-usuario>/go-web:dev`, a tag usada pelo deploy
  permanente (`go-web-application.yaml`).

Um detalhe do GHCR que pega gente de surpresa: **pacotes nascem privados**.
Depois do primeiro push de imagem, é preciso ir em
`github.com/<seu-usuario>?tab=packages` → pacote `go-web` → *Package
settings* → *Change visibility* → público. Sem isso, o cluster não consegue
puxar a imagem (`ImagePullBackOff`), mesmo com tudo o mais certo.

## 1.8 O coração da oficina: preview environments com `pullRequest.github`

`gitops/argocd/config/appsofapps/preview-environment.yaml` é um
`ApplicationSet`:

```yaml
generators:
  - pullRequest:
      github:
        owner: marcellmartini
        repo: devops-tools
        tokenRef:
          secretName: github-token
          key: token
        labels:
          - preview
      requeueAfterSeconds: 15
template:
  metadata:
    name: 'pre-env-{{.branch}}-{{.number}}'
  spec:
    source:
      repoURL: 'https://github.com/marcellmartini/devops-tools.git'
      targetRevision: '{{.head_sha}}'
      path: apps/apps/go-web/helm/
      helm:
        parameters:
          - name: "image.tag"
            value: 'pr-{{.number}}'
          - name: "namespace"
            value: 'pre-env-{{.branch}}-{{.number}}'
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
      syncOptions:
        - CreateNamespace=true
```

O que acontece, passo a passo:

1. A cada **15 segundos** (`requeueAfterSeconds`), o generator consulta a API
   do GitHub perguntando: "quais PRs abertas em `owner/repo` têm a label
   `preview`?"
2. Para cada PR encontrada, ele expõe variáveis (`{{.branch}}`, `{{.number}}`,
   `{{.head_sha}}`) que o `template` usa para gerar uma `Application` única:
   nome `pre-env-<branch>-<numero>`, deployada no **namespace próprio**
   `pre-env-<branch>-<numero>` (`CreateNamespace=true` cria o namespace na
   hora), com a imagem `pr-<numero>` (a mesma tag que
   `build-push-docker.yml` acabou de publicar) e o chart lido **exatamente do
   commit da PR** (`targetRevision: '{{.head_sha}}'` — não do branch, do SHA
   exato, então mudanças posteriores na PR só entram quando o generator
   detectar o novo `head_sha`).
3. Quando a PR **fecha** (ou perde a label `preview`), ela some da resposta da
   API na próxima consulta. O `ApplicationSet` então remove a `Application`
   correspondente — e como ela tinha `prune: true`, o ArgoCD deleta todos os
   recursos que ela gerenciava, **incluindo o namespace**. O ambiente é
   efêmero de ponta a ponta: nasce com a PR, morre com ela, sem intervenção
   manual.

### Por que o secret `github-token` importa de verdade

A API do GitHub sem autenticação tem limite de **60 requisições/hora**. O
generator consulta a cada 15s — isso são **~240 requisições/hora**, sozinho já
estourando o limite anônimo. Na prática, sem o secret `github-token`, o
generator para de funcionar depois de poucos minutos (rate limit). Por isso
ele é tratado como obrigatório na oficina, mesmo a `ApplicationSet` marcando o
campo como opcional no comentário do YAML.

**Limitação a ter em mente:** o generator é `pullRequest.github` — ele
depende de uma PR real, publicada no GitHub. Não existe hoje um generator
local/offline equivalente; a demonstração de preview environments exige o
fluxo real com fork + PR.

---

# Parte 2 — Passo a passo prático

## 2.1 Fork e apontamento

1. Dê fork neste repositório no GitHub.
2. Clone o seu fork e rode o script de setup, que reaponta `repoURL`, o
   `owner` do generator de preview e a imagem do `go-web` para o seu usuário:

   ```shell
   $ ./scripts/setup-fork.sh <seu-usuario-github>
   $ git diff   # revise o que mudou
   $ git add -A && git commit -m "chore: point manifests to my fork"
   $ git push
   ```

## 2.2 Cluster local

```shell
# kind
$ kind create cluster --config k8s/clusters/kind/kind_cluster.yml

# ou minikube
$ minikube start --driver=docker --nodes 4
```

## 2.3 LoadBalancer (MetalLB no kind / tunnel no minikube)

```shell
# só no kind — gera o pool de IPs a partir da subnet real da sua rede docker
$ ./scripts/setup-metallb-pool.sh
$ kubectl apply -k k8s/metallb/

# no minikube, em outro terminal, deixe rodando durante a oficina:
$ minikube tunnel
```

## 2.4 Instalar o ArgoCD

```shell
$ kubectl apply -k gitops/argocd/install/
$ kubectl get pods -n argocd    # espere todos os pods ficarem Running
```

Acesse a UI (opcional, mas ajuda a visualizar o que vem a seguir):

```shell
$ kubectl port-forward service/argocd-server -n argocd 8080:443 &
$ kubectl -n argocd get secrets argocd-initial-admin-secret -o yaml | \
    awk '/password/ {print $2}' | base64 -d
```

Login em `https://localhost:8080` com usuário `admin` e a senha acima.

## 2.5 Secret do GitHub (obrigatório — veja seção 1.8)

Crie um PAT (classic, escopo `repo`, ou fine-grained com `Pull requests:
read`) em `github.com/settings/tokens`, então:

```shell
$ kubectl create secret generic github-token -n argocd \
    --from-literal=token=<seu-PAT>
```

## 2.6 Bootstrap — um único apply

```shell
$ kubectl apply -f gitops/argocd/config/appsofapps/appsofapps.yaml
```

Isso sozinho traz `go-web-application` e `preview-environment` junto (seção
1.2). Confira:

```shell
$ kubectl get applications -n argocd
```

`go-web-app` deve sincronizar e ficar `Healthy`/`Synced` assim que a imagem
`ghcr.io/<seu-usuario>/go-web:dev` existir e estiver pública (seção 1.7) —
publicada automaticamente na primeira vez que você der push para `main`.

## 2.7 Disparar uma preview environment

1. Crie um branch, altere algo em `apps/apps/go-web/src/main.go` (ex.: mude o
   texto retornado), e abra uma Pull Request no seu fork.
2. Adicione a label `preview` na PR.
3. O `build-push-docker.yml` builda e publica
   `ghcr.io/<seu-usuario>/go-web:pr-<numero>` — acompanhe em *Actions* na
   sua PR.
4. Em até 15s depois da imagem publicada, o `ApplicationSet` cria a
   `Application`/namespace `pre-env-<branch>-<numero>`:

   ```shell
   $ kubectl get applications -n argocd
   $ kubectl get ns | grep pre-env-
   $ kubectl port-forward svc/go-web-service -n pre-env-<branch>-<numero> 8080:80
   ```

   Acesse `http://localhost:8080` — é o seu ambiente efêmero, isolado, criado
   só para essa PR.
5. Feche a PR (ou remova a label `preview`) e observe: em até 15s a
   `Application` e o namespace inteiro somem sozinhos.

## 2.8 Problemas comuns

| Sintoma                                  | Causa provável                                                                                                           |
|------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| `go-web-app` em `ImagePullBackOff`       | Tag `dev` não publicada ainda (dê um push em `main`) ou pacote GHCR privado (seção 1.7)                                  |
| Preview não aparece após abrir a PR      | Falta a label `preview`, ou o `github-token` está errado/ausente (rate limit — seção 1.8)                                |
| `LoadBalancer` sem `EXTERNAL-IP` no kind | Pool do MetalLB desatualizado — rode `./scripts/setup-metallb-pool.sh` de novo (a subnet muda se você recriar o cluster) |
| `ImagePullBackOff` na preview            | Imagem `pr-<numero>` ainda buildando — confira a aba *Actions* da PR                                                     |
