# Principais atividades com [Deployment][kubectl-deployment].

## Criar um yaml de [Deployment][kubectl-deployment].
Exemplo:
```shell
$ kubectl create deployment nginx --image nginx \
    -o yaml --dry-run=client > rs.yaml
```

## Escalar a quantidade de pods vida [Deployment][kubectl-deployment]:
1. Via edit:
    ```shell
    $ kubectl edit deployment <DEPLOYMENT_NAME>
    ```
   * alterar `spec.replicas` para o numero desejado de réplicas.

1. Via [scale command][kubectl-scale-command]:
    ```shell
    kubectl scale deployment <DEPLOYMENT_NAME> --replicas <NUM_REPLICAS>
    ```

## Realizar rollback com o [comando rollout][kubectl-rollout-command]:
Esse comando serve para realizar o `rollout` tanto para uma `revision` menor, quanto para uma maior do `Deployment` desejado.

```shell
$ kubectl rollout undo deployment <DEPLOYMENT_NAME> --to-revision <N_REVISION>
```

## Saber o status do rollout
```shell
$ kubectl rollout status deployment <DEPLOYMENT_NAME>
```

## Pausar o deployment
```shell
$ kubectl rollout pause deployment <DEPLOYMENT_NAME>
```

## Despausar o deployment
```shell
$ kubectl rollout resume deployment <DEPLOYMENT_NAME>
```

## Gravar no history o motivo do rollout:
Para gravar o motivo do rollout no hitory do rollout, basta colocar uma [annotation change-cause][kubectl-change-cause] do Deployment, como o comando abaixo.
```shell
$ kubectl annotate deployments.apps <DEPLOYMENT_NAME> \
    kubernetes.io/change-cause="CHANGES"
```

REF.:
1. [Well-Known Labels, Annotations and Taints][well-know-annotation-labels-taints]
2. [Recommended Labels][recommended-labes]

## Ver o history do rollout:
```shell
$ kubectl rollout history deployment <DEPLOYMENT_NAME>
```

# Estratégas de deployment

## strategy type
`strategy` especifica a estratégia usada para substituir pods antigos por novos. Existem 2 tipos:
* [Recreate][deployment-strategy-recreate]
* [RollingUpdate][deployment-strategy-rollingupdate]
>`RollingUpdate` é o valor padrão.

### Recreate
Todos os pods existentes são eliminados antes que novos sejam criados.

Configuração:
```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  strategy:
    type: Recreate
...
```

### RollingUpdate
Um processo de atualização continua pode ser utilizada configurado o RollingUpdate no Deployment.

Você pode especificar `maxUnavailable` e `maxSurge` para controlar o processo de atualização contínua.

* O `maxSurge` é um campo opcional que especifica o **número máximo de pods que podem ser criados** sobre o número desejado de pods.
    > O `valor padrão` é `25%`

* O `maxUnavailable` é um campo opcional que especifica o **número máximo de pods que podem ficar indisponíveis** durante o processo de atualização.
    > O `valor padrão` é `25%`

Configuração:
```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  strategy:
    type: RollingUpdate # essa linha é opcional neste caso
    rollingUpdate:
      maxSurge: 10%
      maxUnavailable: 0
...
```

[kubectl-deployment]:https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
[kubectl-scale-command]:https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#scale
[kubectl-rollout-command]:https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#rollout
[kubectl-change-cause]:https://kubernetes.io/docs/reference/labels-annotations-taints/#change-cause
[well-know-annotation-labels-taints]:https://kubernetes.io/docs/reference/labels-annotations-taints/
[recommended-labes]:https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/
[deployment-strategy-recreate]:https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#recreate-deployment
[deployment-strategy-rollingupdate]:https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-update-deployment
