resource "helm_release" "argocd" {
  name = "argocd"

  create_namespace = true
  namespace        = "argocd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.3.4"

  values = [file("values/argocd-helm-values.yaml")]
}
