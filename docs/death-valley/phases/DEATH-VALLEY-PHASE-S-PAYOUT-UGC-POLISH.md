# Death Valley Phase S — Payout Automation, UGC Price Picker & Seasonal Polish

**Version:** 1.0 · **Date:** 9 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-R-PAYOUT-UGC-SEASONAL.md`

---

## Phase S Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| S1 | **UGC price picker UI** | Modal tier selector R$49–499 ใน Bazaar tab |
| S2 | **Payout history UI** | แสดงประวัติ + disable Request เมื่อ pending |
| S3 | **Group payout cron** | `bridge/scripts/payout-export-cron.sh` + status metadata |
| S4 | **Seasonal pop-up polish** | Filter fashion ตาม season · UI theme · kiosk decorations |

---

## S1 — UGC Price Picker UI

### Config
- `GameConfig.DeathValley.UgcCreatorPack` — `minRobux`, `maxRobux`, `priceTiers`, `maxLinkedPerPlayer`
- Service: `DeathValleyUgcCreatorPackService` อ่าน config แทน hardcoded constants

### Game
- Remote: `CreateUgcCreatorPack(listingId, robux)` (unchanged)
- `GetCreatorRevenueSummary` ขยาย: `ugcPriceTiers`, `ugcMinRobux`, `ugcMaxRobux`
- UI: `DeathValleyUnifiedLoadoutUI.client.luau` — modal overlay เมื่อกด **Sell as Pack**
  - Tier buttons จาก server config
  - Preview: `70% creator share ≈ N credits per sale`
  - Confirm → invoke remote with selected price

---

## S2 — Payout History UI

- Data: `GetCreatorRevenueSummary.payoutHistory` (PlayerStore `creatorPayoutRequests`, max 20)
- UI ใน Bazaar tab:
  - `Minimum payout: N credits`
  - **Request Group Payout** disabled เมื่อมี `status == "pending"`
  - **Payout History** rows: `{status} · {amount} credits · {date}`

---

## S3 — Group Payout Cron Automation

### Bridge
- Script: `bridge/scripts/payout-export-cron.sh`
  - Reads `bridge/.env` (`UTOPIA_BRIDGE_KEY`, optional `PAYOUT_NOTIFY_WEBHOOK_URL`)
  - `GET /utopia/creator-payout/status` → skip if pending = 0
  - `GET /utopia/creator-payout/export` → save CSV to `bridge/data/creator-payout-exports/`
- `creator_payout.queue_status()` returns `lastExportAt`, `lastExportFile`

### Treasurer flow
1. Cron runs weekly (launchd/cron — see `bridge/README.md`)
2. Pay creators manually via Roblox Group from CSV
3. `POST /utopia/creator-payout/mark-paid` with `requestIds`

---

## S4 — Seasonal Pop-Up Visual Polish

### Config
- `GameConfig.SeasonThemes` — per-season `accent`, `signColor`, `badge` (6 seasons)

### Server
- `CommerceShopService` — `SeasonalPopUp` branch:
  - Fashion: `PrismFashionCatalog.getSetsForSeason(currentSeason)` only
  - Preset/UGC packs: `source` field (`fashion` | `season_rotation` | `ugc_creator`)
  - Response: `seasonTheme` serialized for client

### Client
- `CommerceShopUI.client.luau`:
  - Accent theming (stroke, title, badge, buy button)
  - Section headers: Season Fashion / Featured Packs / Creator UGC
  - Row badges: Featured, Creator Pack

### World
- `CommerceDistrictBuilder` — SeasonalPopUp kiosk:
  - Sign + peace disc colors from `SeasonThemes`
  - `SeasonBanner` neon strip + light `ParticleEmitter`

---

## Validation

```bash
cd "/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game"

python3 -m json.tool default.project.json > /dev/null

rg "UgcCreatorPack|SeasonThemes|payout-export-cron|priceTiers|payoutHistory|seasonTheme" src/ bridge/

cd bridge && python3 -c "import creator_payout; print('ok')"
bash scripts/payout-export-cron.sh --dry-run
```

### Studio (`SimulatePlaceKey = "EternityCity"`)

1. Loadout → Bazaar → **Sell as Pack** → pick tier → confirm
2. **Request Group Payout** → history shows pending → button disabled
3. SkyRail **Seasonal Pop-Up** → themed UI + current-season fashion only
4. Bridge cron dry-run succeeds

---

## Production checklist

- Set `ROBLOX_CREATOR_GROUP_ID` in `bridge/.env`
- Schedule `payout-export-cron.sh` weekly on Mac 24/7 host
- Optional: `PAYOUT_NOTIFY_WEBHOOK_URL` for treasurer alerts
