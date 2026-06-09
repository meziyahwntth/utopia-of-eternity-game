#!/usr/bin/env bash
# Publish a single place via Rojo (Chrome .ROBLOSECURITY cookie).
# Usage: bash scripts/publish-place.sh EternityCity
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENV="${ROOT}/.publish-venv"
PLACE_KEY="${1:-}"
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

if [[ ! -d "$VENV" ]]; then
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install -q browser-cookie3
fi

COOKIE="$("$VENV/bin/python3" - <<'PY'
import browser_cookie3
jar = browser_cookie3.chrome(domain_name="roblox.com")
for c in jar:
    if c.name == ".ROBLOSECURITY":
        print(c.value)
        break
PY
)"

if [[ -z "${COOKIE:-}" ]]; then
  echo "ERROR: .ROBLOSECURITY not found in Chrome — log in at roblox.com" >&2
  exit 1
fi

cd "$ROOT"
python3 scripts/validate-p0-publish.py
echo "=== Publishing $PLACE_KEY ($PLACE_ID) ==="
rojo upload --asset_id "$PLACE_ID" --cookie "$COOKIE"
echo "Done — $PLACE_KEY published."
