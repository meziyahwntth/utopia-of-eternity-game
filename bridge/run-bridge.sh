#!/usr/bin/env bash
# Start Utopia Bridge locally (log analyzer + fan-scan)
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR/bridge"
if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created bridge/.env from example — edit UTOPIA_BRIDGE_KEY before production."
fi
python3 -m venv .venv 2>/dev/null || true
# shellcheck disable=SC1091
source .venv/bin/activate
pip install -q -r requirements.txt
exec uvicorn main:app --host "${BRIDGE_HOST:-127.0.0.1}" --port "${BRIDGE_PORT:-8011}" --reload --env-file .env
