#!/usr/bin/env bash
set -euo pipefail

# Temporarily increases the demo failure rate to make the high-error-rate alert easier to show.
kubectl -n sre-prr set env deployment/shop-sre-api FAILURE_RATE=0.35
kubectl -n sre-prr rollout status deployment/shop-sre-api --timeout=180s

echo "Now run load testing for 3-5 minutes and check Prometheus/Grafana/Alertmanager."
echo "To reset: kubectl -n sre-prr set env deployment/shop-sre-api FAILURE_RATE=0.01"
