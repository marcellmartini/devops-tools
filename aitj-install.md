1. kubectl apply -k ./gitops/argocd/install/
3. kubectl apply -f ./gitops/argocd/config/secret.yaml
4. kubectl apply -f ./gitops/argocd/config/appsofapps.yaml
5. Open PR
6. Close PR
7. kubectl delete -f ./gitops/argocd/config/appsofapps.yaml
8. kubectl delete -k ./gitops/argocd/install/

