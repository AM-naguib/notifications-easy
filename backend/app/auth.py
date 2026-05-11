from __future__ import annotations

from fastapi import HTTPException, Request, status

TOKEN_HEADER = "X-App-Token"


def require_token(request: Request, supplied_token: str | None = None) -> str:
    expected = request.app.state.settings.app_token.strip()
    if not expected:
        return ""

    candidate = (supplied_token or request.headers.get(TOKEN_HEADER) or "").strip()
    if candidate != expected:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing app token.",
        )

    return candidate


def admin_token_is_valid(request: Request, supplied_token: str | None = None) -> tuple[bool, str]:
    expected = request.app.state.settings.app_token.strip()
    if not expected:
        return True, ""

    candidate = (supplied_token or "").strip()
    return candidate == expected, candidate

