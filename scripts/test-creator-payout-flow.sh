#!/usr/bin/env bash
# End-to-end creator payout bridge test (push → export → mark-paid → sync).
# Does not require Roblox Studio; simulates game push + treasurer workflow.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/bridge/.env"
DEPLOY_ENV="${HOME}/Meziyah/utopia-bridge/.env"

if [[ -f "$DEPLOY_ENV" ]]; then
  ENV_FILE="$DEPLOY_ENV"
elif [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing bridge/.env" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

HOST="${BRIDGE_HOST:-127.0.0.1}"
PORT="${BRIDGE_PORT:-8011}"
BASE_URL="${PUBLIC_BASE_URL:-http://${HOST}:${PORT}}"
KEY="${UTOPIA_BRIDGE_KEY:-}"
GROUP_ID="${ROBLOX_CREATOR_GROUP_ID:-0}"
TEST_ID="utopia-payout-test-$(date -u +%Y%m%dT%H%M%SZ)"
CREATOR_USER_ID=11076697270
AMOUNT=150

AUTH=()
if [[ -n "$KEY" ]]; then
  AUTH=(-H "X-Utopia-Bridge-Key: $KEY")
fi

echo "=== Creator Payout Flow Test ==="
echo "Bridge: $BASE_URL"
echo "Group ID: $GROUP_ID"
echo "Request ID: $TEST_ID"

curl -fsS "${AUTH[@]}" "$BASE_URL/health" >/dev/null
echo "OK health"

PUSH_BODY=$(python3 - <<PY
import json
print(json.dumps({
  "requestId": "$TEST_ID",
  "creatorUserId": $CREATOR_USER_ID,
  "amount": $AMOUNT,
  "displayName": "PorscheUTP",
  "groupId": int("$GROUP_ID") or None,
  "meta": {"source": "scripts/test-creator-payout-flow.sh"},
}))
PY
)

curl -fsS -X POST "${AUTH[@]}" -H "Content-Type: application/json" \
  -d "$PUSH_BODY" \
  "$BASE_URL/utopia/creator-payout/push" >/dev/null
echo "OK push"

STATUS_JSON="$(curl -fsS "${AUTH[@]}" "$BASE_URL/utopia/creator-payout/status")"
PENDING="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("pendingRequests",0))' <<<"$STATUS_JSON")"
echo "Pending requests: $PENDING"

EXPORT_JSON="$(curl -fsS "${AUTH[@]}" "$BASE_URL/utopia/creator-payout/export?limit=50")"
EXPORT_COUNT="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("totalRequests",0))' <<<"$EXPORT_JSON")"
echo "OK export (batch size: $EXPORT_COUNT)"

MARK_BODY=$(python3 - <<PY
import json
print(json.dumps({"requestIds": ["$TEST_ID"]}))
PY
)
curl -fsS -X POST "${AUTH[@]}" -H "Content-Type: application/json" \
  -d "$MARK_BODY" \
  "$BASE_URL/utopia/creator-payout/mark-paid" >/dev/null
echo "OK mark-paid"

SYNC_JSON="$(curl -fsS "${AUTH[@]}" "$BASE_URL/utopia/creator-payout/sync")"
PAID="$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(any(r.get("requestId")=="'"$TEST_ID"'" and r.get("status")=="paid" for r in d.get("updates",[])))' <<<"$SYNC_JSON")"
if [[ "$PAID" != "True" ]]; then
  echo "FAIL sync — test request not marked paid in sync payload" >&2
  exit 1
fi
echo "OK sync (request paid)"

echo "=== Creator payout flow test PASSED ==="
