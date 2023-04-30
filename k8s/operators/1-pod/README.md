Criar o yaml de um pod:
```shell
    $ kubectl run <POD_NAME> --image <IMAGE> --dry-run=client -o yaml > pod.yaml
```

Buscar informações pelo kubenetes:
```shell
    $ kubectl explain <RESOURCE> --recursive
```

Para trocar pod usar o [replace][kubectl-replace] com `--grace-period 0`:
```shell
    $ kubectl replace --force --grace-period 0
```
Passar [command][kubectl-run] para o POD:

```shell
    $ kubectl run <POD_NAME> --image <IMAGE> --command -- <CMD> <ARG1> ... <ARGN>
```

[kubectl-replace]:https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#replace
[kubectl-run]:https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#run
