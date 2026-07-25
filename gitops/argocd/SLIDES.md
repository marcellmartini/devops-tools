---
title: "Oficina: Preview Environments com ArgoCD"
sub_title: GitOps na prática — do fork ao ambiente efêmero
author: Marcell Martini
---

Objetivo
===

Ao final desta oficina você vai ter:

<!-- pause -->

- Um cluster Kubernetes local (kind ou minikube) rodando ArgoCD
<!-- pause -->
- Uma aplicação (`go-web`) gerenciada via GitOps — o cluster reflete o Git,
  não o contrário
<!-- pause -->
- Uma Pull Request no seu fork que **cria** automaticamente um ambiente
  isolado — e que **se destrói sozinha** quando a PR fecha

<!-- speaker_note: enfatizar que o foco é "ver acontecer ao vivo", não só slides -->

<!-- end_slide -->

Pré-requisitos
===

- Docker
- `kubectl`
- `kustomize`
- `kind` ou `minikube`
- Conta no GitHub + fork deste repositório

<!-- end_slide -->

<!-- jump_to_middle -->

Parte 1
===

# Conceitos

<!-- end_slide -->

ArgoCD: o que é `Application`
===

A unidade básica do ArgoCD: um CRD que diz

> "sincronize `source.path` do `source.repoURL` para
> `destination.namespace` neste cluster"

<!-- pause -->

```yaml {6-8}
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

<!-- pause -->

`prune` + `selfHeal` = GitOps de verdade: **zero drift** entre Git e cluster.

<!-- end_slide -->

O padrão app-of-apps
===

Gerenciar uma `Application` por vez não escala.

<!-- pause -->

Uma `Application` **raiz** aponta para um diretório cheio de outras
`Applications`/`ApplicationSets`. O ArgoCD sincroniza a raiz, descobre os
filhos, passa a gerenciar todos.

<!-- pause -->

```text
appsofapps.yaml (raiz)
  └─ aponta para gitops/argocd/config/appsofapps/
       ├─ appsofapps.yaml            (a si mesma)
       ├─ go-web-application.yaml    (deploy permanente)
       └─ preview-environment.yaml   (ApplicationSet de preview)
```

<!-- pause -->

Um único `kubectl apply -f appsofapps.yaml` faz o bootstrap de tudo.

<!-- end_slide -->

`ApplicationSet` e generators
===

Uma `Application` é estática. Um `ApplicationSet` **gera várias** a partir de
um `template`, usando um *generator* como fonte de variáveis.

<!-- pause -->

Generators comuns:

- `list` — lista fixa
- `git` — diretórios/arquivos de um repo
- `cluster` — um `Application` por cluster registrado
- **`pullRequest`** — um `Application` por Pull Request aberta 👈

<!-- pause -->

`ApplicationSet` + `pullRequest.github` = preview environments. É o coração
desta oficina (Parte 1, seção final).

<!-- end_slide -->

Kustomize vs. Helm — por que os dois
===

<!-- column_layout: [1, 1] -->

<!-- column: 0 -->

### Kustomize

Patches pontuais sobre manifests de terceiros:

- instalação do ArgoCD
- MetalLB

<!-- column: 1 -->

### Helm

Nossa app, parâmetros variáveis por ambiente:

- `go-web` (namespace, tag de imagem...)

<!-- reset_layout -->

<!-- pause -->

Cada `Application` escolhe uma das duas só apontando `source.path` para uma
pasta com `kustomization.yaml` ou `Chart.yaml`.

<!-- end_slide -->

A aplicação de exemplo: `go-web`
===

`apps/apps/go-web/`

- `src/` — servidor HTTP em Go, ~15 linhas
- `helm/` — o chart

<!-- pause -->

```yaml
namespace: dev
image:
  repository: ghcr.io/marcellmartini/go-web
  tag: 'dev'
