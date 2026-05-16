from locust import HttpUser, between, task


class ShopApiUser(HttpUser):
    wait_time = between(0.2, 1.0)

    @task(4)
    def browse_products(self):
        self.client.get("/products", name="GET /products")

    @task(2)
    def checkout_keyboard(self):
        self.client.post(
            "/checkout",
            json={"sku": "keyboard-basic", "quantity": 1},
            name="POST /checkout",
        )

    @task(2)
    def cpu_path(self):
        self.client.get("/cpu?iterations=180000", name="GET /cpu")

    @task(1)
    def slow_path(self):
        self.client.get("/slow", name="GET /slow")

    @task(1)
    def health_check(self):
        self.client.get("/healthz", name="GET /healthz")
