1. kubectl apply -k ./gitops/argocd/install/
3. kubectl apply -f ./gitops/argocd/config/secret.yaml
4. kubectl apply -f ./gitops/argocd/config/appsofapps.yaml
5. kubectl -n argocd get secrets argocd-initial-admin-secret -o yaml |
     awk '/password/ {print $2}' |
     base64 -d
6. kubectl port-forward -n argocd pods/argocd-server 8080:8080
7. Logar no GitHub.
8. Open PR
9. Close PR
10. kubectl delete -f ./gitops/argocd/config/appsofapps.yaml
11. kubectl delete -k ./gitops/argocd/install/

