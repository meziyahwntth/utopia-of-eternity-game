#!/usr/bin/env bash
# Add api.utopiaofeternity.com CNAME → Cloudflare Tunnel (requires CF_API_TOKEN).
# Create token: Cloudflare Dashboard → Profile → API Tokens → Edit zone DNS (utopiaofeternity.com)
set -euo pipefail
ZONE_NAME="${ZONE_NAME:-utopiaofeternity.com}"
RECORD_NAME="${RECORD_NAME:-api}"
TUNNEL_TARGET="${TUNNEL_TARGET:-830d397a-cd2e-4f55-84bc-6505f374681e.cfargotunnel.com}"

if [[ -z "${CF_API_TOKEN:-}" ]]; then
  echo "Set CF_API_TOKEN (Zone.DNS Edit for ${ZONE_NAME}) then re-run." >&2
  echo "Manual: DNS → Add CNAME ${RECORD_NAME} → ${TUNNEL_TARGET} (Proxied)" >&2
  exit 1
fi

ZONE_ID="$(curl -sf -H "Authorization: Bearer ${CF_API_TOKEN}" \
  "https://api.cloudflare.com/client/v4/zones?name=${ZONE_NAME}" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result'][0]['id'])")"

curl -sf -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "$(python3 - <<PY
import json
print(json.dumps({
  "type": "CNAME",
  "name": "${RECORD_NAME}",
  "content": "${TUNNEL_TARGET}",
  "proxied": True,
  "ttl": 1,
}))
PY
)" | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK' if d.get('success') else d); sys.exit(0 if d.get('success') else 1)"

echo "Waiting for DNS..."
for _ in 1 2 3 4 5 6; do
  sleep 5
  if curl -sf --max-time 10 "https://api.${ZONE_NAME}/health" >/dev/null 2>&1; then
    echo "OK: https://api.${ZONE_NAME}/health"
    exit 0
  fi
done
echo "WARN: CNAME created but health not reachable yet — check tunnel + launchd" >&2
