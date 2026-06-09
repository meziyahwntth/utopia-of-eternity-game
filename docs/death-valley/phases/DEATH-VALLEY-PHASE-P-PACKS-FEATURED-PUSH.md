# Death Valley Phase P — Robux Packs, Featured Carousel & Open Cloud Push

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-O-FRIEND-JOIN-BAZAAR.md`

---

## Phase P Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| P1 | **Robux Preset Packs** | Developer Products · grant cosmetic/title + inbox |
| P2 | **Featured Carousel** | MemoryStore featured map · Bazaar UI carousel |
| P3 | **Open Cloud Sender** | Bridge drains queue → Roblox Experience Notifications |

---

## P1 — Preset Packs

- Catalog: `PrismPresetPackCatalog.luau`
- Service: `DeathValleyLoadoutPresetPackService.luau`
- Remotes: `GetPresetPackCatalog`, `PurchasePresetPack`, `PresetPackPurchased`
- `CommerceShopService.ProcessReceipt` delegates to pack service first
- Studio dev grant when `DeveloperProducts[packId] == 0`

Register products before publish:

```lua
local PrismCatalogAssets = require(...)
PrismCatalogAssets.registerProduct("dv_pack_survivor_starter", CREATOR_PRODUCT_ID)
```

---

## P2 — Featured Carousel

- Service: `DeathValleyLoadoutFeaturedService.luau`
- MemoryStore: `UtopiaDV_FeaturedCarousel_v1`
- Auto-feature when listing likes ≥ 10
- Studio admin: `AdminFeatureMarketListing`
- GameConfig: `DeathValley.FeaturedListingIds`
- UI: horizontal **Featured Carousel** + **Robux Preset Packs** in Bazaar tab

Remotes: `GetFeaturedCarousel`

---

## P3 — Open Cloud Bridge

Env (`bridge/.env`):

```env
ROBLOX_OPEN_CLOUD_API_KEY=...
ROBLOX_UNIVERSE_ID=...
ROBLOX_OPEN_CLOUD_NOTIFY_URL=https://apis.roblox.com/cloud/v2/universes/{universe_id}/user/{user_id}/notifications
```

Endpoints:

| Path | Method | Purpose |
|------|--------|---------|
| `/utopia/social-notify/push` | POST | Queue from game (Phase O) |
| `/utopia/social-notify/status` | GET | Queue depth + config check |
| `/utopia/social-notify/process` | POST | Send queued via Open Cloud |

Cron example:

```bash
curl -X POST -H "X-Utopia-Bridge-Key: $KEY" http://127.0.0.1:8011/utopia/social-notify/process
```

---

## Validation

```bash
rg "PresetPack|FeaturedCarousel|PurchasePresetPack|opencloud_notify" utopia-of-eternity-game/
python3 -m json.tool utopia-of-eternity-game/default.project.json > /dev/null
cd utopia-of-eternity-game/bridge && python3 -c "import opencloud_notify; print(opencloud_notify.is_configured())"
```

---

## Studio Test

1. Bazaar tab → Featured carousel cards · Robux pack **Buy** (dev grant)
2. Like listing 10× → auto-feature on carousel
3. Studio `AdminFeatureMarketListing` for manual feature
4. Enable Push → bridge queue → `POST /utopia/social-notify/process`
