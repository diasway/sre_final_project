output "app_namespace" {
  value = kubernetes_namespace_v1.app.metadata[0].name
}

output "monitoring_namespace" {
  value = kubernetes_namespace_v1.monitoring.metadata[0].name
}

output "app_service" {
  value = "kubectl -n ${var.app_namespace} port-forward svc/shop-sre-api 8000:80"
}

output "grafana_access" {
  value = "kubectl -n ${var.monitoring_namespace} port-forward svc/sre-monitoring-grafana 3000:80"
}
