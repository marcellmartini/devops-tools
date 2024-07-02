module "ingress" {
  source = "../../module"

  # Uncomment the line below if you have a LoadBalancer
  # configured in your cluster
  # controler_service_type = "LoadBalancer"
}
