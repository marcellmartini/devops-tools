variable "controler_service_type" {
  type        = string
  default     = "NodePort"
  description = "Set the type of ingress"
}

variable "namespace" {
  type        = string
  default     = "ingress-nginx"
  description = "Namespace where ingress will be deployed"
}

variable "release_name" {
  type        = string
  default     = "ingress-nginx"
  description = "Helm release name"
}
