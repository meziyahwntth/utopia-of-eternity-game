#!/usr/bin/env bash
# Install Utopia Bridge as macOS launchd service (24/7 on Mac).
# Syncs bridge to ~/Meziyah/utopia-bridge — launchd cannot execute scripts on Desktop (TCC).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="${ROOT}/bridge"
DEST="${HOME}/Meziyah/utopia-bridge"
PLIST_SRC="${SRC}/launchd/com.utopiaofeternity.bridge.plist"
PLIST_DST="${HOME}/Library/LaunchAgents/com.utopiaofeternity.bridge.plist"
WRAPPER_DIR="${HOME}/Library/Application Support/UtopiaOfEternity"
WRAPPER="${WRAPPER_DIR}/run-bridge.sh"

mkdir -p "${DEST}"
rsync -a --delete \
  --exclude '.venv' \
  --exclude '__pycache__' \
  --exclude '*.pyc' \
  "${SRC}/" "${DEST}/"

rm -rf "${DEST}/.venv"

if [[ -f "${SRC}/.env" ]]; then
  cp "${SRC}/.env" "${DEST}/.env"
fi

chmod +x "${DEST}/run-bridge-prod.sh"
mkdir -p "${WRAPPER_DIR}"
cat > "${WRAPPER}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec /bin/bash "${DEST}/run-bridge-prod.sh"
EOF
chmod +x "${WRAPPER}"

mkdir -p "${HOME}/Library/LaunchAgents"
cp "${PLIST_SRC}" "${PLIST_DST}"

launchctl bootout "gui/$(id -u)/com.utopiaofeternity.bridge" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "${PLIST_DST}"
launchctl enable "gui/$(id -u)/com.utopiaofeternity.bridge"
launchctl kickstart -k "gui/$(id -u)/com.utopiaofeternity.bridge"

for _ in 1 2 3 4 5; do
  sleep 3
  if curl -sf "http://127.0.0.1:8011/health" >/dev/null; then
    echo "OK: Utopia Bridge listening on :8011 (deployed at ${DEST})"
    exit 0
  fi
done

echo "FAIL: Bridge not healthy — check /tmp/utopia-bridge.err" >&2
tail -8 /tmp/utopia-bridge.err 2>/dev/null || true
exit 1
