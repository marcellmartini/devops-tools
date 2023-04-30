Para criar um yaml do [ReplicaSet][kubectl-replicaset], basta criar um yaml do [Deployment][kubectl-deployment] e trocar o kind para [ReplicaSet][kubectl-replicaset] e remover o `strategy`.
Exemplo:
```shell
    $ kubectl create deployment nginx --image nginx -o yaml --dry-run=client > rs.yaml

    $ sed -i 's/Deployment/ReplicaSet/g' rs.yaml
    $ sed -i 's/strategy.*//g' rs.yaml
```

[kubectl-deployment]:https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
[kubectl-replicaset]:https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/
