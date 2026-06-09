#!/usr/bin/env bash
# Build a local .rbxlx for Studio Play — no Rojo Connect / no Roblox upload.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-/tmp/utopia-playtest.rbxlx}"

cd "$ROOT"
python3 scripts/validate-p0-publish.py
rojo build default.project.json -o "$OUT"
echo ""
echo "OK — open in Roblox Studio:"
echo "  File → Open from File… → $OUT"
echo "  Then Play (F5). Enable Game Settings → Security → Studio API + HTTP if not done."
