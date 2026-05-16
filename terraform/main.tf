resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = var.app_namespace
    labels = {
      name = var.app_namespace
    }
  }
}

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = var.monitoring_namespace
    labels = {
      name = var.monitoring_namespace
    }
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "sre-monitoring"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "67.5.0"

  values = [file("${path.module}/values-kube-prometheus.yaml")]

  depends_on = [kubernetes_namespace_v1.monitoring]
}

resource "kubernetes_deployment_v1" "app" {
  metadata {
    name      = "shop-sre-api"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels = {
      app = "shop-sre-api"
    }
  }

  spec {
    replicas = var.replicas

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "0"
        max_surge       = "1"
      }
    }

    selector {
      match_labels = {
        app = "shop-sre-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "shop-sre-api"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path"   = "/metrics"
          "prometheus.io/port"   = "8000"
        }
      }

      spec {
        container {
          name              = "shop-sre-api"
          image             = "${var.image_repository}:${var.image_tag}"
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 8000
          }

          env {
            name  = "APP_NAME"
            value = "shop-sre-api"
          }

          env {
            name  = "APP_VERSION"
            value = var.image_tag
          }

          env {
            name  = "FAILURE_RATE"
            value = var.failure_rate
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/readyz"
              port = "http"
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 2
            failure_threshold     = 3
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "http"
            }
            initial_delay_seconds = 15
            period_seconds        = 20
            timeout_seconds       = 2
            failure_threshold     = 3
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace_v1.app]
}

resource "kubernetes_service_v1" "app" {
  metadata {
    name      = "shop-sre-api"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels = {
      app = "shop-sre-api"
    }
    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/path"   = "/metrics"
      "prometheus.io/port"   = "8000"
    }
  }

  spec {
    selector = {
      app = "shop-sre-api"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8000
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "app" {
  metadata {
    name      = "shop-sre-api-hpa"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  spec {
    min_replicas = 2
    max_replicas = 6

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.app.metadata[0].name
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 60
        }
      }
    }
  }
}
