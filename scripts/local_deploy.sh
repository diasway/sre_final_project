#!/usr/bin/env bash
set -euo pipefail

IMAGE=${IMAGE:-shop-sre-api:local}

docker build -t "$IMAGE" .

if command -v minikube >/dev/null 2>&1; then
  minikube image load "$IMAGE" || true
fi

kubectl apply -f k8s/base/
kubectl -n sre-prr set image deployment/shop-sre-api shop-sre-api="$IMAGE"
kubectl -n sre-prr rollout status deployment/shop-sre-api --timeout=180s
kubectl apply -f k8s/observability/ || true
kubectl get pods -n sre-prr -o wide
