# Build image
# docker build -t shop-sre-api:local .

# Encode kubeconfig for GitHub secret KUBE_CONFIG_B64
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\.kube\config"))

# Port-forward application
# kubectl -n sre-prr port-forward svc/shop-sre-api 8000:80

# Port-forward Grafana
# kubectl -n monitoring port-forward svc/sre-monitoring-grafana 3000:80
