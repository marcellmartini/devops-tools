# Ref.: https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx
resource "helm_release" "ingress_nginx" {
  name = var.release_name

  create_namespace = true
  namespace        = var.namespace

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  # Change the value of var.controler_service_type if you have
  # a LoadBalancer configured in the cluster.
  set {
    name  = "controller.service.type"
    value = var.controler_service_type
  }
}
