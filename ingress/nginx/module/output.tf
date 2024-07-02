output "chart_status" {
  value = helm_release.ingress_nginx.status
}

output "chart_name" {
  value = helm_release.ingress_nginx.name
}
