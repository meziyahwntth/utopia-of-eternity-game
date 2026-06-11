#!/usr/bin/env bash
# Publish a single place via Rojo build + Roblox Open Cloud place publishing API.
# rojo upload --api_key can return success without creating a version when scopes
# are incomplete; this script POSTs the built rbxlx and requires versionNumber.
# Requires: ROBLOX_OPEN_CLOUD_API_KEY in bridge/.env (universe-places:write)
# Usage: bash scripts/publish-place.sh EternityCity
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLACE_KEY="${1:-}"
UNIVERSE_ID="10293115628"
PLACES=(
  "Hub:119887759427070"
  "Solhaven:115650957014564"
  "Nocturne:93828090134581"
  "EternityCity:94486544638073"
  "DeathValley:91092008076019"
)

if [[ -z "$PLACE_KEY" ]]; then
  echo "Usage: bash scripts/publish-place.sh <Hub|Solhaven|Nocturne|EternityCity|DeathValley>" >&2
  exit 1
fi

PLACE_ID=""
for entry in "${PLACES[@]}"; do
  name="${entry%%:*}"
  id="${entry##*:}"
  if [[ "$name" == "$PLACE_KEY" ]]; then
    PLACE_ID="$id"
    break
  fi
done

if [[ -z "$PLACE_ID" ]]; then
  echo "Unknown place: $PLACE_KEY" >&2
  echo "Usage: bash scripts/publish-place.sh <Hub|Solhaven|Nocturne|EternityCity|DeathValley>" >&2
  exit 1
fi

if ! command -v rojo >/dev/null; then
  echo "ERROR: install rojo (brew install rojo)" >&2
  exit 1
fi

BRIDGE_ENV="${ROOT}/bridge/.env"
if [[ -f "$BRIDGE_ENV" ]]; then
  set -a  # auto-export: python subprocess needs the key in its environment
  # shellcheck disable=SC1090
  source "$BRIDGE_ENV"
  set +a
fi
if [[ -z "${ROBLOX_OPEN_CLOUD_API_KEY:-}" ]]; then
  echo "ERROR: ROBLOX_OPEN_CLOUD_API_KEY not set — check bridge/.env" >&2
  exit 1
fi

cd "$ROOT"
python3 scripts/validate-p0-publish.py

RBXLX="$(mktemp /tmp/utopia-publish-XXXXXX).rbxlx"  # macOS mktemp ไม่รองรับ suffix หลัง XXXXXX
trap 'rm -f "$RBXLX" "${RBXLX%.rbxlx}"' EXIT

echo "=== Building $PLACE_KEY for publish ==="
rojo build -o "$RBXLX"

echo "=== Publishing $PLACE_KEY ($PLACE_ID) in universe $UNIVERSE_ID ==="
RESP="$(python3 - "$UNIVERSE_ID" "$PLACE_ID" "$RBXLX" <<'PY'
import json
import os
import sys
import urllib.error
import urllib.request

universe_id, place_id, rbxlx_path = sys.argv[1:4]
api_key = os.environ.get("ROBLOX_OPEN_CLOUD_API_KEY", "").strip()
if not api_key:
    print("ERROR: ROBLOX_OPEN_CLOUD_API_KEY missing", file=sys.stderr)
    raise SystemExit(1)

with open(rbxlx_path, "rb") as handle:
    body = handle.read()

url = (
    f"https://apis.roblox.com/universes/v1/{universe_id}/places/{place_id}/versions"
    "?versionType=Published"
)
req = urllib.request.Request(
    url,
    data=body,
    headers={
        "x-api-key": api_key,
        "Content-Type": "application/xml",
    },
    method="POST",
)
try:
    with urllib.request.urlopen(req, timeout=300) as resp:
        status = resp.status
        raw = resp.read().decode("utf-8")
except urllib.error.HTTPError as exc:
    detail = exc.read().decode("utf-8", errors="replace")
    print(f"HTTP {exc.code} {detail[:500]}", file=sys.stderr)
    raise SystemExit(1) from exc

try:
    payload = json.loads(raw) if raw else {}
except json.JSONDecodeError:
    payload = {}

version = payload.get("versionNumber")
print(f"HTTP {status}")
print(f"placeId={place_id}")
print(f"versionNumber={version}")
if not version:
    print(f"response={raw[:500]}", file=sys.stderr)
    raise SystemExit(1)
PY
)"
echo "$RESP"
echo "Done — $PLACE_KEY published."
