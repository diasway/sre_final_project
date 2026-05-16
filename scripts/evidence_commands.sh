#!/usr/bin/env bash
set -euo pipefail

echo "=== Terraform state/resources ==="
(cd terraform && terraform state list || true)

echo "=== Application pods ==="
kubectl get pods -n sre-prr -o wide

echo "=== Application service ==="
kubectl get svc -n sre-prr

echo "=== HPA ==="
kubectl get hpa -n sre-prr

echo "=== ServiceMonitor ==="
kubectl get servicemonitor -n sre-prr

echo "=== PrometheusRule ==="
kubectl get prometheusrule -n sre-prr

echo "=== Grafana service ==="
kubectl get svc -n monitoring | grep grafana || true

echo "=== Alertmanager service ==="
kubectl get svc -n monitoring | grep alertmanager || true
