from __future__ import annotations

import sqlite3
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterator
from uuid import uuid4

from .schemas import OrderQueueItem

SCHEMA = """
CREATE TABLE IF NOT EXISTS orders (
    sequence INTEGER PRIMARY KEY AUTOINCREMENT,
    id TEXT NOT NULL UNIQUE,
    order_number TEXT,
    customer_name TEXT NOT NULL,
    amount TEXT NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('pending', 'acknowledged')),
    created_at TEXT NOT NULL,
    acknowledged_at TEXT
);
"""


def init_db(db_path: Path) -> None:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    with get_connection(db_path) as connection:
        connection.executescript(SCHEMA)
        connection.commit()


@contextmanager
def get_connection(db_path: Path) -> Iterator[sqlite3.Connection]:
    connection = sqlite3.connect(db_path, check_same_thread=False)
    connection.row_factory = sqlite3.Row
    try:
        yield connection
    finally:
        connection.close()


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _row_to_order(row: sqlite3.Row) -> OrderQueueItem:
    return OrderQueueItem(
        id=row["id"],
        order_number=row["order_number"],
        customer_name=row["customer_name"],
        amount=row["amount"],
        status=row["status"],
        created_at=row["created_at"],
        acknowledged_at=row["acknowledged_at"],
    )


def create_order(
    db_path: Path,
    *,
    customer_name: str,
    amount: str,
    order_number: str | None,
) -> OrderQueueItem:
    order_id = str(uuid4())
    created_at = _utc_now()

    with get_connection(db_path) as connection:
        cursor = connection.execute(
            """
            INSERT INTO orders (
                id,
                order_number,
                customer_name,
                amount,
                status,
                created_at
            )
            VALUES (?, ?, ?, ?, 'pending', ?)
            """,
            (order_id, order_number, customer_name, amount, created_at),
        )
        sequence = cursor.lastrowid

        if not order_number:
            order_number = str(sequence)
            connection.execute(
                "UPDATE orders SET order_number = ? WHERE id = ?",
                (order_number, order_id),
            )

        row = connection.execute(
            """
            SELECT id, order_number, customer_name, amount, status, created_at, acknowledged_at
            FROM orders
            WHERE id = ?
            """,
            (order_id,),
        ).fetchone()
        connection.commit()

    if row is None:
        raise RuntimeError("Failed to load created order.")

    return _row_to_order(row)


def list_pending_orders(db_path: Path, *, limit: int) -> list[OrderQueueItem]:
    safe_limit = max(1, min(limit, 50))

    with get_connection(db_path) as connection:
        rows = connection.execute(
            """
            SELECT id, order_number, customer_name, amount, status, created_at, acknowledged_at
            FROM orders
            WHERE status = 'pending'
            ORDER BY sequence ASC
            LIMIT ?
            """,
            (safe_limit,),
        ).fetchall()

    return [_row_to_order(row) for row in rows]


def list_recent_orders(db_path: Path, *, limit: int) -> list[OrderQueueItem]:
    safe_limit = max(1, min(limit, 100))

    with get_connection(db_path) as connection:
        rows = connection.execute(
            """
            SELECT id, order_number, customer_name, amount, status, created_at, acknowledged_at
            FROM orders
            ORDER BY sequence DESC
            LIMIT ?
            """,
            (safe_limit,),
        ).fetchall()

    return [_row_to_order(row) for row in rows]


def acknowledge_orders(db_path: Path, *, ids: list[str]) -> list[str]:
    ordered_ids = list(dict.fromkeys(order_id for order_id in ids if order_id))
    if not ordered_ids:
        return []

    placeholders = ", ".join("?" for _ in ordered_ids)
    now = _utc_now()

    with get_connection(db_path) as connection:
        existing_rows = connection.execute(
            f"""
            SELECT id
            FROM orders
            WHERE status = 'pending' AND id IN ({placeholders})
            ORDER BY sequence ASC
            """,
            ordered_ids,
        ).fetchall()
        existing_ids = [row["id"] for row in existing_rows]

        if existing_ids:
            ack_placeholders = ", ".join("?" for _ in existing_ids)
            connection.execute(
                f"""
                UPDATE orders
                SET status = 'acknowledged',
                    acknowledged_at = ?
                WHERE id IN ({ack_placeholders})
                """,
                [now, *existing_ids],
            )
            connection.commit()

    return existing_ids
