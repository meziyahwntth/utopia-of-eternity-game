# Death Valley Phase T — Bridge Payout Sync & Production Bridge

**Version:** 1.0 · **Date:** 9 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-S-PAYOUT-UGC-POLISH.md` · **P0 publish complete**

---

## Phase T Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| T1 | **Export status in Bridge queue** | `export_payouts` marks rows `exported` + `exportedAt` |
| T2 | **Sync endpoint** | `GET /utopia/creator-payout/sync` → mirror into PlayerStore |
| T3 | **Game polling** | `DeathValleyCreatorPayoutSyncBridge` every 300s |
| T4 | **UI status** | Payout history shows `exported` / `paid` + dates |
| T5 | **Production bridge URLs** | `BridgeSecrets` + `bridge/.env` production template |

---

## T1 — Bridge queue export markers

When treasurer runs export:

- Each pending row → `status: "exported"`, `exportedAt` ISO timestamp
- Export API response includes `exportedAt`, `requestIds[]`

When treasurer runs `mark-paid`:

- Rows → `status: "paid"`, `paidAt` ISO timestamp

---

## T2 — Sync endpoint

```
GET /utopia/creator-payout/sync
Header: X-Utopia-Bridge-Key: ...
```

Response:

```json
{
  "ok": true,
  "updates": [
    {
      "requestId": "guid",
      "creatorUserId": 12345,
      "status": "exported",
      "exportedAt": "2026-06-09T04:00:00+00:00",
      "paidAt": null
    }
  ]
}
```

---

## T3 — Game polling

- Module: `DeathValleyCreatorPayoutSyncBridge.luau`
- Started from `DeathValleyLoadoutHandlers.server.luau`
- Config: `GameConfig.Bridge.CREATOR_PAYOUT_SYNC_URL` (auto-derived from push URL if omitted)
- Poll interval: `CREATOR_PAYOUT_SYNC_POLL_SECONDS` (default 300)
- PlayerStore: `patchCreatorPayoutRequest(userId, requestId, patch)`

Requires **HttpService enabled** in published experience.

---

## T4 — UI

Bazaar tab payout history:

| Status | Color | Button |
|--------|-------|--------|
| `pending` | amber | Request disabled |
| `exported` | blue | Request disabled |
| `paid` | green | Request enabled |

Date column uses `exportedAt` / `paidAt` when available.

---

## T5 — Production Bridge

### Local (Mac 24/7)

```bash
cd bridge && cp .env.example .env
# Set UTOPIA_BRIDGE_KEY, ROBLOX_CREATOR_GROUP_ID (when group exists)
bash run-bridge.sh
```

### Roblox secrets (`BridgeSecrets.luau`)

```lua
CREATOR_PAYOUT_PUSH_URL = "https://api.utopiaofeternity.com/utopia/creator-payout/push",
CREATOR_PAYOUT_SYNC_URL = "https://api.utopiaofeternity.com/utopia/creator-payout/sync",
```

### Weekly cron

```bash
bash bridge/scripts/payout-export-cron.sh
```

---

## Validation

```bash
cd "/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game"
python3 -m json.tool default.project.json > /dev/null
rojo build -o /tmp/utopia-phase-t.rbxlx
python3 scripts/validate-p0-publish.py
cd bridge && python3 -c "from creator_payout import payout_sync_state, export_payouts; print('ok')"
curl -s http://127.0.0.1:8011/health  # when bridge running
```

---

## P0 Publish — Complete (9 Jun 2026)

| Asset | Status |
|-------|--------|
| Universe `10293115628` Utopia of Eternity | Live |
| 5 Places published via Rojo | Done |
| 7 Developer Products | Done |
| Maturity questionnaire (Moderate) | Done |
| `validate-p0-publish.py` | OK |

Republish after code changes:

```bash
bash scripts/publish-all-places.sh
```
