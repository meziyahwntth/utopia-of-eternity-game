"""Creator payout queue — group treasurer export for Death Valley loadout revenue."""
from __future__ import annotations

import csv
import io
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from pydantic import BaseModel, Field

DATA_DIR = Path(__file__).resolve().parent / "data"
QUEUE_FILE = DATA_DIR / "creator-payout-queue.jsonl"
EXPORT_DIR = DATA_DIR / "creator-payout-exports"
PAID_FILE = DATA_DIR / "creator-payout-paid.jsonl"

GROUP_ID = int(os.getenv("ROBLOX_CREATOR_GROUP_ID", "0") or "0")


class CreatorPayoutPush(BaseModel):
    requestId: str
    creatorUserId: int
    amount: int
    groupId: int | None = None
    displayName: str | None = None
    createdAt: int | None = None
    meta: dict[str, Any] | None = None


def _append_jsonl(path: Path, row: dict[str, Any]) -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(row, ensure_ascii=False) + "\n")


def _read_queue() -> list[dict[str, Any]]:
    if not QUEUE_FILE.exists():
        return []
    rows: list[dict[str, Any]] = []
    with QUEUE_FILE.open(encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return rows


def _paid_ids() -> set[str]:
    return set(_paid_details().keys())


def _paid_details() -> dict[str, str]:
    if not PAID_FILE.exists():
        return {}
    out: dict[str, str] = {}
    with PAID_FILE.open(encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
                rid = row.get("requestId")
                if isinstance(rid, str):
                    paid_at = row.get("paidAt")
                    out[rid] = paid_at if isinstance(paid_at, str) else ""
            except json.JSONDecodeError:
                continue
    return out


def _write_queue(rows: list[dict[str, Any]]) -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with QUEUE_FILE.open("w", encoding="utf-8") as fh:
        for row in rows:
            fh.write(json.dumps(row, ensure_ascii=False) + "\n")


def _patch_queue_rows(request_ids: set[str], patch: dict[str, Any]) -> int:
    if not request_ids:
        return 0
    rows = _read_queue()
    updated = 0
    for row in rows:
        rid = row.get("requestId")
        if isinstance(rid, str) and rid in request_ids:
            row.update(patch)
            updated += 1
    if updated > 0:
        _write_queue(rows)
    return updated


def push_payout(payload: CreatorPayoutPush) -> dict[str, Any]:
    row = payload.model_dump()
    row["status"] = "pending"
    row["queuedAt"] = datetime.now(timezone.utc).isoformat()
    if row.get("groupId") in (None, 0):
        row["groupId"] = GROUP_ID or None
    _append_jsonl(QUEUE_FILE, row)
    return {"ok": True, "requestId": payload.requestId, "queued": payload.amount}


def export_payouts(limit: int = 200) -> dict[str, Any]:
    paid = _paid_ids()
    pending: list[dict[str, Any]] = []
    for row in _read_queue():
        rid = row.get("requestId")
        if isinstance(rid, str) and rid in paid:
            continue
        if row.get("status") == "paid":
            continue
        pending.append(row)
        if len(pending) >= limit:
            break

    total_credits = sum(int(r.get("amount") or 0) for r in pending)
    by_creator: dict[int, int] = {}
    for row in pending:
        uid = int(row.get("creatorUserId") or 0)
        if uid <= 0:
            continue
        by_creator[uid] = by_creator.get(uid, 0) + int(row.get("amount") or 0)

    csv_buf = io.StringIO()
    writer = csv.writer(csv_buf)
    writer.writerow(
        [
            "requestId",
            "creatorUserId",
            "displayName",
            "amount",
            "groupId",
            "createdAt",
            "queuedAt",
        ]
    )
    for row in pending:
        writer.writerow(
            [
                row.get("requestId"),
                row.get("creatorUserId"),
                row.get("displayName") or "",
                row.get("amount"),
                row.get("groupId") or GROUP_ID or "",
                row.get("createdAt") or "",
                row.get("queuedAt") or "",
            ]
        )

    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    export_path = EXPORT_DIR / f"payout-export-{stamp}.json"
    export_payload = {
        "exportedAt": datetime.now(timezone.utc).isoformat(),
        "groupId": GROUP_ID or None,
        "totalRequests": len(pending),
        "totalCredits": total_credits,
        "byCreator": {str(k): v for k, v in by_creator.items()},
        "requests": pending,
        "csv": csv_buf.getvalue(),
    }
    export_path.write_text(json.dumps(export_payload, ensure_ascii=False, indent=2), encoding="utf-8")

    exported_at = export_payload["exportedAt"]
    exported_ids = {
        rid
        for row in pending
        if isinstance((rid := row.get("requestId")), str)
    }
    _patch_queue_rows(
        exported_ids,
        {
            "status": "exported",
            "exportedAt": exported_at,
        },
    )

    return {
        "ok": True,
        "exportFile": str(export_path.name),
        "exportedAt": exported_at,
        "requestIds": sorted(exported_ids),
        "totalRequests": len(pending),
        "totalCredits": total_credits,
        "byCreator": export_payload["byCreator"],
        "csv": csv_buf.getvalue(),
    }


def mark_paid(request_ids: list[str]) -> dict[str, Any]:
    paid = _paid_ids()
    marked = 0
    paid_at = datetime.now(timezone.utc).isoformat()
    marked_ids: set[str] = set()
    for rid in request_ids:
        if not isinstance(rid, str) or rid in paid:
            continue
        _append_jsonl(
            PAID_FILE,
            {
                "requestId": rid,
                "paidAt": paid_at,
            },
        )
        marked_ids.add(rid)
        marked += 1
    if marked_ids:
        _patch_queue_rows(
            marked_ids,
            {
                "status": "paid",
                "paidAt": paid_at,
            },
        )
    return {"ok": True, "marked": marked}


def payout_sync_state() -> dict[str, Any]:
    """Return payout status rows for Roblox servers to mirror into PlayerStore."""
    paid_map = _paid_details()
    updates: list[dict[str, Any]] = []
    for row in _read_queue():
        rid = row.get("requestId")
        if not isinstance(rid, str):
            continue
        creator_id = row.get("creatorUserId")
        if not isinstance(creator_id, int):
            continue
        status = row.get("status") or "pending"
        if rid in paid_map:
            status = "paid"
        exported_at = row.get("exportedAt")
        paid_at = row.get("paidAt") or paid_map.get(rid)
        updates.append(
            {
                "requestId": rid,
                "creatorUserId": creator_id,
                "status": status,
                "exportedAt": exported_at if isinstance(exported_at, str) else None,
                "paidAt": paid_at if isinstance(paid_at, str) else None,
            }
        )
    return {"ok": True, "updates": updates}


def queue_status() -> dict[str, Any]:
    paid = _paid_ids()
    pending_count = 0
    pending_credits = 0
    for row in _read_queue():
        rid = row.get("requestId")
        if isinstance(rid, str) and rid in paid:
            continue
        if row.get("status") == "paid":
            continue
        pending_count += 1
        pending_credits += int(row.get("amount") or 0)

    last_export_at: str | None = None
    last_export_file: str | None = None
    if EXPORT_DIR.exists():
        exports = sorted(EXPORT_DIR.glob("payout-export-*.json"), key=lambda p: p.stat().st_mtime, reverse=True)
        if exports:
            last_export_file = exports[0].name
            try:
                payload = json.loads(exports[0].read_text(encoding="utf-8"))
                last_export_at = payload.get("exportedAt")
            except (json.JSONDecodeError, OSError):
                last_export_at = None

    return {
        "ok": True,
        "groupId": GROUP_ID or None,
        "pendingRequests": pending_count,
        "pendingCredits": pending_credits,
        "queueFile": str(QUEUE_FILE.name),
        "lastExportAt": last_export_at,
        "lastExportFile": last_export_file,
    }
