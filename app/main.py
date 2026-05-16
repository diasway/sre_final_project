import os
import random
import time
from typing import Dict, List

from fastapi import FastAPI, HTTPException, Query, Request, Response
from fastapi.responses import PlainTextResponse
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest
from pydantic import BaseModel, Field

APP_NAME = os.getenv("APP_NAME", "shop-sre-api")
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
FAILURE_RATE = float(os.getenv("FAILURE_RATE", "0.01"))

app = FastAPI(
    title="Shop SRE API",
    description="Small e-commerce API used for SRE production readiness review.",
    version=APP_VERSION,
)

HTTP_REQUESTS = Counter(
    "http_requests_total",
    "Total HTTP requests handled by the service.",
    ["method", "path", "status"],
)

HTTP_DURATION = Histogram(
    "http_request_duration_seconds",
    "HTTP request duration in seconds.",
    ["method", "path"],
    buckets=[0.005, 0.01, 0.025, 0.05, 0.1, 0.2, 0.3, 0.5, 1.0, 2.5, 5.0],
)

IN_PROGRESS = Gauge(
    "http_requests_in_progress",
    "Number of HTTP requests currently in progress.",
    ["method", "path"],
)

CHECKOUTS = Counter(
    "checkout_requests_total",
    "Checkout requests by result.",
    ["result"],
)

INVENTORY = Gauge(
    "shop_inventory_items",
    "Number of items currently available in the demo inventory.",
    ["sku"],
)

PRODUCTS: List[Dict[str, object]] = [
    {"sku": "keyboard-basic", "name": "Basic Keyboard", "price": 19.99, "stock": 120},
    {"sku": "mouse-wireless", "name": "Wireless Mouse", "price": 14.99, "stock": 180},
    {"sku": "monitor-24", "name": "24 inch Monitor", "price": 129.99, "stock": 35},
    {"sku": "usb-c-hub", "name": "USB-C Hub", "price": 24.99, "stock": 65},
]

for product in PRODUCTS:
    INVENTORY.labels(sku=str(product["sku"])).set(int(product["stock"]))


class CheckoutRequest(BaseModel):
    sku: str = Field(..., examples=["keyboard-basic"])
    quantity: int = Field(..., ge=1, le=10, examples=[1])


@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    path = request.url.path
    method = request.method

    if path == "/metrics":
        return await call_next(request)

    start = time.perf_counter()
    IN_PROGRESS.labels(method=method, path=path).inc()
    status_code = 500

    try:
        response = await call_next(request)
        status_code = response.status_code
        return response
    finally:
        duration = time.perf_counter() - start
        IN_PROGRESS.labels(method=method, path=path).dec()
        HTTP_DURATION.labels(method=method, path=path).observe(duration)
        HTTP_REQUESTS.labels(method=method, path=path, status=str(status_code)).inc()


@app.get("/")
def root():
    return {
        "service": APP_NAME,
        "version": APP_VERSION,
        "message": "Shop SRE API is running",
    }


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/readyz")
def readyz():
    return {"status": "ready"}


@app.get("/products")
def products():
    return {"items": PRODUCTS}


@app.post("/checkout")
def checkout(order: CheckoutRequest):
    time.sleep(random.uniform(0.02, 0.18))

    product = next((item for item in PRODUCTS if item["sku"] == order.sku), None)
    if not product:
        CHECKOUTS.labels(result="not_found").inc()
        raise HTTPException(status_code=404, detail="Product not found")

    if random.random() < FAILURE_RATE:
        CHECKOUTS.labels(result="error").inc()
        raise HTTPException(status_code=503, detail="Temporary checkout dependency failure")

    if int(product["stock"]) < order.quantity:
        CHECKOUTS.labels(result="out_of_stock").inc()
        raise HTTPException(status_code=409, detail="Insufficient stock")

    product["stock"] = int(product["stock"]) - order.quantity
    INVENTORY.labels(sku=str(product["sku"])).set(int(product["stock"]))
    CHECKOUTS.labels(result="success").inc()

    return {
        "status": "accepted",
        "sku": order.sku,
        "quantity": order.quantity,
        "remaining_stock": product["stock"],
    }


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/slow")
def slow_endpoint():
    time.sleep(random.uniform(0.4, 1.2))
    return {"status": "slow path completed"}


@app.get("/cpu")
def cpu_endpoint(iterations: int = Query(120000, ge=1000, le=2000000)):
    total = 0
    for i in range(iterations):
        total += (i * i) % 97
    return {"status": "cpu work completed", "checksum": total}


@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    if isinstance(exc, HTTPException):
        raise exc
    return PlainTextResponse("Internal Server Error", status_code=500)
