import importlib.util
import os
import sys
import tempfile
import unittest

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
APP_PATH = os.path.join(ROOT, "mock-api", "app.py")

spec = importlib.util.spec_from_file_location("nexora_app", APP_PATH)
module = importlib.util.module_from_spec(spec)
sys.modules["nexora_app"] = module
spec.loader.exec_module(module)

app = module.app


class NexoraBackendTests(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        app.config["TESTING"] = True

    def login(self, usuario="ana", password="1234"):
        return self.client.post(
            "/api/auth/login",
            json={"usuario": usuario, "password": password},
        )

    def test_login_ok(self):
        resp = self.login()
        self.assertEqual(resp.status_code, 200)
        self.assertIn("token", resp.get_json())

    def test_login_bad_password(self):
        resp = self.login(password="bad")
        self.assertEqual(resp.status_code, 401)

    def test_cuentas_requires_auth(self):
        resp = self.client.get("/api/cuentas")
        self.assertEqual(resp.status_code, 401)

    def test_transfer_success(self):
        login = self.login()
        token = login.get_json()["token"]

        resp = self.client.post(
            "/api/transferencias",
            headers={"Authorization": f"Bearer {token}"},
            json={"cuentaOrigen": "100001", "cuentaDestino": "100002", "monto": 25000},
        )
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()["estado"], "EXITOSA")

    def test_transfer_insufficient_funds(self):
        login = self.login()
        token = login.get_json()["token"]

        resp = self.client.post(
            "/api/transferencias",
            headers={"Authorization": f"Bearer {token}"},
            json={"cuentaOrigen": "100001", "cuentaDestino": "100002", "monto": 999999999},
        )
        self.assertEqual(resp.status_code, 400)

    def test_transfer_cross_user_forbidden(self):
        login = self.login()
        token = login.get_json()["token"]

        resp = self.client.post(
            "/api/transferencias",
            headers={"Authorization": f"Bearer {token}"},
            json={"cuentaOrigen": "100001", "cuentaDestino": "200001", "monto": 1000},
        )
        self.assertIn(resp.status_code, (403, 400))


if __name__ == "__main__":
    unittest.main()
