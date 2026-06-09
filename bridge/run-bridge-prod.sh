#!/usr/bin/env bash
# Production Utopia Bridge — no --reload, bind localhost for cloudflared tunnel.
set -euo pipefail
BRIDGE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BRIDGE_DIR"
if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created bridge/.env from example — set UTOPIA_BRIDGE_KEY before production." >&2
  exit 1
fi
PYTHON=""
for candidate in /opt/homebrew/bin/python3.14 /opt/homebrew/bin/python3.13 /opt/homebrew/bin/python3.12 /opt/homebrew/bin/python3.11 /opt/homebrew/bin/python3 python3.14 python3; do
  if [[ -x "$candidate" ]] || command -v "$candidate" >/dev/null 2>&1; then
    PYTHON="$candidate"
    break
  fi
done
if [[ -z "$PYTHON" ]]; then
  echo "ERROR: python3 not found" >&2
  exit 1
fi
if [[ ! -d .venv ]] || [[ ! -x .venv/bin/python ]]; then
  "$PYTHON" -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate
pip install -q -r requirements.txt
exec uvicorn main:app --host "${BRIDGE_HOST:-127.0.0.1}" --port "${BRIDGE_PORT:-8011}" --workers 1 --env-file .env
