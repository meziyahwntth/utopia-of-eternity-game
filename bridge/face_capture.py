"""Prism Live Mirror — liveness + face embedding (PDPA: live capture only, no gallery)."""
from __future__ import annotations

import hashlib
import json
import secrets
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from pydantic import BaseModel, Field

DATA_DIR = Path(__file__).resolve().parent / "data" / "face_capture"
SESSION_TTL_SECONDS = 300
MAX_ATTEMPTS_PER_DAY = 3

LIVENESS_CHALLENGES = ("blink", "turn_left", "turn_right", "smile")


class SessionStart(BaseModel):
    userId: int
    robloxUsername: str | None = None
    keyCount: int = 0
    consentAccepted: bool = False


class LivenessFrame(BaseModel):
    sessionToken: str
    challenge: str
    frameHash: str  # client sends SHA256 of frame — never raw image in logs
    timestampMs: int


class LivenessVerify(BaseModel):
    sessionToken: str
    completedChallenges: list[str] = Field(default_factory=list)


class EmbeddingResult(BaseModel):
    sessionToken: str
    morphParams: dict[str, float] = Field(default_factory=dict)


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _session_path(token: str) -> Path:
    return DATA_DIR / "sessions" / f"{token}.json"


def _embedding_path(user_id: int) -> Path:
    return DATA_DIR / "embeddings" / f"{user_id}.json"


def _load_session(token: str) -> dict[str, Any] | None:
    path = _session_path(token)
    if not path.exists():
        return None
    data = json.loads(path.read_text(encoding="utf-8"))
    if time.time() - data.get("createdAt", 0) > SESSION_TTL_SECONDS:
        path.unlink(missing_ok=True)
        return None
    return data


def _save_session(token: str, payload: dict[str, Any]) -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    (DATA_DIR / "sessions").mkdir(parents=True, exist_ok=True)
    _session_path(token).write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def start_session(body: SessionStart) -> dict[str, Any]:
    if not body.consentAccepted:
        return {"ok": False, "error": "consent_required"}
    if body.keyCount < 25:
        return {"ok": False, "error": "key_25_required"}

    token = secrets.token_urlsafe(32)
    challenges = list(LIVENESS_CHALLENGES)
    payload = {
        "token": token,
        "userId": body.userId,
        "username": body.robloxUsername,
        "createdAt": time.time(),
        "challenges": challenges,
        "completed": [],
        "frames": [],
        "status": "active",
    }
    _save_session(token, payload)
    return {
        "ok": True,
        "sessionToken": token,
        "ttlSeconds": SESSION_TTL_SECONDS,
        "challenges": challenges,
        "captureMode": "live_only",
        "galleryUploadAllowed": False,
    }


def submit_liveness_frame(body: LivenessFrame) -> dict[str, Any]:
    session = _load_session(body.sessionToken)
    if not session:
        return {"ok": False, "error": "session_expired"}
    if body.challenge not in session["challenges"]:
        return {"ok": False, "error": "invalid_challenge"}

    session["frames"].append({
        "challenge": body.challenge,
        "frameHash": body.frameHash,
        "at": _now_iso(),
    })
    _save_session(body.sessionToken, session)
    return {"ok": True, "received": body.challenge}


def verify_liveness(body: LivenessVerify) -> dict[str, Any]:
    session = _load_session(body.sessionToken)
    if not session:
        return {"ok": False, "error": "session_expired"}

    required = set(session["challenges"])
    completed = set(body.completedChallenges)
    if not required.issubset(completed):
        missing = list(required - completed)
        return {"ok": False, "error": "challenges_incomplete", "missing": missing}

    if len(session.get("frames", [])) < len(required):
        return {"ok": False, "error": "insufficient_frames"}

    session["completed"] = list(completed)
    session["status"] = "liveness_passed"
    _save_session(body.sessionToken, session)
    return {"ok": True, "liveness": "passed"}


def _derive_embedding(user_id: int, frame_hashes: list[str]) -> str:
    """Deterministic embedding stub — replace with local AI model in production."""
    material = f"{user_id}:" + ":".join(sorted(frame_hashes))
    return hashlib.sha256(material.encode()).hexdigest()


def _default_morph_params() -> dict[str, float]:
    return {
        "jaw_width": 0.5,
        "cheek_fullness": 0.5,
        "nose_width": 0.5,
        "nose_height": 0.5,
        "mouth_width": 0.5,
        "lip_fullness": 0.5,
        "eye_size": 0.5,
        "eyebrow_height": 0.5,
        "ear_size": 0.5,
        "skin_tone": 0.5,
    }


def finalize_embedding(body: EmbeddingResult) -> dict[str, Any]:
    session = _load_session(body.sessionToken)
    if not session:
        return {"ok": False, "error": "session_expired"}
    if session.get("status") != "liveness_passed":
        return {"ok": False, "error": "liveness_not_passed"}

    user_id = session["userId"]
    frame_hashes = [f["frameHash"] for f in session.get("frames", [])]
    embedding = _derive_embedding(user_id, frame_hashes)

    morph = _default_morph_params()
    morph.update(body.morphParams)

    (DATA_DIR / "embeddings").mkdir(parents=True, exist_ok=True)
    record = {
        "userId": user_id,
        "embedding": embedding,
        "morphParams": morph,
        "updatedAt": _now_iso(),
        "sessionToken": body.sessionToken,
        "rawPhotoStored": False,
    }
    _embedding_path(user_id).write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding="utf-8")

    session["status"] = "completed"
    _save_session(body.sessionToken, session)

    return {
        "ok": True,
        "embeddingId": embedding[:16],
        "morphParams": morph,
        "rawPhotoReturned": False,
    }


def get_embedding(user_id: int) -> dict[str, Any] | None:
    path = _embedding_path(user_id)
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))
