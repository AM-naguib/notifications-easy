from __future__ import annotations

from pathlib import Path

from fastapi.testclient import TestClient

from app.main import create_app
from app.settings import Settings


def make_client(tmp_path: Path, token: str = "") -> TestClient:
    settings = Settings(database_path=tmp_path / "test.db", app_token=token)
    return TestClient(create_app(settings))


def test_order_lifecycle_and_acknowledgement(tmp_path: Path) -> None:
    with make_client(tmp_path) as client:
        first = client.post(
            "/v1/orders",
            json={"customer_name": "Sherif Atef", "amount": "650"},
        )
        second = client.post(
            "/v1/orders",
            json={"customer_name": "Ibrahim Mohamed", "amount": "1329", "order_number": "680"},
        )

        assert first.status_code == 201
        assert second.status_code == 201
        assert first.json()["order_number"] == "1"
        assert second.json()["order_number"] == "680"

        pending = client.get("/v1/orders/pending", params={"limit": 5})
        assert pending.status_code == 200
        pending_items = pending.json()["items"]
        assert [item["customer_name"] for item in pending_items] == [
            "Sherif Atef",
            "Ibrahim Mohamed",
        ]

        ack = client.post(
            "/v1/orders/ack",
            json={"ids": [pending_items[0]["id"]]},
        )
        assert ack.status_code == 200
        assert ack.json()["count"] == 1

        remaining = client.get("/v1/orders/pending", params={"limit": 5})
        assert remaining.status_code == 200
        assert [item["customer_name"] for item in remaining.json()["items"]] == [
            "Ibrahim Mohamed"
        ]


def test_pending_limit_is_respected(tmp_path: Path) -> None:
    with make_client(tmp_path) as client:
        for index in range(3):
            response = client.post(
                "/v1/orders",
                json={"customer_name": f"Customer {index}", "amount": str(index + 1)},
            )
            assert response.status_code == 201

        pending = client.get("/v1/orders/pending", params={"limit": 2})
        assert pending.status_code == 200
        assert pending.json()["count"] == 2


def test_token_protection_on_json_api(tmp_path: Path) -> None:
    with make_client(tmp_path, token="secret-token") as client:
        denied = client.get("/v1/orders/pending", params={"limit": 1})
        assert denied.status_code == 401

        allowed = client.get(
            "/v1/orders/pending",
            params={"limit": 1},
            headers={"X-App-Token": "secret-token"},
        )
        assert allowed.status_code == 200


def test_admin_unlock_flow(tmp_path: Path) -> None:
    with make_client(tmp_path, token="secret-token") as client:
        locked = client.get("/admin")
        assert locked.status_code == 200
        assert "Admin Token Required" in locked.text

        unlocked = client.get("/admin", params={"token": "secret-token"})
        assert unlocked.status_code == 200
        assert "Create Queue Item" in unlocked.text

