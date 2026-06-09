"""Utopia of Eternity Bridge — log analyzer + Eternity Forge fan-scan API."""
from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field

from creator_payout import CreatorPayoutPush, export_payouts, mark_paid, payout_sync_state, push_payout, queue_status
from opencloud_notify import is_configured, send_experience_notification
from face_capture import (
    EmbeddingResult,
    LivenessFrame,
    LivenessVerify,
    SessionStart,
    finalize_embedding,
    get_embedding,
    start_session,
    submit_liveness_frame,
    verify_liveness,
)

BRIDGE_KEY = os.getenv("UTOPIA_BRIDGE_KEY", "")
DATA_DIR = Path(__file__).resolve().parent / "data"
LOG_FILE = DATA_DIR / "security-events.jsonl"
FAN_FILE = DATA_DIR / "fan-candidates.json"

app = FastAPI(title="Utopia Bridge", version="0.4.0")


def _require_key(header: str | None) -> None:
    if not BRIDGE_KEY:
        return
    if header != BRIDGE_KEY:
        raise HTTPException(status_code=401, detail="Invalid bridge key")


class LogBatch(BaseModel):
    game: str
    version: str | None = None
    events: list[dict[str, Any]] = Field(default_factory=list)


class FanCandidate(BaseModel):
    experienceId: int
    title: str
    description: str | None = None
    creatorId: int | None = None
    visits: int | None = None
    ccu: int | None = None
    hasMonetization: bool | None = None
    policyFlags: list[str] | None = None


class FanScanPayload(BaseModel):
    candidates: list[FanCandidate] = Field(default_factory=list)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "utopia-bridge"}


@app.post("/utopia/log-analyzer")
def log_analyzer(
    batch: LogBatch,
    x_utopia_security: str | None = Header(default=None),
    x_utopia_bridge_key: str | None = Header(default=None),
) -> dict[str, Any]:
    _require_key(x_utopia_bridge_key)
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with LOG_FILE.open("a", encoding="utf-8") as fh:
        for event in batch.events:
            row = {
                "at": datetime.now(timezone.utc).isoformat(),
                "game": batch.game,
                "version": batch.version,
                "security_header": x_utopia_security,
                "event": event,
            }
            fh.write(json.dumps(row, ensure_ascii=False) + "\n")
    return {"ok": True, "received": len(batch.events)}


@app.get("/utopia/fan-scan")
def fan_scan(x_utopia_bridge_key: str | None = Header(default=None)) -> dict[str, Any]:
    _require_key(x_utopia_bridge_key)
    if not FAN_FILE.exists():
        return {"candidates": [], "updatedAt": None}
    payload = json.loads(FAN_FILE.read_text(encoding="utf-8"))
    return payload


@app.put("/utopia/fan-scan")
def fan_scan_upsert(
    body: FanScanPayload,
    x_utopia_bridge_key: str | None = Header(default=None),
) -> dict[str, Any]:
    """Cron / admin pushes candidate list for Roblox servers to poll."""
    _require_key(x_utopia_bridge_key)
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    payload = {
        "candidates": [c.model_dump() for c in body.candidates],
        "updatedAt": datetime.now(timezone.utc).isoformat(),
    }
    FAN_FILE.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    return {"ok": True, "count": len(body.candidates)}


@app.post("/utopia/fan-scan/report")
def fan_report(
    candidate: FanCandidate,
    x_utopia_bridge_key: str | None = Header(default=None),
) -> dict[str, str]:
    _require_key(x_utopia_bridge_key)
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    reports = DATA_DIR / "fan-reports.jsonl"
    with reports.open("a", encoding="utf-8") as fh:
        fh.write(
            json.dumps(
                {"at": datetime.now(timezone.utc).isoformat(), **candidate.model_dump()},
                ensure_ascii=False,
            )
            + "\n"
        )
    return {"ok": "queued"}


# --- Prism Live Mirror (face capture — live only, PDPA) ---


@app.post("/utopia/face-capture/session")
def face_capture_session(
    body: SessionStart,
    x_utopia_bridge_key: str | None = Header(default=None),
) -> dict:
    _require_key(x_utopia_bridge_key)
    return start_session(body)


@app.post("/utopia/face-capture/frame")
def face_capture_frame(
    body: LivenessFrame,
    x_utopia_bridge_key: str | None = Header(default=None),
) -> dict:
    _require_key(x_utopia_bridge_key)
    return submit_liveness_frame(body)


@app.post("/utopia/face-capture/verify")
def face_capture_verify(
    body: LivenessVerify,
    x_utopia_bridge_key: str | None = Header(default=None),
) -> dict:
    _require_key(x_utopia_bridge_key)
    return verify_liveness(body)


@app.post("/utopia/face-capture/embed")
def face_capture_embed(
    body: EmbeddingResult,
    x_utopia_bridge_key: str | None = Header(default=None),
) -> dict:
    _require_key(x_utopia_bridge_key)
    return finalize_embedding(body)


@app.get("/utopia/face-capture/embedding/{user_id}")
def face_capture_get_embedding(
    user_id: int,
    x_utopia_bridge_key: str | None = Header(default=None),
) -> dict:
    _require_key(x_utopia_bridge_key)
    record = get_embedding(user_id)
    if not record:
        raise HTTPException(status_code=404, detail="No embedding")
    return {
        "userId": record["userId"],
        "embeddingId": record["embedding"][:16],
        "morphParams": record["morphParams"],
        "updatedAt": record["updatedAt"],
        "rawPhotoStored": False,
    }


