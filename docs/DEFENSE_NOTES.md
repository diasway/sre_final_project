# Defense notes

## Project overview

Our project is a Production Readiness Review for a small e-commerce microservice named `shop-sre-api`. The service has product browsing and checkout endpoints, and it exposes Prometheus metrics through `/metrics`. We deployed it to Kubernetes and prepared it with IaC, CI/CD, observability, alerting, autoscaling, and load testing.

## Why this architecture is production-ready

The system is reproducible because infrastructure is described with Terraform and Kubernetes manifests. The service is containerized with Docker. The CI/CD pipeline tests the code, builds an image, pushes it to a registry, and updates the Kubernetes deployment. Monitoring is based on Prometheus, Grafana, and Alertmanager. Reliability is measured with SLIs and SLOs.

## IaC explanation

Terraform creates the application namespace, monitoring namespace, Prometheus/Grafana stack, application Deployment, Service, and HPA. Variables are used for image repository, image tag, namespace, replica count, and failure rate. Terraform state is stored locally for this course demo and excluded from Git so it is not accidentally committed.

## CI/CD explanation

GitHub Actions runs automatically on push to the main branch. First it installs Python dependencies and runs unit tests. Then it builds a Docker image and pushes it to GitHub Container Registry. If the Kubernetes secret is configured, it applies manifests and updates the deployment image to the new commit SHA.

## Observability explanation

The application exports request count, request duration, in-progress requests, checkout result counters, and inventory gauges. Prometheus scrapes `/metrics` using ServiceMonitor. Grafana visualizes request rate, error rate, p95 latency, and available replicas. Alertmanager receives alerts when error rate or latency exceeds the SLO threshold.

## SLO explanation

The main SLOs are availability and latency. Product browsing should have at least 99.5% successful responses over 30 days. Checkout should have at least 99.0% successful responses. For latency, 95% of API requests should be below 300 ms. These SLOs are realistic for a demo service and measurable using Prometheus metrics.

## Autoscaling explanation

The HorizontalPodAutoscaler scales the deployment from 2 to 6 replicas based on CPU utilization. Each pod has CPU requests and limits, so Kubernetes can calculate utilization correctly. During Locust load testing, traffic increases CPU usage and HPA adds more replicas.

## Load testing explanation

Locust simulates users browsing products, performing checkout, calling health checks, and occasionally using a slow endpoint. This creates realistic traffic and allows us to test how the system behaves under spikes.

## Individual contribution

Mukhametkali Dias focused on CI/CD, Docker image flow, deployment validation, and defense preparation. Qaldyqan Yerzat focused on Terraform, Kubernetes, Prometheus/Grafana, alerting, and load testing. Both members reviewed all parts because the defense requires technical understanding from both students.

## Possible questions and answers

### Why did you choose Kubernetes?

Kubernetes gives us standard production mechanisms: deployments, services, health probes, rolling updates, and autoscaling. It also integrates well with Prometheus and Grafana.

### Why do we need Terraform if we already have YAML files?

Terraform manages infrastructure reproducibly and tracks state. YAML files define Kubernetes resources, but Terraform gives an IaC workflow with plan/apply and variable management.

### What is an SLI?

An SLI is a measurable reliability indicator, such as request success rate, p95 latency, or pod availability.

### What is an SLO?

An SLO is a target for an SLI. For example, 99.5% successful requests over 30 days.

### What happens when a new version is pushed?

GitHub Actions runs tests, builds the Docker image, pushes it to GHCR, updates the Kubernetes deployment, and waits for rollout status.

### How do alerts work?

Prometheus evaluates rules. If a rule is true for a specified duration, the alert fires and Alertmanager receives it.

### How did you test scaling?

We used Locust to generate traffic and watched HPA with `kubectl get hpa -w`. When CPU utilization increased, Kubernetes increased the number of replicas.
