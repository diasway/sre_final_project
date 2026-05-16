# SRE Capstone Project - Production Readiness Review

**Project:** Shop SRE API - production-ready microservice infrastructure  
**Team:** Mukhametkali Dias, Qaldyqan Yerzat  
**Course Deliverable:** Endterm & Final Exam: SRE Capstone Project - Production Readiness Review

This repository contains a complete SRE capstone implementation: Infrastructure as Code, CI/CD, Kubernetes deployment, observability, alerting, SLOs, autoscaling, and load testing.

## 1. Architecture

The project deploys a small e-commerce style API called `shop-sre-api`. It exposes product and checkout endpoints, publishes Prometheus metrics, runs on Kubernetes, and is monitored through Prometheus and Grafana.

```text
Developer push -> GitHub Actions -> Docker image -> GHCR registry -> Kubernetes deployment
                                                        |
                                                        v
                         Prometheus <- ServiceMonitor <- shop-sre-api /metrics
                              |
                              v
                         Grafana dashboards + Alertmanager alerts
                              |
                              v
                         SLO review and incident response
```

## 2. Repository structure

```text
.
├── app/                         # FastAPI microservice with Prometheus metrics
├── tests/                       # Unit tests for the service
├── docker/                      # Docker helper files
├── k8s/base/                    # Kubernetes namespace, deployment, service, HPA
├── k8s/observability/           # ServiceMonitor, PrometheusRule, Grafana dashboard ConfigMap
├── terraform/                   # IaC for Kubernetes namespace, app, HPA, and monitoring stack
├── load-testing/                # Locust load test scenario
├── scripts/                     # Local deployment and evidence collection helpers
├── docs/                        # Report source, diagrams, defense notes, screenshot checklist
├── .github/workflows/           # CI/CD pipeline
├── Dockerfile
├── Makefile
└── docker-compose.yml           # Optional local app + Prometheus + Grafana demo
```

## 3. Prerequisites

Install these tools:

- Docker Desktop or Docker Engine
- Kubernetes cluster: Minikube, Docker Desktop Kubernetes, or a cloud cluster
- kubectl
- Terraform >= 1.6
- Helm >= 3
- Python >= 3.11
- GitHub account with a public repository

For Minikube:

```bash
minikube start --cpus=4 --memory=6144
minikube addons enable metrics-server
```

## 4. Run locally without Kubernetes

```bash
python -m venv .venv
source .venv/bin/activate  # Windows Git Bash: source .venv/Scripts/activate
pip install -r app/requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Test:

```bash
curl http://localhost:8000/healthz
curl http://localhost:8000/products
curl http://localhost:8000/metrics
curl "http://localhost:8000/cpu?iterations=180000"
```

## 5. Build Docker image

```bash
docker build -t shop-sre-api:local .
docker run --rm -p 8000:8000 shop-sre-api:local
```

## 6. Deploy monitoring stack with Terraform

Terraform uses Kubernetes and Helm providers. It provisions:

- `sre-prr` namespace
- `monitoring` namespace
- kube-prometheus-stack Helm release
- application Deployment and Service
- HorizontalPodAutoscaler

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Default image is `shop-sre-api:local`. For a registry image, edit `terraform.tfvars`:

```hcl
image_repository = "ghcr.io/YOUR_GITHUB_USERNAME/YOUR_REPO/shop-sre-api"
image_tag        = "latest"
```

## 7. Apply observability resources

After Prometheus Operator CRDs are installed by Terraform:

```bash
kubectl apply -f k8s/observability/
```

Check resources:

```bash
kubectl get pods -n sre-prr
kubectl get hpa -n sre-prr
kubectl get servicemonitor -n sre-prr
kubectl get prometheusrule -n sre-prr
```

## 8. Access the application and Grafana

Application:

```bash
kubectl -n sre-prr port-forward svc/shop-sre-api 8000:80
curl http://localhost:8000/healthz
```

Grafana:

```bash
kubectl -n monitoring port-forward svc/sre-monitoring-grafana 3000:80
```

Open `http://localhost:3000`.

Default credentials from `terraform/values-kube-prometheus.yaml`:

```text
user: admin
password: sre-capstone-admin
```

## 9. Run load testing

Install Locust:

```bash
pip install locust
```

Run Locust traffic that includes product browsing, checkout, slow requests, and CPU-bound requests:

```bash
locust -f load-testing/locustfile.py --host http://localhost:8000
```

Or headless:

```bash
locust -f load-testing/locustfile.py --host http://localhost:8000 \
  --headless -u 150 -r 20 --run-time 5m
```

Watch HPA scaling:

```bash
kubectl get hpa -n sre-prr -w
kubectl get pods -n sre-prr -w
```

## 10. GitHub Actions CI/CD

The workflow is in `.github/workflows/ci-cd.yml`.

It performs:

1. Python dependency installation
2. Unit tests
3. Docker image build
4. Push to GitHub Container Registry
5. Kubernetes deployment update
6. Rollout status verification

Set this secret in GitHub for deployment:

```text
KUBE_CONFIG_B64
```

PowerShell command to create the secret value:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\.kube\config"))
```

Linux/Git Bash command:

```bash
base64 -w 0 ~/.kube/config
```

## 11. Screenshots required for final submission

The report already contains the correct technical sections. For final submission, replace the screenshot placeholders with real evidence from your run:

- GitHub Actions successful run
- Docker image in GHCR
- Terraform apply output
- Kubernetes pods and services
- Grafana dashboard with traffic
- Prometheus alert rules
- Alertmanager firing alert
- HPA scaling during Locust traffic

Use `docs/SCREENSHOT_CHECKLIST.md` for exact commands and screenshot points.

## 12. SLO summary

| User Journey | SLI | SLO |
|---|---|---|
| Product browsing | Availability | 99.5% successful non-5xx responses per 30 days |
| Checkout | Availability | 99.0% successful non-5xx responses per 30 days |
| API latency | Latency | 95% of requests below 300 ms |
| Incident response | Recovery | rollback or mitigation within 15 minutes |

## 13. Team contribution

| Member | Main role | Contribution |
|---|---|---|
| Mukhametkali Dias | Incident Commander / CI-CD Engineer | GitHub Actions, Docker image flow, deployment validation, defense explanation |
| Qaldyqan Yerzat | Operations / Observability Engineer | Terraform, Kubernetes manifests, Prometheus/Grafana, alerts, load testing |

Both members must understand all sections for the live defense.
