# Ref.: https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx
resource "helm_release" "ingress_nginx" {
  name = "ingress-nginx"

  create_namespace = true
  namespace        = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  # If keep the type as LoadBalancer and there isn´t a LoadBalancer
  # The TOFU will wait forever, becouse the LB will not get an IP.
  set {
    name  = "controller.service.type"
    value = "NodePort"
  }
}
