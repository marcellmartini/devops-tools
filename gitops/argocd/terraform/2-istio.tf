# resource "kubernetes_namespace" "istio_system" {
#   metadata {
#     name = "istio-system"
#   }
# }
#
# resource "helm_release" "istio_base" {
#   name = "my-istio-base"
#
#   repository       = "https://istio-release.storage.googleapis.com/charts"
#   chart            = "base"
#   namespace        = kubernetes_namespace.istio_system.metadata[0].name
#   create_namespace = false
#   version          = "1.22.1"
#
#   set {
#     name  = "defaultRevision"
#     value = "default"
#   }
#
#   depends_on = [ kubernetes_namespace.istio_system ]
# }
#
# resource "helm_release" "istiod" {
#   name = "my-istio-d"
#
#   repository       = "https://istio-release.storage.googleapis.com/charts"
#   chart            = "istiod"
#   namespace        = kubernetes_namespace.istio_system.metadata[0].name
#   create_namespace = false
#   version          = "1.17.2"
#
#   depends_on = [
#     helm_release.istio_base
#   ]
# }
#
# resource "helm_release" "istio_gateway" {
#   name = "ingressgateway"
#
#   repository       = "https://istio-release.storage.googleapis.com/charts"
#   chart            = "gateway"
#   namespace        = kubernetes_namespace.istio_ingress.metadata[0].name
#   create_namespace = false
#   version          = "1.17.2"
#
#   depends_on = [
#     helm_release.istiod
#   ]
# }
#
# resource "kubernetes_namespace" "istio_ingress" {
#   metadata {
#     name = "istio-ingress"
#   }
# }
#
# resource "kubernetes_labels" "default_namespace" {
#   api_version = "v1"
#   kind        = "Namespace"
#   metadata {
#     name = "default"
#   }
#   labels = {
#     "istio-injection" = "enabled"
#   }
# }
