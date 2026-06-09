# P0 — Place IDs & Developer Products (Pre-Publish)

**Priority:** P0 · **Status:** ✅ Complete (9 Jun 2026) — live on Roblox universe `10293115628`

Before live Robux purchases or cross-place teleport, configure gitignored secret files on this machine.

---

## Quick start

```bash
cd "/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game"
bash scripts/init-secrets.sh          # creates missing secret files from examples
# Edit PlaceSecrets.luau + CatalogSecrets.luau with real IDs
python3 scripts/validate-p0-publish.py
```

---

## Step 1 — Create Roblox Universe & 5 Places

In [Roblox Creator Dashboard](https://create.roblox.com/dashboard/creations):

| GameConfig key | Place name (suggested) | Role |
|----------------|------------------------|------|
| `Hub` | Utopia Plaza Hub | Spawn, museum, teleport kiosks |
| `Solhaven` | Solhaven | Day garden, Luminlings |
| `Nocturne` | Nocturne Alley | Twilight mystery |
| `EternityCity` | Utopia of Eternity | Flagship city, commerce |
| `DeathValley` | หุบเขามรณะ | Hellbound co-op horror |

For each place, copy **Place ID** from the URL:

```
https://create.roblox.com/dashboard/creations/experiences/{UNIVERSE_ID}/places/{PLACE_ID}/overview
```

Also copy **Universe ID** from the experience overview page.

---

## Step 2 — Fill `PlaceSecrets.luau`

Path: `src/ServerScriptService/Secrets/PlaceSecrets.luau` (gitignored)

```lua
return {
    UniverseId = 1234567890,      -- experience universe ID
    CreatorGroupId = 9876543,     -- optional: Roblox group for creator payouts

    Hub = 1111111111,
    Solhaven = 2222222222,
    Nocturne = 3333333333,
    EternityCity = 4444444444,
    DeathValley = 5555555555,
}
```

Loaded by `BridgeBootstrap` → `GameConfig.Places[].id` at server start.

**Studio note:** When `PlaceId == 0`, world builders use `GameConfig.StudioDev.SimulatePlaceKey` — Place IDs are required for published cross-place teleport only.

---

## Step 3 — Register Developer Products

In Creator Dashboard → your experience → **Monetization** → **Developer Products** → Create.

### P0 required (Death Valley preset packs)

| Catalog key | Suggested name | Robux (match catalog) |
|-------------|----------------|------------------------|
| `dv_pack_survivor_starter` | Survivor Starter Pack | 99 |
| `dv_pack_hellbound_elite` | Hellbound Elite Pack | 149 |
| `dv_pack_veteran_trail` | Night Veteran Pack | 79 |
| `dv_pack_style_only` | Style Preset Pack | 49 |
| `dv_pack_commerce_luxury` | Luxury Galleria Loadout | 199 |
| `dv_pack_commerce_creator_spotlight` | Creator Spotlight Pack | 129 |
| `dv_pack_ugc_generic` | UGC Creator Loadout Pack | 49–499 (generic receipt) |

Robux prices are defined in `PrismPresetPackCatalog.luau`. Dashboard product price **must match** the catalog `robux` field for each static pack.

`dv_pack_ugc_generic` is one product used for all dynamic UGC creator packs (Phase R) — set price to the maximum tier (499) or use Roblox's closest allowed price; server validates 49–499 at purchase time.

### Optional (Hellbound travel)

| Key | Robux |
|-----|-------|
| `hellbound_private_jet` | 499 |

---

## Step 4 — Fill `CatalogSecrets.luau`

Path: `src/ServerScriptService/Secrets/CatalogSecrets.luau` (gitignored)

```lua
return {
    dv_pack_survivor_starter = 1000000001,
    dv_pack_hellbound_elite = 1000000002,
    -- ... paste numeric Developer Product IDs from Dashboard
    dv_pack_ugc_generic = 1000000007,
}
```

Loaded by `CatalogBootstrap` → `PrismCatalogAssets.registerProduct()`.

When ID is `0`, Studio grants purchases for free (`CommerceShopService` dev mode).

---

## Step 5 — Bridge `.env` (optional but recommended)

```env
ROBLOX_UNIVERSE_ID=<same as PlaceSecrets.UniverseId>
ROBLOX_CREATOR_GROUP_ID=<same as PlaceSecrets.CreatorGroupId>
```

Also set `GameConfig.DeathValley.CreatorPayout.groupId` automatically when `PlaceSecrets.CreatorGroupId > 0`.

---

## Step 6 — Link Experience to Community

**Community:** `791898614` — https://www.roblox.com/communities/791898614/Utopia-of-Eternity

**Status (9 Jun 2026):** ✅ Complete

| Step | Status |
|------|--------|
| Ownership transfer → Group `791898614` | ✅ Done |
| Community visibility (experiences on home page) | ✅ Done |
| Configure Private + Studio/Mesh APIs | ✅ Saved |
| Bridge payout test | ✅ `bash scripts/test-creator-payout-flow.sh` PASSED |
| **Public / Limited audience Save** | ⏳ Blocked until ~10 Jun 2026 (new-creator waiting period) |

1. ~~Creator Dashboard → Initiate ownership transfer → accept as group owner~~ **Done**
2. ~~Community Settings → Community experiences visible on home page~~ **Done**
3. Run bridge payout test: `bash scripts/test-creator-payout-flow.sh` (regression OK anytime)

**After ~10 Jun 2026 (manual on Creator Dashboard):**

1. Configure → Audience → **Public** (or Limited + Community Members) → **Save Changes**
2. Message agent: **`Public Save แล้ว`** → agent runs API verify + optional republish

**In-game (Studio — manual after ~10 Jun):** `GameConfig.StudioDev.SeedCreatorTestCredits = true` seeds ≥150 credits in Studio only. Death Valley / Eternity City → Loadout → Bazaar → **Request Group Payout**.

**Treasurer:** `bash bridge/scripts/payout-export-cron.sh` → pay via Group → `POST /utopia/creator-payout/mark-paid`.

---

## Validation

```bash
python3 scripts/validate-p0-publish.py
python3 -m json.tool default.project.json > /dev/null
```

Expected when complete: `OK — all P0 Place IDs and Developer Products configured.`

---

## Studio smoke test (after IDs filled)

1. Publish all 5 places to the same universe
2. Enable **HttpService** + **Studio Access to API Services**
3. Hub → teleport kiosk → each city
4. Eternity City → Bazaar → buy preset pack (real Robux in live, free if product ID still 0 in Studio)
5. `bash bridge/scripts/payout-export-cron.sh --dry-run` with bridge running

---

## Files reference

| File | Purpose |
|------|---------|
| `PlaceSecrets.example.luau` | Template (committed) |
| `PlaceSecrets.luau` | Real place IDs (gitignored) |
| `CatalogSecrets.example.luau` | Template (committed) |
| `CatalogSecrets.luau` | Developer Product IDs (gitignored) |
| `PublishRequirements.luau` | P0 key lists for validation |
| `CatalogBootstrap.luau` | Registers products at boot |
| `scripts/validate-p0-publish.py` | Pre-publish checker |

**Never commit** `PlaceSecrets.luau`, `CatalogSecrets.luau`, or `BridgeSecrets.luau`.
