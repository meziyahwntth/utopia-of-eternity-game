#!/usr/bin/env bash
# Phase S — weekly group treasurer payout export (Death Valley creator credits)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$BRIDGE_DIR/.env"
DRY_RUN=0
LIMIT=200

usage() {
  cat <<'EOF'
Usage: payout-export-cron.sh [--dry-run] [--limit N]

Exports pending creator payout requests from Utopia Bridge to CSV/JSON.
Requires bridge/.env with UTOPIA_BRIDGE_KEY (and optional PAYOUT_NOTIFY_WEBHOOK_URL).

Examples:
  bash bridge/scripts/payout-export-cron.sh
  bash bridge/scripts/payout-export-cron.sh --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --limit)
      LIMIT="${2:-200}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE — copy from bridge/.env.example" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

HOST="${BRIDGE_HOST:-127.0.0.1}"
PORT="${BRIDGE_PORT:-8011}"
BASE_URL="${BRIDGE_BASE_URL:-http://${HOST}:${PORT}}"
KEY="${UTOPIA_BRIDGE_KEY:-}"
WEBHOOK="${PAYOUT_NOTIFY_WEBHOOK_URL:-}"
EXPORT_DIR="$BRIDGE_DIR/data/creator-payout-exports"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"

AUTH_HEADER=()
if [[ -n "$KEY" ]]; then
  AUTH_HEADER=(-H "X-Utopia-Bridge-Key: $KEY")
fi

echo "[payout-cron] Checking queue status at $BASE_URL ..."
STATUS_JSON="$(curl -fsS "${AUTH_HEADER[@]}" "$BASE_URL/utopia/creator-payout/status")"
PENDING="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("pendingRequests",0))' <<<"$STATUS_JSON")"
PENDING_CREDITS="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("pendingCredits",0))' <<<"$STATUS_JSON")"

echo "[payout-cron] Pending: $PENDING requests ($PENDING_CREDITS credits)"

if [[ "$PENDING" -eq 0 ]]; then
  echo "[payout-cron] Nothing to export."
  exit 0
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[payout-cron] Dry run — would export up to $LIMIT pending requests."
  exit 0
fi

mkdir -p "$EXPORT_DIR"
RESPONSE_FILE="$EXPORT_DIR/payout-export-response-$STAMP.json"
CSV_FILE="$EXPORT_DIR/payout-batch-$STAMP.csv"

echo "[payout-cron] Exporting ..."
curl -fsS "${AUTH_HEADER[@]}" "$BASE_URL/utopia/creator-payout/export?limit=$LIMIT" -o "$RESPONSE_FILE"

python3 <<PY
import json
from pathlib import Path
path = Path("$RESPONSE_FILE")
payload = json.loads(path.read_text(encoding="utf-8"))
csv = payload.get("csv") or ""
Path("$CSV_FILE").write_text(csv, encoding="utf-8")
print(f"[payout-cron] Saved CSV: $CSV_FILE")
print(f"[payout-cron] Export file: {payload.get('exportFile', '?')}")
print(f"[payout-cron] Total requests: {payload.get('totalRequests', 0)}")
print(f"[payout-cron] Total credits: {payload.get('totalCredits', 0)}")
PY

if [[ -n "$WEBHOOK" ]]; then
  SUMMARY="Utopia payout export: $PENDING requests, $PENDING_CREDITS credits. CSV: $(basename "$CSV_FILE")"
  curl -fsS -X POST "$WEBHOOK" \
    -H "Content-Type: application/json" \
    -d "{\"text\": $(python3 -c "import json; print(json.dumps('$SUMMARY'))")}" \
    >/dev/null 2>&1 || echo "[payout-cron] Webhook notify failed (non-fatal)" >&2
  echo "[payout-cron] Webhook notified."
fi

echo "[payout-cron] Done. Treasurer: pay via Roblox Group, then POST /utopia/creator-payout/mark-paid"
