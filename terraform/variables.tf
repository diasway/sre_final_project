variable "kubeconfig_path" {
  description = "Path to kubeconfig file."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubernetes context to use. Leave empty to use current context."
  type        = string
  default     = null
}

variable "app_namespace" {
  description = "Namespace for the application."
  type        = string
  default     = "sre-prr"
}

variable "monitoring_namespace" {
  description = "Namespace for Prometheus and Grafana."
  type        = string
  default     = "monitoring"
}

variable "image_repository" {
  description = "Container image repository."
  type        = string
  default     = "shop-sre-api"
}

variable "image_tag" {
  description = "Container image tag."
  type        = string
  default     = "local"
}

variable "replicas" {
  description = "Initial number of application replicas."
  type        = number
  default     = 2
}

variable "failure_rate" {
  description = "Injected failure rate for demo alerts."
  type        = string
  default     = "0.01"
}
