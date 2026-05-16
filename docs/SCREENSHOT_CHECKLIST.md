# Screenshot checklist for final report

Do not fake screenshots. Run the project and insert real screenshots into the final report.

## 1. Terraform apply

Command:

```bash
cd terraform
terraform init
terraform validate
terraform apply
```

Screenshot: terminal showing successful `Apply complete` and resource count.

## 2. GitHub Actions CI/CD

Open GitHub repository -> Actions -> latest workflow run.

Screenshot: green successful workflow with test, build, push, and deploy steps.

## 3. Docker image registry

Open GitHub repository -> Packages -> `shop-sre-api`.

Screenshot: image package with latest tag or commit SHA tag.

## 4. Kubernetes deployment

Command:

```bash
kubectl get pods -n sre-prr -o wide
kubectl get svc -n sre-prr
kubectl rollout status deployment/shop-sre-api -n sre-prr
```

Screenshot: running pods, service, rollout success.

## 5. Prometheus targets

Port-forward Prometheus or open the Prometheus UI from kube-prometheus-stack.

Typical command:

```bash
kubectl -n monitoring port-forward svc/sre-monitoring-kube-prometheus-prometheus 9090:9090
```

Open `http://localhost:9090/targets`.

Screenshot: `shop-sre-api` target is UP.

## 6. Grafana dashboard

Command:

```bash
kubectl -n monitoring port-forward svc/sre-monitoring-grafana 3000:80
```

Open `http://localhost:3000`.

Credentials:

```text
admin / sre-capstone-admin
```

Screenshot: SRE Capstone dashboard showing request rate, error rate, p95 latency, and replicas.

## 7. Alertmanager alert

Trigger alert:

```bash
./scripts/trigger_alert.sh
kubectl -n sre-prr port-forward svc/shop-sre-api 8000:80
locust -f load-testing/locustfile.py --host http://localhost:8000 --headless -u 150 -r 20 --run-time 5m
```

Open Alertmanager:

```bash
kubectl -n monitoring port-forward svc/sre-monitoring-kube-prometheus-alertmanager 9093:9093
```

Screenshot: `ShopApiHighErrorRate` or `ShopApiHighLatencyP95` firing.

Reset failure rate:

```bash
kubectl -n sre-prr set env deployment/shop-sre-api FAILURE_RATE=0.01
```

## 8. HPA scaling

Commands:

```bash
kubectl get hpa -n sre-prr -w
kubectl get pods -n sre-prr -w
```

Run Locust traffic in another terminal.

Screenshot: HPA moving from 2 replicas to a higher number during load.
