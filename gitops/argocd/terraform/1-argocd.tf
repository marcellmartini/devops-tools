resource "kubernetes_namespace" "argocd_namespace" {
  metadata {
    name = "argocd"

    labels = {
      "istio-injection" = "enabled"
    }
  }
}

resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = kubernetes_namespace.argocd_namespace.metadata[0].name
  create_namespace = false
  version          = "3.35.4"

  values = [file("values/argocd-helm-values.yaml")]
}

resource "kubernetes_manifest" "argocd_gateway" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1alpha3"
    "kind"       = "Gateway"
    "metadata" = {
      "name"      = "argocd-gateway"
      "namespace" = "argocd"
    }
    "spec" = {
      "selector" = {
        "istio" = "ingressgateway"
      }
      "servers" = [
        {
          "hosts" = [
            "*",
          ]
          "port" = {
            "name"     = "http"
            "number"   = 80
            "protocol" = "HTTP"
          }
        },
      ]
    }
  }
}

resource "kubernetes_manifest" "argocd_virtualservice" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1alpha3"
    "kind"       = "VirtualService"
    "metadata" = {
      "labels"    = null
      "name"      = "argocd"
      "namespace" = "argocd"
    }
    "spec" = {
      "gateways" = [
        "argocd-gateway",
      ]
      "hosts" = [
        "*",
      ]
      "http" = [
        {
          "route" = [
            {
              "destination" = {
                "host" = "argocd-server.argocd.svc.cluster.local"
                "port" = {
                  "number" = 80
                }
              }
            },
          ]
        },
      ]
    }
  }
}
