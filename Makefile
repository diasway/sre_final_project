IMAGE ?= shop-sre-api:local
NAMESPACE ?= sre-prr

.PHONY: test run docker-build docker-run terraform-init terraform-apply deploy-observability port-forward-app port-forward-grafana load-test clean

test:
	python -m pytest -q

run:
	uvicorn app.main:app --host 0.0.0.0 --port 8000

docker-build:
	docker build -t $(IMAGE) .

docker-run:
	docker run --rm -p 8000:8000 $(IMAGE)

terraform-init:
	cd terraform && terraform init

terraform-apply:
	cd terraform && terraform apply

deploy-observability:
	kubectl apply -f k8s/observability/

port-forward-app:
	kubectl -n $(NAMESPACE) port-forward svc/shop-sre-api 8000:80

port-forward-grafana:
	kubectl -n monitoring port-forward svc/sre-monitoring-grafana 3000:80

load-test:
	locust -f load-testing/locustfile.py --host http://localhost:8000 --headless -u 150 -r 20 --run-time 5m

clean:
	kubectl delete namespace $(NAMESPACE) --ignore-not-found=true
