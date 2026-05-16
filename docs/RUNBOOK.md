# SRE runbook

## Service

`shop-sre-api` is a Kubernetes-hosted FastAPI service in namespace `sre-prr`.

## Key commands

```bash
kubectl get pods -n sre-prr -o wide
kubectl logs -n sre-prr deployment/shop-sre-api
kubectl describe deployment -n sre-prr shop-sre-api
kubectl get hpa -n sre-prr
kubectl rollout status deployment/shop-sre-api -n sre-prr
```

## Incident: high error rate

Symptoms:

- Grafana error rate panel increases
- `ShopApiHighErrorRate` alert fires
- Users report checkout errors

Diagnosis:

```bash
kubectl logs -n sre-prr deployment/shop-sre-api --tail=100
kubectl get pods -n sre-prr
kubectl describe pods -n sre-prr -l app=shop-sre-api
```

Mitigation:

```bash
kubectl -n sre-prr rollout undo deployment/shop-sre-api
kubectl -n sre-prr rollout status deployment/shop-sre-api
```

## Incident: high latency

Symptoms:

- p95 latency above 300 ms
- `ShopApiHighLatencyP95` alert fires

Diagnosis:

```bash
kubectl top pods -n sre-prr
kubectl get hpa -n sre-prr
```

Mitigation:

```bash
kubectl -n sre-prr scale deployment shop-sre-api --replicas=4
```

Then check whether HPA stabilizes the deployment.

## Incident: pod crash loop

Symptoms:

- Pod status is CrashLoopBackOff
- Restart alert fires

Diagnosis:

```bash
kubectl logs -n sre-prr <pod-name> --previous
kubectl describe pod -n sre-prr <pod-name>
```

Mitigation:

```bash
kubectl -n sre-prr rollout undo deployment/shop-sre-api
```
