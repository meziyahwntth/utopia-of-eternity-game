# Death Valley Phase R — Group Payout Export, UGC Packs & Seasonal Pop-Up

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-Q-COMMERCE-CREATOR-ROTATION.md`

---

## Phase R Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| R1 | **Group payout export** | Creator requests payout → Bridge queue → treasurer CSV export |
| R2 | **UGC-linked creator packs** | Bazaar listing → dynamic Robux pack · 70% to author |
| R3 | **Seasonal pop-up shop** | `seasonal_pop_up` kiosk + rotated preset + UGC packs |

---

## R1 — Group Payout Export

### Game
- Service: `DeathValleyCreatorRevenueService` (`requestPayout`, `tryBridgePayoutPush`)
- PlayerStore: `creatorPayoutRequests`
- Config: `GameConfig.DeathValley.CreatorPayout` (`minCredits`, `groupId`)
- Remote: `RequestCreatorPayout`
- UI: **Request Group Payout** in Bazaar tab (min 100 credits default)

### Bridge
Env (`bridge/.env`):

```env
ROBLOX_CREATOR_GROUP_ID=12345678
UTOPIA_BRIDGE_KEY=...
```

Endpoints:

| Path | Method | Purpose |
|------|--------|---------|
| `/utopia/creator-payout/push` | POST | Game queues payout request |
| `/utopia/creator-payout/export` | GET | Treasurer CSV + JSON batch |
| `/utopia/creator-payout/mark-paid` | POST | Mark requestIds paid |
| `/utopia/creator-payout/status` | GET | Queue depth |

Treasurer cron:

```bash
curl -H "X-Utopia-Bridge-Key: $KEY" "http://127.0.0.1:8011/utopia/creator-payout/export" \
  | jq -r '.csv' > payout-batch.csv
```

Secrets (`BridgeSecrets.luau`):

```lua
CREATOR_PAYOUT_PUSH_URL = "http://127.0.0.1:8011/utopia/creator-payout/push",
```

---

## R2 — UGC-Linked Creator Packs

- Service: `DeathValleyUgcCreatorPackService.luau`
- MemoryStore: `UtopiaDV_UgcCreatorPacks_v1` + index sorted map
- Pack id prefix: `dv_ugc_{listingIdCompact}`
- Remote: `CreateUgcCreatorPack(listingId, robux?)` · `GetMyUgcCreatorPacks`
- Purchase: `DeathValleyLoadoutPresetPackService.resolvePack` + redeem listing share code
- Revenue: `recordPackSale(authorUserId, …)` on grant
- Generic dev product key: `dv_pack_ugc_generic` (single receipt handler via `pendingByUser`)
- UI: **Sell as Pack** on **My Published Listings** (Bazaar tab)

Flow:
1. Publish preset to Bazaar
2. Click **Sell as Pack** (R$49–499)
3. Pack appears in Seasonal Pop-Up + carousel `ugcPacks`
4. Buyers get preset via share-code redeem · author earns ledger credits

---

## R3 — Seasonal Pop-Up Shop

- Service: `DeathValleySeasonalPopUpShopService.luau`
- Shop: `seasonal_pop_up` on SkyRail Plaza (existing kiosk)
- Catalog: fashion seasonal sets + rotated preset packs + season UGC packs
- `CommerceShopService` SeasonalPopUp branch + `seasonPopUpLabel` in catalog response
- Kiosk sign shows current season name (`CommerceDistrictBuilder`)
- Remote: `GetSeasonalPopUpShop`
- `CommerceShopUI` shows season label when opening pop-up

---

## Validation

```bash
rg "RequestCreatorPayout|UgcCreatorPack|SeasonalPopUp|creator-payout" \
  "/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game/"
python3 -m json.tool "/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game/default.project.json" > /dev/null
cd "/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game/bridge" && python3 -c "import creator_payout; print('ok')"
```

Studio (`SimulatePlaceKey = "EternityCity"`):

1. Bazaar → earn credits → **Request Group Payout**
2. Publish listing → **Sell as Pack** → buy from Seasonal Pop-Up kiosk
3. SkyRail **Seasonal Pop-Up · {Season}** shows rotated packs

---

## Production checklist

- Set `GameConfig.DeathValley.CreatorPayout.groupId`
- Register `dv_pack_ugc_generic` Developer Product in `PrismCatalogAssets`
- Bridge cron: `/utopia/creator-payout/export` weekly
- Manual Roblox Group payout from CSV (Roblox has no in-game creator Robux split)
