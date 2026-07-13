module "ingress" {
  source = "../../module"

  attributes = [
    {
      name  = "controller.service.type"
      value = "NodePort"
    },
    {
      name  = "controller.extraArgs.enable-ssl-passthrough"
      value = "true"

    }
  ]
}
