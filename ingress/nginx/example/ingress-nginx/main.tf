module "ingress" {
  source = "../../module"

  attributes = [
    {
      name  = "controller.service.type"
      value = "NodePort"
    }
  ]
}
