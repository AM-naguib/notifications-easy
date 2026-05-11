from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(slots=True)
class Settings:
    database_path: Path
    app_token: str = ""
    recent_limit: int = 20
    app_name: str = "EasyOrders API"

    @classmethod
    def from_env(cls, root: Path | None = None) -> "Settings":
        project_root = root or Path(__file__).resolve().parents[2]
        default_db = project_root / "data" / "easyorders.db"
        db_path = Path(os.getenv("EASYORDERS_DB_PATH", str(default_db))).expanduser()

        return cls(
            database_path=db_path.resolve(),
            app_token=os.getenv("EASYORDERS_APP_TOKEN", "").strip(),
        )

