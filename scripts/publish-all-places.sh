#!/usr/bin/env bash
# Publish all 5 MVP places via Rojo (legacy cookie auth from Chrome).
# Requires: rojo, Chrome logged into Roblox as experience owner.
# Usage: bash scripts/publish-all-places.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENV="${ROOT}/.publish-venv"
PLACES=(
  "Hub:119887759427070"
  "Solhaven:115650957014564"
  "Nocturne:93828090134581"
  "EternityCity:94486544638073"
  "DeathValley:91092008076019"
)

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

python3 "$ROOT/scripts/validate-p0-publish.py" || true

cd "$ROOT"
for entry in "${PLACES[@]}"; do
  name="${entry%%:*}"
  id="${entry##*:}"
  echo "=== Publishing $name ($id) ==="
  rojo upload --asset_id "$id" --cookie "$COOKIE"
done

echo "Done — all places published."
