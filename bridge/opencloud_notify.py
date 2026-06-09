"""Roblox Open Cloud Experience Notification sender (Phase P)."""
from __future__ import annotations

import json
import os
import urllib.error
import urllib.request
from typing import Any

OPEN_CLOUD_API_KEY = os.getenv("ROBLOX_OPEN_CLOUD_API_KEY", "")
UNIVERSE_ID = os.getenv("ROBLOX_UNIVERSE_ID", "")
NOTIFY_URL_TEMPLATE = os.getenv(
    "ROBLOX_OPEN_CLOUD_NOTIFY_URL",
    "https://apis.roblox.com/cloud/v2/universes/{universe_id}/user/{user_id}/notifications",
)


def is_configured() -> bool:
    return bool(OPEN_CLOUD_API_KEY and UNIVERSE_ID)


def send_experience_notification(
    user_id: int,
    message: str,
    launch_data: str | None = None,
) -> dict[str, Any]:
    if not is_configured():
        return {"ok": False, "reason": "open_cloud_not_configured"}

    url = NOTIFY_URL_TEMPLATE.format(universe_id=UNIVERSE_ID, user_id=user_id)
    payload: dict[str, Any] = {"message": message}
    if launch_data:
        payload["launchData"] = launch_data

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "x-api-key": OPEN_CLOUD_API_KEY,
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            body = resp.read().decode("utf-8")
            return {"ok": True, "status": resp.status, "body": body[:500]}
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        return {"ok": False, "status": exc.code, "error": detail[:500]}
    except urllib.error.URLError as exc:
        return {"ok": False, "error": str(exc)}
