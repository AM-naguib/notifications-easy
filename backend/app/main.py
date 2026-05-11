from __future__ import annotations

from pathlib import Path
from typing import Annotated
from urllib.parse import urlencode

from fastapi import FastAPI, Form, Header, Query, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from .auth import admin_token_is_valid, require_token
from .schemas import (
    AcknowledgeRequest,
    AcknowledgeResponse,
    HealthResponse,
    OrderCreate,
    OrderQueueItem,
    PendingOrdersResponse,
)
from .settings import Settings
from .storage import (
    acknowledge_orders,
    create_order,
    init_db,
    list_pending_orders,
    list_recent_orders,
)

APP_ROOT = Path(__file__).resolve().parent
TEMPLATES = Jinja2Templates(directory=str(APP_ROOT / "templates"))


def create_app(settings: Settings | None = None) -> FastAPI:
    resolved_settings = settings or Settings.from_env()
    init_db(resolved_settings.database_path)

    app = FastAPI(title=resolved_settings.app_name)
    app.state.settings = resolved_settings
    app.mount("/static", StaticFiles(directory=str(APP_ROOT / "static")), name="static")

    @app.get("/", include_in_schema=False)
    async def root() -> RedirectResponse:
        return RedirectResponse(url="/admin", status_code=302)

    @app.get("/v1/health", response_model=HealthResponse)
    async def healthcheck() -> HealthResponse:
        return HealthResponse(status="ok")

    @app.post("/v1/orders", response_model=OrderQueueItem, status_code=201)
    async def create_order_endpoint(
        payload: OrderCreate,
        request: Request,
        x_app_token: Annotated[str | None, Header(alias="X-App-Token")] = None,
    ) -> OrderQueueItem:
        require_token(request, x_app_token)
        return create_order(
            request.app.state.settings.database_path,
            customer_name=payload.customer_name,
            amount=payload.amount,
            order_number=payload.order_number,
        )

    @app.get("/v1/orders/pending", response_model=PendingOrdersResponse)
    async def pending_orders_endpoint(
        request: Request,
        limit: Annotated[int, Query(ge=1, le=50)] = 5,
        x_app_token: Annotated[str | None, Header(alias="X-App-Token")] = None,
    ) -> PendingOrdersResponse:
        require_token(request, x_app_token)
        items = list_pending_orders(request.app.state.settings.database_path, limit=limit)
        return PendingOrdersResponse(items=items, count=len(items))

    @app.post("/v1/orders/ack", response_model=AcknowledgeResponse)
    async def acknowledge_orders_endpoint(
        payload: AcknowledgeRequest,
        request: Request,
        x_app_token: Annotated[str | None, Header(alias="X-App-Token")] = None,
    ) -> AcknowledgeResponse:
        require_token(request, x_app_token)
        acknowledged_ids = acknowledge_orders(
            request.app.state.settings.database_path,
            ids=payload.ids,
        )
        return AcknowledgeResponse(
            acknowledged_ids=acknowledged_ids,
            count=len(acknowledged_ids),
        )

    @app.get("/admin", response_class=HTMLResponse)
    async def admin_page(
        request: Request,
        token: str | None = None,
        created: int | None = None,
    ) -> HTMLResponse:
        is_valid, provided_token = admin_token_is_valid(request, token)
        token_enabled = bool(request.app.state.settings.app_token)

        context = {
            "request": request,
            "app_name": "EasyOrders Control Room",
            "token": provided_token,
            "token_enabled": token_enabled,
            "locked": token_enabled and not is_valid,
            "flash": "Order added successfully." if created else None,
            "api_hint": "/v1/orders, /v1/orders/pending, /v1/orders/ack",
            "pending_orders": [],
            "recent_orders": [],
        }

        if not context["locked"]:
            context["pending_orders"] = list_pending_orders(
                request.app.state.settings.database_path,
                limit=50,
            )
            context["recent_orders"] = list_recent_orders(
                request.app.state.settings.database_path,
                limit=request.app.state.settings.recent_limit,
            )

        return TEMPLATES.TemplateResponse(request, "admin.html", context)

    @app.post("/admin/orders", response_class=RedirectResponse)
    async def admin_create_order(
        request: Request,
        customer_name: Annotated[str, Form(...)],
        amount: Annotated[str, Form(...)],
        order_number: Annotated[str | None, Form()] = None,
        token: Annotated[str | None, Form()] = None,
    ) -> RedirectResponse:
        require_token(request, token)

        payload = OrderCreate(
            customer_name=customer_name,
            amount=amount,
            order_number=order_number,
        )
        create_order(
            request.app.state.settings.database_path,
            customer_name=payload.customer_name,
            amount=payload.amount,
            order_number=payload.order_number,
        )

        query_params = {"created": 1}
        if request.app.state.settings.app_token:
            query_params["token"] = token or ""

        return RedirectResponse(
            url=f"/admin?{urlencode(query_params)}",
            status_code=303,
        )

    return app


app = create_app()
