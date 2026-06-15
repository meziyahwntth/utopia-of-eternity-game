#!/bin/zsh
# ─────────────────────────────────────────────────────────────────────────────
# knowledge-ingest — wrapper สำหรับ MemPalace ingest (เทียบเท่า MCP knowledge_ingest)
# ใช้:  ./knowledge-ingest.sh <file-or-dir>            # โหมด CLI (default)
#       ./knowledge-ingest.sh <file-or-dir> --http     # โหมด HTTP (server :8005, ไม่โหลด embedding ใน shell)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

MP="/Users/macbook/blue-topaz-ai/venv-mempalace/bin/mempalace-code"
TARGET_PATH="${1:?usage: knowledge-ingest <file-or-dir> [--http]}"
MODE="${2:-cli}"

# absolute path
if [[ -d "$TARGET_PATH" ]]; then
  ABS="$(cd "$TARGET_PATH" && pwd)"
else
  ABS="$(cd "$(dirname "$TARGET_PATH")" && pwd)/$(basename "$TARGET_PATH")"
fi

if [[ "$MODE" == "--http" ]]; then
  echo "==> MemPalace ingest (HTTP :8005): $ABS"
  curl -s -X POST http://127.0.0.1:8005/api/ingest \
    -H "Content-Type: application/json" \
    -d "{\"path\":\"$ABS\",\"description\":\"ingest via knowledge-ingest.sh\"}"
  echo
  exit 0
fi

# CLI mode — `mine` ต้องรับ "โฟลเดอร์ wing ที่มี mempalace.yaml" (ไม่ใช่ไฟล์เดี่ยว)
# → ไต่ขึ้น parent หา mempalace.yaml ที่ใกล้ที่สุด แล้ว mine ทั้ง wing นั้น (incremental)
DIR="$ABS"; [[ -d "$DIR" ]] || DIR="$(dirname "$ABS")"
WING="$DIR"
while [[ "$WING" != "/" && ! -f "$WING/mempalace.yaml" ]]; do
  WING="$(dirname "$WING")"
done
if [[ ! -f "$WING/mempalace.yaml" ]]; then
  echo "==> ไม่พบ mempalace.yaml ใน parent → init ที่ $DIR"
  "$MP" init "$DIR" --yes
  WING="$DIR"
fi
echo "==> MemPalace ingest (CLI) — wing dir: $WING  (รวมไฟล์ใหม่: $ABS)"
exec "$MP" mine "$WING"
