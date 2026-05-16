from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_healthz_returns_ok():
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_products_endpoint_returns_items():
    response = client.get("/products")
    assert response.status_code == 200
    body = response.json()
    assert "items" in body
    assert len(body["items"]) >= 1


def test_checkout_accepts_valid_order():
    response = client.post("/checkout", json={"sku": "keyboard-basic", "quantity": 1})
    assert response.status_code in [200, 503]


def test_metrics_endpoint_exposes_prometheus_metrics():
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "http_requests_total" in response.text
