# Security Pre-Public Checklist — Utopia Shield

**Date:** 9 มิถุนายน 2026 · **Scope:** Luau Security layer + Bridge integration (no Roblox web required)

Review before Configure → Public Save (~10 Jun 2026).

---

## Utopia Shield — implementation map

| Layer | Module(s) | Pre-Public status |
|-------|-----------|---------------------|
| Remote hardening | `RemoteGuard`, `HoneypotRemotes`, `RateLimiter` | ✅ In repo |
| Movement / exploit | `MovementValidator`, `EvasionDetector`, `EmulatorDetector` | ✅ In repo |
| Economy abuse | `EconomyGuard`, `EconomyInflationGuard` | ✅ In repo |
| Griefing / severe offense | `GriefingGuard`, `SevereOffenseGate` | ✅ In repo |
| Ban pipeline | `BanRegistry`, `BanBroadcast`, `SentinelStrike` | ✅ In repo |
| Backdoor scan | `BackdoorScanner` | ✅ In repo |
| Suspicion scoring | `SuspicionTracker` | ✅ In repo |
| Fan-game IP | `FanExperienceGuard`, `FanScanBridge` | ✅ Wired — enable `GameConfig.Bridge.FAN_SCAN_URL` after Public |
| Support / appeals | `SupportDeskService`, `SupportDeskUI` | ✅ Fan report + ban appeal → Bridge |
| Log export | `LogExportBridge` | ✅ Appeals queue |
| Line OA digest | `LineNotifier` | ⏳ Configure bridge env after Public |

Entry point: `src/ServerScriptService/SecurityCore.server.luau`

---

## Bridge endpoints (production)

| Endpoint | Purpose | Verify |
|----------|---------|--------|
| `GET /health` | Liveness | `curl -sS https://api.utopiaofeternity.com/health` |
| `POST /utopia/fan-scan/report` | In-game fan report | Support Desk UI |
| Creator payout flow | Group `791898614` | `bash scripts/test-creator-payout-flow.sh` |
| Payout export cron | Treasurer dry-run | `bash bridge/scripts/payout-export-cron.sh --dry-run` |

---

## Pre-Public actions (local / Bridge only)

- [x] Security modules compile (`rojo build`)
- [x] Bridge health + payout regression pass
- [x] Support Desk exposes Community group ID `791898614`
- [ ] Enable `FAN_SCAN_URL` in bridge bootstrap when fan-scan cron is live
- [ ] Line OA webhook in bridge `.env` (treasurer / admin only — never commit)
- [ ] Studio Play manual smoke: RemoteGuard + Support Desk (after Public Save)

---

## Post-Public actions (requires Roblox Dashboard)

- [ ] License Manager registration — see [ROBLOX-LICENSE-MANAGER-CHECKLIST.md](ROBLOX-LICENSE-MANAGER-CHECKLIST.md)
- [ ] Rights Manager keywords registered
- [ ] Re-run IP audit search on Roblox catalog

---

## Agent policy (9 Jun 2026)

Until user sends **`Public Save แล้ว`**:

- No Roblox website / Creator Dashboard automation
- No Roblox Studio CLI launch
- No `publish-all-places.sh` (Roblox upload API)

Safe: `rojo build`, `validate-p0-publish.py`, bridge curl tests, Luau edits, local docs.
