# Death Valley Phase Q — Commerce District Packs, Creator Revenue & Seasonal Rotation

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-P-PACKS-FEATURED-PUSH.md`

---

## Phase Q Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| Q1 | **Commerce District Preset Bazaar** | Physical kiosk + `CommerceShopUI` for commerce-channel packs |
| Q2 | **Creator Revenue Split** | Soft credits ledger (70% pack share + Bazaar download tips) |
| Q3 | **Seasonal Featured Rotation** | Carousel pack order follows `GameConfig.Seasons` month |

---

## Q1 — Commerce District Shop

- Shop id: `preset_bazaar` · `shopType = "PresetBazaar"`
- Config: `PrismCommerceConfig.luau`
- World: `CommerceDistrictBuilder` → Canal Promenade kiosk
- Catalog: `PrismPresetPackCatalog.listForChannel("commerce")`
- Purchase: `CommerceShopService.processPurchase` → `DeathValleyLoadoutPresetPackService.promptPurchase`
- Packs: `dv_pack_commerce_luxury`, `dv_pack_commerce_creator_spotlight` (`shopChannel = "commerce"`)

Player flow: walk to **Preset Bazaar — Commerce District** → `ShopPrompt` → buy pack like any commerce item.

---

## Q2 — Creator Revenue Split

- Service: `DeathValleyCreatorRevenueService.luau`
- PlayerStore fields: `creatorBalance`, `creatorSalesLedger`
- **Pack sales:** when `pack.creatorUserId > 0`, credit `floor(robux × creatorSharePercent)` (default 70%)
- **Bazaar downloads:** +5 creator credits to listing author on successful `acquireFromMarket`
- Remotes: `GetCreatorRevenueSummary`
- UI: Bazaar tab shows creator credit balance

> Roblox does not allow in-experience Robux payout to arbitrary creators. Ledger tracks soft credits for manual/group settlement.

Set creator on pack catalog:

```lua
creatorUserId = CREATOR_USER_ID,
creatorSharePercent = 70,
```

---

## Q3 — Seasonal Featured Rotation

- Service: `DeathValleyLoadoutFeaturedRotationService.luau`
- Config: `GameConfig.DeathValley.SeasonalFeaturedRotation`
- Season source: `DeathValleySeasonService` (UTC month → `GameConfig.Seasons`)
- Carousel: `DeathValleyLoadoutFeaturedService.getCarouselPayload` returns `rotation` + season-ordered packs
- Remotes: `GetSeasonalFeaturedRotation`, `GetFeaturedCarousel` (includes `rotation`)
- UI: **Season spotlight: {name}** label on Bazaar carousel

Example config:

```lua
SeasonalFeaturedRotation = {
  packIdsBySeasonName = {
    Halloween = { "dv_pack_survivor_starter", "dv_pack_commerce_luxury" },
    Songkran = { "dv_pack_commerce_luxury", "dv_pack_survivor_starter" },
  },
  listingTags = { "community", "seasonal" },
},
```

---

## Pack Catalog Channels

| Field | Values |
|-------|--------|
| `shopChannel` | `"wardrobe"` · `"commerce"` · `"both"` |
| `seasonTag` | Matches `GameConfig.Seasons` name for fallback rotation |
| `creatorUserId` | Roblox user id for revenue ledger |
| `creatorSharePercent` | 70 or 0.70 |

---

## Validation

```bash
rg "PresetBazaar|CreatorRevenue|FeaturedRotation|shopChannel" "/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game/src/"
python3 -m json.tool "/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game/default.project.json" > /dev/null
```

Studio (`GameConfig.StudioDev.SimulatePlaceKey = "EternityCity"`):

1. Canal Promenade → **Preset Bazaar** kiosk → buy commerce pack
2. Bazaar tab → season label + rotated pack order
3. Publish preset → friend acquires → author `creatorBalance` +5

---

## Next (Phase R ideas)

- Group payout export from creator ledger
- UGC-linked creator packs bound to live Bazaar listing author
- Commerce District seasonal pop-up rotation tied to `SeasonalPopUp` shop