```

<!-- pause -->

O **mesmo chart**, sem mudar código, serve:

- o deploy permanente (tag `dev`)
- cada preview environment (tag `pr-<numero>`, namespace isolado)

<!-- end_slide -->

Rede local: kind vs. minikube
===

`Service` tipo `LoadBalancer` normalmente depende de um cloud provider.
Localmente isso não existe.

<!-- pause -->

- **minikube** → `minikube tunnel` simula o load balancer, pronto
- **kind** → precisa do **MetalLB**: atribui IP de um pool
  (`IPAddressPool`) e anuncia na rede local via `L2Advertisement`

<!-- pause -->

⚠️ A rede docker do `kind` tem subnet **alocada dinamicamente** — muda por
host/execução. `scripts/setup-metallb-pool.sh` detecta a subnet real e
regenera o pool antes de aplicar.

<!-- end_slide -->

Pipeline de imagem: do código ao GHCR
===

Duas GitHub Actions, ambas publicando em `ghcr.io` com o `GITHUB_TOKEN`
automático — **nenhum secret manual**:

<!-- pause -->

| Workflow | Dispara em | Publica |
|---|---|---|
| `build-push-docker.yml` | PR tocando `go-web/src/*` | `go-web:pr-<numero>` |
| `main-build.yml` | push em `main` | `go-web:dev` |

<!-- pause -->

⚠️ Pacotes do GHCR **nascem privados**. Primeiro push → tornar público em
*Package settings* → *Change visibility*, senão `ImagePullBackOff`.

<!-- end_slide -->

<!-- jump_to_middle -->

Parte 1 (final)
===

# O coração da oficina: `pullRequest.github`

<!-- end_slide -->

O generator `pullRequest.github`
===

```yaml {4-9|10}
generators:
  - pullRequest:
      github:
        owner: marcellmartini
        repo: devops-tools
        tokenRef:
          secretName: github-token
          key: token
        labels: [preview]
      requeueAfterSeconds: 15
```

<!-- pause -->

A cada **15s**, consulta a API do GitHub: "quais PRs abertas em `owner/repo`
têm a label `preview`?"

<!-- end_slide -->

O template — uma `Application` por PR
===

```yaml {2|4|6|8-9}
template:
  metadata:
    name: 'pre-env-{{.branch}}-{{.number}}'
  spec:
    source:
      targetRevision: '{{.head_sha}}'
      helm:
        parameters:
          - name: "image.tag"
            value: 'pr-{{.number}}'
```

<!-- pause -->

- namespace **próprio**: `pre-env-<branch>-<numero>`
- lê o chart **do commit exato** da PR (`head_sha`, não do branch)
- imagem: a mesma tag que o workflow acabou de publicar

<!-- end_slide -->

Ciclo de vida: nasce e morre com a PR
===

```text
PR aberta + label "preview"
        │
        ▼
  build-push-docker.yml publica go-web:pr-<N>
        │
        ▼ (até 15s depois)
  ApplicationSet cria Application "pre-env-<branch>-<N>"
        │  (CreateNamespace=true, prune+selfHeal)
        ▼
  namespace + deploy no ar
        │
        ▼
PR fecha (ou perde a label)
        │
        ▼ (até 15s depois)
  generator para de listar essa PR → Application é removida
        │  (prune: true)
        ▼
  namespace inteiro é destruído — sem intervenção manual
```

<!-- end_slide -->

Por que o secret `github-token` importa de verdade
===

- API do GitHub sem autenticação: **60 requisições/hora**
<!-- pause -->
- O generator consulta a cada 15s: **~240 requisições/hora**, sozinho
<!-- pause -->
- Sem token → rate limit em poucos minutos → preview para de funcionar

<!-- pause -->

**Limitação:** o generator exige uma PR real no GitHub — não existe hoje
equivalente local/offline para testar 100% sem rede.

<!-- end_slide -->

Arquitetura: como tudo se conecta
===

```text
                            ── SOFTWARE ──

┌──────────────────┐      ┌──────────────────────┐      ┌──────────────────┐
│      GitHub      │      │    GitHub Actions    │      │       GHCR       │
│  fork + PR #<n>  │─────▶│     build-push-      │─────▶│      go-web      │
│  label: preview  │      │      docker.yml      │      │     :pr-<n>      │
└──────────────────┘      └──────────────────────┘      └──────────────────┘
    │
    │ poll a cada 15s
    │ (secret github-token)
    ▼
┌──────────────────────────────────────────┐
│          ArgoCD ApplicationSet           │
│      generator: pullRequest.github       │
└──────────────────────────────────────────┘
    │ cria Application
    │ (image.tag=pr-<n>)
    ▼
═══════════════════════════════════ INFRA ══════════════════════════════════════
┌─ cluster kind/minikube — namespace pre-env-<branch>-<numero> ────────────┐
│                                                                          │
│   ┌──────────────────────────┐      ┌──────────────────────┐             │
│   │    Deployment go-web     │      │    Service go-web    │             │
│   │   imagem: GHCR pr-<n>    │─────▶│     (ClusterIP)      │             │
│   └──────────────────────────┘      └──────────────────────┘             │
│                                       │ exposto via                      │
│                                       ▼                                  │
│                                     ┌──────────────────────┐             │
│                                     │      MetalLB /       │             │
│                                     │   minikube tunnel    │             │
│                                     └──────────────────────┘             │
└──────────────────────────────────────────────────────────────────────────┘
```

<!-- end_slide -->

<!-- jump_to_middle -->

Parte 2
===

# Mão na massa

<!-- end_slide -->

1. Fork e apontamento
===

```bash
$ ./scripts/setup-fork.sh <seu-usuario-github>
$ git diff   # revise
$ git add -A && git commit -m "chore: point manifests to my fork"
$ git push
```

Reaponta `repoURL`, `owner` do generator e a imagem do `go-web` para o seu
fork — automaticamente.

<!-- end_slide -->

2. Cluster local
===

```bash
# kind
$ kind create cluster --config k8s/clusters/kind/kind_cluster.yml

# ou minikube
$ minikube start --driver=docker --nodes 4
```

<!-- end_slide -->

3. LoadBalancer
===

```bash
# só no kind
$ ./scripts/setup-metallb-pool.sh
$ kubectl apply -k k8s/metallb/

# no minikube, em outro terminal:
$ minikube tunnel
```

<!-- end_slide -->

4. Instalar o ArgoCD
===

```bash
$ kubectl apply -k gitops/argocd/install/
$ kubectl get pods -n argocd

$ kubectl port-forward service/argocd-server -n argocd 8080:443 &
$ kubectl -n argocd get secrets argocd-initial-admin-secret -o yaml | \
    awk '/password/ {print $2}' | base64 -d
```

<!-- end_slide -->

5. Secret do GitHub
===

PAT (escopo `repo`, ou fine-grained com `Pull requests: read`):

```bash
$ kubectl create secret generic github-token -n argocd \
    --from-literal=token=<seu-PAT>
```

<!-- end_slide -->

6. Bootstrap — um único apply
===

```bash
$ kubectl apply -f gitops/argocd/config/appsofapps/appsofapps.yaml
$ kubectl get applications -n argocd
```

<!-- pause -->

`go-web-app` sincroniza sozinho assim que a imagem `go-web:dev` existir e
estiver pública.

<!-- end_slide -->

7. Acessar o `go-web-app`
===

Namespace `dev`, `Service` `ClusterIP`, sem Ingress — acesso via
port-forward. `8080` já está em uso pelo ArgoCD (passo 4), use `8081`:

```bash
$ kubectl port-forward svc/go-web-service -n dev 8081:80
```

<!-- pause -->

`http://localhost:8081` — o Deployment "permanente", fora do fluxo de
preview.

<!-- end_slide -->

8. Disparar uma preview environment
===

<!-- pause -->

**1.** Branch + mude algo em `go-web/src/main.go` → abra uma PR

<!-- pause -->

**2.** Adicione a label `preview`

<!-- pause -->

**3.** Acompanhe o build em *Actions*

<!-- pause -->

**4.** Em até 15s:

```bash
$ kubectl get applications -n argocd
$ kubectl get ns | grep pre-env-
$ kubectl port-forward svc/go-web-service \
    -n pre-env-<branch>-<numero> 8082:80
```

<!-- pause -->

**5.** Feche a PR → tudo some sozinho

<!-- end_slide -->

Problemas comuns
===

| Sintoma | Causa provável |
|---|---|
| `go-web-app` em `ImagePullBackOff` | tag `dev` não publicada, ou pacote GHCR privado |
| Preview não aparece | falta a label `preview`, ou `github-token` errado/ausente |
| `LoadBalancer` sem `EXTERNAL-IP` (kind) | pool do MetalLB desatualizado — rode `setup-metallb-pool.sh` de novo |
| `ImagePullBackOff` na preview | imagem `pr-<numero>` ainda buildando |

<!-- end_slide -->

<!-- jump_to_middle -->

Obrigado!
===

# Perguntas?

Documentação completa: `gitops/argocd/WORKSHOP.md`
