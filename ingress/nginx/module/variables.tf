variable "attributes" {
  type    = list(map(string))
  default = []
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

variable "chart_version" {
  type        = string
  default     = "4.10.1"
  description = "Version of the chart that will be installed"
}
