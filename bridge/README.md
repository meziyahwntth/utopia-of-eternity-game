# Utopia Bridge

FastAPI sidecar for Roblox **Utopia Shield** + **Eternity Forge**.

| Endpoint | Method | Consumer |
|----------|--------|----------|
| `/utopia/log-analyzer` | POST | `LogExportBridge.luau` |
| `/utopia/fan-scan` | GET | `FanScanBridge.luau` (poll) |
| `/utopia/fan-scan` | PUT | Cron / admin pushes candidates |
| `/utopia/fan-scan/report` | POST | Support Desk reports |
| `/utopia/face-capture/session` | POST | Prism Live Mirror (key 25, live only) |
| `/utopia/face-capture/frame` | POST | Liveness frame hash |
| `/utopia/face-capture/verify` | POST | Complete liveness |
| `/utopia/face-capture/embed` | POST | Store embedding + morph params |
| `/utopia/face-capture/embedding/{user_id}` | GET | Retrieve embedding metadata |
| `/utopia/social-notify/push` | POST | Phase O — queue out-of-game notify hook (Open Cloud wire-up) |
| `/utopia/social-notify/status` | GET | Phase P — queue depth + Open Cloud config |
| `/utopia/social-notify/process` | POST | Phase P — send queued notifications via Open Cloud |
| `/utopia/creator-payout/push` | POST | Phase R — game queues creator payout request |
| `/utopia/creator-payout/export` | GET | Phase R/S — treasurer CSV + JSON batch export |
| `/utopia/creator-payout/mark-paid` | POST | Phase R — mark requestIds paid after Group payout |
| `/utopia/creator-payout/status` | GET | Phase R/S — queue depth + last export metadata |
| `/utopia/creator-payout/sync` | GET | Phase T — exportedAt / paid sync for PlayerStore |

## Setup

```bash
cd bridge
cp .env.example .env
# edit UTOPIA_BRIDGE_KEY
bash run-bridge.sh
```

Health: `curl http://127.0.0.1:8011/health`

## Creator payout cron (Phase S)

Group treasurer workflow — Roblox has no in-game Robux split API; export CSV and pay manually via Group.

```bash
# Ensure bridge is running (bash bridge/run-bridge.sh)
bash bridge/scripts/payout-export-cron.sh          # export if pending > 0
bash bridge/scripts/payout-export-cron.sh --dry-run # check only
```

Exports land in `bridge/data/creator-payout-exports/` (`payout-batch-*.csv`).

After paying creators in Roblox Group:

```bash
curl -X POST -H "X-Utopia-Bridge-Key: $UTOPIA_BRIDGE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"requestIds":["guid-1","guid-2"]}' \
  http://127.0.0.1:8011/utopia/creator-payout/mark-paid
```

### Weekly cron (macOS launchd example)

```xml
<!-- ~/Library/LaunchAgents/com.utopiaofeternity.payout-export.plist -->
<plist version="1.0">
<dict>
  <key>Label</key><string>com.utopiaofeternity.payout-export</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>/path/to/utopia-of-eternity-game/bridge/scripts/payout-export-cron.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key><integer>1</integer>
    <key>Hour</key><integer>9</integer>
    <key>Minute</key><integer>0</integer>
  </dict>
</dict>
</plist>
```

Optional: set `PAYOUT_NOTIFY_WEBHOOK_URL` in `bridge/.env` for Slack/Discord treasurer alerts.

## Production (Mac 24/7)

macOS blocks launchd from running scripts on **Desktop** — deploy syncs to `~/Meziyah/utopia-bridge`:

```bash
bash bridge/scripts/install-launchd-bridge.sh   # launchd com.utopiaofeternity.bridge
```

Cloudflare tunnel ingress (`~/.cloudflared/config.yml`):

```yaml
  - hostname: api.utopiaofeternity.com
    service: http://localhost:8011
```

Add DNS in the **utopiaofeternity.com** Cloudflare zone (same account as tunnel):

```bash
cloudflared tunnel route dns meziyah api.utopiaofeternity.com
launchctl kickstart -k gui/$(id -u)/com.meziyah.cloudflared
curl https://api.utopiaofeternity.com/health
```

Local health: `curl http://127.0.0.1:8011/health`

## Production URLs (match `BridgeSecrets.luau`)

| Secret | Example |
|--------|---------|
| `LOG_ANALYZER_URL` | `https://api.utopiaofeternity.com/utopia/log-analyzer` |
| `FAN_SCAN_URL` | `https://api.utopiaofeternity.com/utopia/fan-scan` |
| `BRIDGE_KEY` | shared with Bridge `X-Utopia-Bridge-Key` header |

Store in **Clawdi Vault** (never commit):

```bash
clawdi vault set utopia/BRIDGE_FAN_SCAN_URL "https://api.utopiaofeternity.com/utopia/fan-scan"
clawdi vault set utopia/BRIDGE_LOG_ANALYZER_URL "https://api.utopiaofeternity.com/utopia/log-analyzer"
clawdi vault set utopia/BRIDGE_KEY "<random>"
```

Copy `src/ServerScriptService/Secrets/BridgeSecrets.example.luau` → `BridgeSecrets.luau` and paste URLs.

## Roblox

1. Enable **HttpService** in Game Settings
2. `BridgeBootstrap.server.luau` loads secrets before security flush
3. `FanScanBridge` polls every 10 minutes when `FAN_SCAN_URL` is set
