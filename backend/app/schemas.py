from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field, field_validator


class _TrimmedModel(BaseModel):
    @classmethod
    def _strip_or_none(cls, value: str | None) -> str | None:
        if value is None:
            return None
        stripped = value.strip()
        return stripped or None


class OrderCreate(_TrimmedModel):
    customer_name: str = Field(min_length=1, max_length=120)
    amount: str = Field(min_length=1, max_length=40)
    order_number: str | None = Field(default=None, max_length=40)

    @field_validator("customer_name", "amount", mode="before")
    @classmethod
    def validate_required_text(cls, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError("Value cannot be blank.")
        return stripped

    @field_validator("order_number", mode="before")
    @classmethod
    def validate_optional_order_number(cls, value: str | None) -> str | None:
        return cls._strip_or_none(value)


class OrderQueueItem(BaseModel):
    id: str
    order_number: str
    customer_name: str
    amount: str
    status: Literal["pending", "acknowledged"]
    created_at: str
    acknowledged_at: str | None = None


class PendingOrdersResponse(BaseModel):
    items: list[OrderQueueItem]
    count: int


class BulkOrderCreateRequest(BaseModel):
    count: int = Field(default=20, ge=1, le=50)
    start_order_number: int = Field(default=668, ge=1, le=999999)


class BulkOrderCreateResponse(BaseModel):
    items: list[OrderQueueItem]
    count: int


class AcknowledgeRequest(BaseModel):
    ids: list[str] = Field(default_factory=list, max_length=50)


class AcknowledgeResponse(BaseModel):
    acknowledged_ids: list[str]
    count: int


class HealthResponse(BaseModel):
    status: Literal["ok"]