class SocialNotifyPush(BaseModel):
    targetUserId: int
    type: str
    title: str
    body: str
    data: dict[str, Any] | None = None


@app.post("/utopia/social-notify/push")
def social_notify_push(
    payload: SocialNotifyPush,
    x_utopia_bridge_key: str | None = Header(default=None),
) -> dict[str, Any]:
    """Queue hook for Roblox Open Cloud Experience Notifications (wire externally)."""
    _require_key(x_utopia_bridge_key)
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    out_file = DATA_DIR / "social-notify-queue.jsonl"
    row = {
        "at": datetime.now(timezone.utc).isoformat(),
        "targetUserId": payload.targetUserId,
        "type": payload.type,
        "title": payload.title,
        "body": payload.body,
        "data": payload.data,
        "status": "queued",
    }
    with out_file.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(row) + "\n")
    return {"ok": True, "queued": True, "targetUserId": payload.targetUserId}


class SocialNotifyProcessResult(BaseModel):
    processed: int = 0
    sent: int = 0
    failed: int = 0
    skipped: int = 0


@app.get("/utopia/social-notify/status")
def social_notify_status() -> dict[str, Any]:
    out_file = DATA_DIR / "social-notify-queue.jsonl"
    queued = 0
    if out_file.exists():
        with out_file.open("r", encoding="utf-8") as fh:
            for line in fh:
                if not line.strip():
                    continue
                try:
                    row = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if row.get("status") == "queued":
                    queued += 1
    return {
        "openCloudConfigured": is_configured(),
        "queued": queued,
        "queueFile": str(out_file),
    }


@app.post("/utopia/social-notify/process")
def social_notify_process(
    limit: int = 20,
    x_utopia_bridge_key: str | None = Header(default=None),
) -> dict[str, Any]:
    """Drain queued notifications and send via Roblox Open Cloud."""
    _require_key(x_utopia_bridge_key)
    out_file = DATA_DIR / "social-notify-queue.jsonl"
    if not out_file.exists():
        return SocialNotifyProcessResult().model_dump()

    lines: list[str] = []
    with out_file.open("r", encoding="utf-8") as fh:
        lines = fh.readlines()

    result = SocialNotifyProcessResult()
    updated: list[dict[str, Any]] = []

    for line in lines:
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if row.get("status") != "queued":
            updated.append(row)
            continue
        if result.processed >= limit:
            updated.append(row)
            continue

        result.processed += 1
        target_user_id = row.get("targetUserId")
        if not isinstance(target_user_id, int):
            row["status"] = "failed"
            row["error"] = "invalid_target"
            result.failed += 1
            updated.append(row)
            continue

        launch_data = None
        data = row.get("data")
        if isinstance(data, dict):
            code = data.get("shareLink") or data.get("presetCode")
            if isinstance(code, str) and code:
                launch_data = json.dumps({"utopiaPresetCode": code})

        send_result = send_experience_notification(
            target_user_id,
            str(row.get("body") or row.get("title") or "Utopia notification"),
            launch_data,
        )
        if send_result.get("ok"):
            row["status"] = "sent"
            row["sentAt"] = datetime.now(timezone.utc).isoformat()
            result.sent += 1
        elif send_result.get("reason") == "open_cloud_not_configured":
            row["status"] = "queued"
            result.skipped += 1
        else:
            row["status"] = "failed"
            row["error"] = send_result
            result.failed += 1
        updated.append(row)

    with out_file.open("w", encoding="utf-8") as fh:
        for row in updated:
            fh.write(json.dumps(row) + "\n")

    payload = result.model_dump()
    payload["openCloudConfigured"] = is_configured()
    return payload


class CreatorPayoutMarkPaid(BaseModel):
    requestIds: list[str] = Field(default_factory=list)


@app.post("/utopia/creator-payout/push")
def creator_payout_push(
    payload: CreatorPayoutPush,
    x_utopia_bridge_key: str | None = Header(default=None),
) -> dict[str, Any]:
    _require_key(x_utopia_bridge_key)
    return push_payout(payload)


@app.get("/utopia/creator-payout/export")
def creator_payout_export(
    limit: int = 200,
    x_utopia_bridge_key: str | None = Header(default=None),
) -> dict[str, Any]:
    _require_key(x_utopia_bridge_key)
    return export_payouts(limit=limit)


@app.post("/utopia/creator-payout/mark-paid")
def creator_payout_mark_paid(
    body: CreatorPayoutMarkPaid,
    x_utopia_bridge_key: str | None = Header(default=None),
) -> dict[str, Any]:
    _require_key(x_utopia_bridge_key)
    return mark_paid(body.requestIds)


@app.get("/utopia/creator-payout/status")
def creator_payout_status(
    x_utopia_bridge_key: str | None = Header(default=None),
) -> dict[str, Any]:
    _require_key(x_utopia_bridge_key)
    return queue_status()


@app.get("/utopia/creator-payout/sync")
def creator_payout_sync(
    x_utopia_bridge_key: str | None = Header(default=None),
) -> dict[str, Any]:
    """Phase T — Roblox servers poll to mirror exportedAt / paid status into PlayerStore."""
    _require_key(x_utopia_bridge_key)
    return payout_sync_state()
