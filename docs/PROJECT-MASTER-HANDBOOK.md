# PROJECT MASTER HANDBOOK — Utopia of Eternity

**Version:** 1.0 · **Recorded:** 9 มิถุนายน 2026  
**Project root:** `/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game/`  
**Parent folder:** `/Users/macbook/Desktop/Utopia of Eternity/`  
**Platform:** Roblox (Rojo 7.x) · **Engine:** Luau strict · **Bridge:** FastAPI Python  

> เอกสารนี้บันทึกประวัติโปรเจกต์ตั้งแต่ขั้นร่าง → เตรียมการ → ออกแบบ → ดำเนินการทุก Phase จนถึง **Death Valley Phase S** (9 มิ.ย. 2026)  
> ใช้เป็น **single source of truth** เมื่อเปิด Cursor session ใหม่

---

## สารบัญ

1. [ภาพรวมโปรเจกต์](#1-ภาพรวมโปรเจกต์)
2. [ขั้นร่างและที่มา](#2-ขั้นร่างและที่มา)
3. [ขั้นเตรียมการ (Phase 0.x)](#3-ขั้นเตรียมการ-phase-0x)
4. [การออกแบบหลัก](#4-การออกแบบหลัก)
5. [World Build & Commerce](#5-world-build--commerce)
6. [Death Valley — Phase A ถึง R](#6-death-valley--phase-a-ถึง-r)
7. [สถาปัตยกรรม Loadout Stack (Phase K→R)](#7-สถาปัตยกรรม-loadout-stack-phase-kr)
8. [Bridge & Open Cloud](#8-bridge--open-cloud)
9. [โครงสร้างโฟลเดอร์ (หลังจัดระเบียบ)](#9-โครงสร้างโฟลเดอร์-หลังจัดระเบียบ)
10. [Config & Secrets](#10-config--secrets)
11. [Remotes สำคัญ (Death Valley)](#11-remotes-สำคัญ-death-valley)
12. [Validation & Studio Test](#12-validation--studio-test)
13. [งานถัดไป (Backlog)](#13-งานถัดไป-backlog)
14. [อ้างอิงภายนอก](#14-อ้างอิงภายนอก)

---

## 1. ภาพรวมโปรเจกต์

**Utopia of Eternity** คือ Roblox open-world universe แบบ IP-safe 100% — 5 MVP Places:

| Place | Key | โหมดเวลา | บทบาท |
|-------|-----|----------|--------|
| Utopia Plaza Hub | `Hub` | กลางวันถาวร | Spawn, Museum, Teleport |
| Solhaven | `Solhaven` | กลางวันถาวร | สวน, treasure, trade |
| Nocturne Alley | `Nocturne` | Twilight | ปริศนา, cipher — ไม่ใช่ horror |
| Utopia of Eternity | `EternityCity` | กลางวันถาวร | Solarpunk flagship, commerce, fashion |
| หุบเขามรณะ | `DeathValley` | Eternal night | Opt-in horror co-op บนดาว Hellbound |

**One-liner:** Hang out กลางวัน · ล่าปริศนาข้ามเมือง · horror กลางคืนเมื่อพร้อม

**Official web:** https://utopiaofeternity.com

---

## 2. ขั้นร่างและที่มา

### 2.1 Design plan ต้นฉบับ
- **Cursor plan:** `~/.cursor/plans/roblox_ip-safe_game_design_3a5374d5.plan.md` (~1800 บรรทัด)
- ครอบคลุม: IP audit, 5 places, Prism Keys, monetization, security, fan license (Eternity Forge)
- **Pitch:** `~/Desktop/Utopia of Eternity/UTOPIA-OF-ETERNITY-PITCH.html`

### 2.2 หลักการออกแบบ (IP-safe)
- ไม่ใช้ franchise names, ไม่ copy model/audio
- Original universe: Prism Solarpunk aesthetic
- Cosmetic-only monetization — ไม่ P2W combat stats
- เรียนรู้จาก pain points ของ **99 Nights** (griefing, random toxic, difficulty ไม่ลดเมื่อคนออก)

### 2.3 Visual & City plans
- **Eternity City visual upgrade:** `~/.cursor/plans/eternity_city_visual_upgrade_4abf9c47.plan.md`
- Visual bible: `docs/visual-ref/eternity-city/VISUAL-BIBLE.md`

---

## 3. ขั้นเตรียมการ (Phase 0.x)

### Phase 0.5 — Security (Utopia Shield + Sentinel)
**Entry:** `src/ServerScriptService/SecurityCore.server.luau`

| Module | หน้าที่ |
|--------|---------|
| `GriefingGuard` | Sanctuary, PvP spam, DV sabotage |
| `EconomyInflationGuard` | Velocity cap, dump detection, circuit breaker |
| `SevereOffenseGate` | Honeypot/executor → perm ban |
| `EmulatorDetector` | Multi-account → device block |
| `LogExportBridge` | Batch logs → Bridge API |
| `FanScanBridge` | Poll fan-scan candidates |
| `RemoteGuard`, `RateLimiter`, `MovementValidator` | Core anti-cheat |

### Phase 0.6 — Hub greybox + Teleport
- `HubGreyboxBuilder` / `HubWorldBuilder` — Sanctuary + 4 teleport kiosks
- `TeleportBootstrap` — ProximityPrompt → PlaceTeleport
- Place IDs ใน `PlaceSecrets.luau` (gitignored)

### Bootstrap chain
```
GameBootstrap → BridgeBootstrap → SecurityCore → World builders
```

---

## 4. การออกแบบหลัก

| เอกสาร | Path |
|--------|------|
| GDD MVP | `docs/design/GDD-UTOPIA-OF-ETERNITY.md` |
| Systems Volume 02 | `docs/design/DESIGN-V02-SYSTEMS.md` |
| Fan License V03 | `docs/design/DESIGN-V03-FAN-LICENSE-PROGRAM.md` |
| IP Audit | `docs/legal/IP-AUDIT-UTOPIA-OF-ETERNITY.md` |
| City Encyclopedia | `docs/systems/CITY-ENCYCLOPEDIA.md` |
| Social Dungeons | `docs/systems/SOCIAL-DUNGEON-SYSTEM.md` |
| Face Creation | `docs/systems/FACE-CREATION-SYSTEM.md` |

### ระบบ meta หลัก
- **Prism Keys:** จำนวนซ่อน (`??`), cross-city clues, Eternity City gate keys 11/15/20/25
- **Luminlings:** 3-stage grow (Solhaven)
- **Seasons:** `GameConfig.Seasons` — Halloween, Christmas, NewYear, ChineseNewYear, Songkran, LoyKrathong
- **Sanctuary:** 120–280 stud, No PvP, mount pad, Prism Transit Shuttle

---

## 5. World Build & Commerce

### World builders
| Place | Builder |
|-------|---------|
| Hub | `HubWorldBuilder.luau` |
| Solhaven | `SolhavenWorldBuilder.luau` |
| Nocturne | `NocturneWorldBuilder.luau` |
| Eternity City | `EternityCityWorldBuilder.luau` |
| Death Valley | `DeathValleyWorldBuilder.luau` |

**Spec:** `docs/world/WORLD-BUILD-MICROCURVE-SPEC.md`

### Commerce (Eternity City)
- **17 shop entries** ใน `PrismCommerceConfig.luau`
- **Commerce Peace Zone** — No PvP, No Combat Tools
- **Districts:** Aurora Mega Mall, Canal Promenade, Sky Rail, Twilight Overpass
- **Design doc:** `docs/commerce/FASHION-AND-SHOPS-DESIGN.md`
- **Services:** `CommerceShopService.server.luau`, `CommerceShopUI.client.luau`

### Loadout Plazas (Hub, Eternity City, Solhaven, Nocturne)
- `LoadoutPlazaKit.luau` — terminals: wardrobe, titles, shared, market/bazaar + mirror

---

## 6. Death Valley — Phase A ถึง R

**Planet:** Hellbound · **DataStore:** `UtopiaDeathValley_v1` · **Party:** 4 · **Friends-only default**

ทุก phase doc อยู่ที่: `docs/death-valley/phases/`

### Phase A — Survival Core
- Beacon Lv1–3, prep/wave loop, wraiths (Whisper/Stalker/Legion Echo)
- Revive, exit portal, horror FX opt-out
- **Doc:** `DEATH-VALLEY-PHASE-A-SURVIVAL.md`

### Phase B — Expansion
- Night modifiers (every 5 nights), POI (Whispering Grove, Hollow Lake)
- Horizon Rings 5/15/20, Hellbound path stub
- **Doc:** `DEATH-VALLEY-PHASE-B-EXPANSION.md`

### Phase C — Persistence
- DataStore checkpoint, Hellbound travel pipeline, Mega Dungeon zones 2–5
- Weekly rotating boss
- **Doc:** `DEATH-VALLEY-PHASE-C-PERSISTENCE.md`

### Phase D — LiveOps
- Hellbound Terminal (Eternity City), Spirit Chamber, LFG board, season leaderboard
- **Doc:** `DEATH-VALLEY-PHASE-D-LIVEOPS.md`

### Phase E — CrossWorld
- Commerce ticket auto-depart, cross-server LFG, global leaderboard UI (L key)
- **Doc:** `DEATH-VALLEY-PHASE-E-CROSSWORLD.md`

### Phase F — Global Matchmaking
- OrderedDataStore global leaderboard, LFG queue auto-party
- **Doc:** `DEATH-VALLEY-PHASE-F-GLOBAL-MATCHMAKING.md`

### Phase G — Social Rewards
- Direct party invite cross-server, 12-season historical leaderboard, Luminite rewards
- **Doc:** `DEATH-VALLEY-PHASE-G-SOCIAL-REWARDS.md`

### Phase H — Rollover Social
- Friends-list LFG invite, season titles/cosmetics, top-25 auto-distribute
- **Doc:** `DEATH-VALLEY-PHASE-H-ROLLOVER-SOCIAL.md`

### Phase I — Presentation Admin
- Title billboard overhead, cosmetic aura FX, Studio admin F9 force rollover
- **Doc:** `DEATH-VALLEY-PHASE-I-PRESENTATION-ADMIN.md`

### Phase J — Cosmetic Persistence
- Cosmetic picker (C), DataStore owned/equipped, admin reset season pointer
- **Doc:** `DEATH-VALLEY-PHASE-J-COSMETIC-PERSISTENCE.md`

### Phase K — Loadout Hub
- Title picker (T), 3D preview, Hub loadout terminals, cross-place equip
- **Doc:** `DEATH-VALLEY-PHASE-K-LOADOUT-HUB.md`

### Phase L — Unified Mirror
- Unified tab UI (V), 3× preset slots, Hub mirror showcase
- **Doc:** `DEATH-VALLEY-PHASE-L-UNIFIED-MIRROR.md`

### Phase M — Preset Share Plaza
- Share preset with friends, mirror auto-rotate, Eternity City loadout plaza
- **Doc:** `DEATH-VALLEY-PHASE-M-PRESET-SHARE-PLAZA.md`

### Phase N — Cross-Server Social
- Share codes, cross-server MessagingService notify, friend online toast
- Plazas in Solhaven/Nocturne
- **Doc:** `DEATH-VALLEY-PHASE-N-CROSS-SERVER-SOCIAL.md`

### Phase O — Friend Join & Bazaar
- Teleport to friend via presence jobId, offline notify queue, preset marketplace
- **Doc:** `DEATH-VALLEY-PHASE-O-FRIEND-JOIN-BAZAAR.md`

### Phase P — Packs, Featured, Push
- Robux preset packs (`PrismPresetPackCatalog`), featured carousel (MemoryStore)
- Open Cloud bridge sender for push notifications
- **Doc:** `DEATH-VALLEY-PHASE-P-PACKS-FEATURED-PUSH.md`

### Phase Q — Commerce, Creator, Rotation
- Commerce District kiosk `preset_bazaar` (Canal Promenade)
- Creator revenue ledger (70% pack share, +5 credits per bazaar download)
- Seasonal featured rotation by `GameConfig.Seasons` month
- **Doc:** `DEATH-VALLEY-PHASE-Q-COMMERCE-CREATOR-ROTATION.md`

### Phase R — Payout, UGC, Seasonal Pop-Up
- **Group payout export:** `RequestCreatorPayout` → Bridge CSV/JSON for group treasurer
- **UGC-linked packs:** `CreateUgcCreatorPack` — Bazaar listing → dynamic `dv_ugc_*` pack
- **Seasonal pop-up shop:** `seasonal_pop_up` (SkyRail) + rotated packs + UGC packs
- **Doc:** `DEATH-VALLEY-PHASE-R-PAYOUT-UGC-SEASONAL.md`

### Phase S — Payout Automation, UGC Picker & Seasonal Polish ✅ ล่าสุด
- **UGC price picker:** Modal tier selector R$49–499 in Bazaar tab
- **Payout history UI:** History rows + disable Request when pending
- **Group payout cron:** `bridge/scripts/payout-export-cron.sh` + `lastExportAt` status
- **Seasonal polish:** `GameConfig.SeasonThemes`, filtered fashion catalog, themed CommerceShopUI, kiosk decorations
- **Doc:** `DEATH-VALLEY-PHASE-S-PAYOUT-UGC-POLISH.md`

---

## 7. สถาปัตยกรรม Loadout Stack (Phase K→R)

```
┌─────────────────────────────────────────────────────────────┐
│  Client: DeathValleyUnifiedLoadoutUI (tabs: Titles/Cosms/   │
│  Presets/Shared/Bazaar) + CommerceShopUI + Presence Toast   │
└───────────────────────────┬─────────────────────────────────┘
                            │ DeathValleyRemotes
┌───────────────────────────▼─────────────────────────────────┐
│  DeathValleyLoadoutHandlers.server.luau                     │
└───────────────────────────┬─────────────────────────────────┘
                            │
     ┌──────────────────────┼──────────────────────┐
     ▼                      ▼                      ▼
 LoadoutPresetService   PresetShareService    PresetMarketService
 PresetPackService      FeaturedService       UgcCreatorPackService
 FeaturedRotationService CreatorRevenueService SeasonalPopUpShopService
 FriendPresenceService  FriendJoinService     SocialNotifyService
     │                      │                      │
     └──────────────────────┼──────────────────────┘
                            ▼
              DeathValleyPlayerStore (DataStore UtopiaDeathValley_v1)
                            │
              MemoryStore (market, featured, ugc packs, presence)
                            │
              Bridge (payout queue, open cloud push)
```

### PlayerStore fields สำคัญ (Phase C→R)
- `checkpoint`, `seasonBests`, `earnedTitles`, `ownedCosmetics`, `equipped*`
- `loadoutPresets` (3 slots), `presetInbox`, `activeShareCodes`
- `socialNotifyQueue`, `notifyPrefs`
- `publishedMarketListings`, `marketLikes`, `purchasedPresetPacks`
- `creatorBalance`, `creatorSalesLedger`, `creatorPayoutRequests`
- `linkedUgcPackIds`

### Server services (45 modules ใน DeathValley/)
**Survival:** Beacon, Night, Wraith, Revive, Checkpoint, Expansion, POI, WeeklyBoss  
**Season/LFG:** Season, SeasonRollover, SeasonReward, Lfg*, Leaderboard*  
**Loadout/Social:** Loadout*, Preset*, Market*, Pack*, Featured*, Creator*, Ugc*, Friend*, Social*, JoinData  

---

## 8. Bridge & Open Cloud

**Path:** `bridge/` · **Port:** 8011 · **Run:** `bash bridge/run-bridge.sh`

| Endpoint | Phase | Purpose |
|----------|-------|---------|
| `/utopia/log-analyzer` | 0.5 | Security log batch |
| `/utopia/fan-scan` | 0.5 | Fan experience candidates |
| `/utopia/social-notify/push\|process` | P | Open Cloud push queue |
| `/utopia/creator-payout/push\|export\|mark-paid\|status` | R | Group treasurer payout |

**Secrets:** `src/ServerScriptService/Secrets/BridgeSecrets.luau` (gitignored)  
**Example:** `BridgeSecrets.example.luau`

**Env:** `bridge/.env` — `ROBLOX_OPEN_CLOUD_API_KEY`, `ROBLOX_UNIVERSE_ID`, `ROBLOX_CREATOR_GROUP_ID`

---

## 9. โครงสร้างโฟลเดอร์ (หลังจัดระเบียบ)

```
utopia-of-eternity-game/
├── default.project.json          ← Rojo map (อย่าย้าย path ใน src/)
├── README.md
├── docs/
│   ├── 00-START-HERE.md          ← เปิด session ใหม่เริ่มที่นี่
│   ├── PROJECT-MASTER-HANDBOOK.md ← เอกสารนี้
│   ├── INDEX.md
│   ├── design/                   ← GDD, DESIGN-V02/V03
│   ├── death-valley/
│   │   ├── phases/               ← DEATH-VALLEY-PHASE-A..R.md
│   │   ├── DEATH-VALLEY-MEGA-DUNGEON.md
│   │   └── HELLBOUND-TRAVEL-AND-DEATH-VALLEY.md
│   ├── commerce/                 ← Fashion, weapons catalog
│   ├── world/                    ← Microcurve, streaming specs
│   ├── legal/                    ← IP audit, license checklist
│   ├── systems/                  ← City encyclopedia, social dungeon, face
│   ├── visual-ref/               ← Art reference (fashion, weapons, city)
│   ├── ugc/                      ← Blockbench pipeline
│   └── reference/                ← Quant build study
├── src/
│   ├── ServerScriptService/
│   │   ├── DeathValley/          ← 45 server modules + handlers
│   │   ├── Commerce/
│   │   ├── World/
│   │   ├── Security/
│   │   ├── Hellbound/
│   │   └── Secrets/              ← BridgeSecrets, PlaceSecrets (gitignored)
│   ├── ReplicatedStorage/Modules/
│   │   ├── GameConfig.luau       ← Source of truth สำหรับ tuning
│   │   ├── PrismCommerceConfig.luau
│   │   ├── PrismPresetPackCatalog.luau
│   │   └── ...
│   └── StarterPlayer/StarterPlayerScripts/
│       ├── DeathValleyUnifiedLoadoutUI.client.luau  ← Loadout UI หลัก
│       └── CommerceShopUI.client.luau
└── bridge/
    ├── main.py
    ├── creator_payout.py         ← Phase R/S
    ├── scripts/payout-export-cron.sh  ← Phase S
    └── opencloud_notify.py       ← Phase P
```

**หมายเหตุ:** โค้ด Luau ใน `src/` **ไม่ได้ย้าย** — Rojo `default.project.json` อ้าง path ตรง จึงปลอดภัย

---

## 10. Config & Secrets

### GameConfig.luau
- `GameConfig.Places` — 5 place keys
- `GameConfig.DeathValley` — party, docs paths, SeasonalFeaturedRotation, CreatorPayout, UgcCreatorPack, MegaDungeon
- `GameConfig.SeasonThemes` — seasonal pop-up accent colors (Phase S)
- `GameConfig.StudioDev.SimulatePlaceKey` — Studio place simulation
- `GameConfig.Bridge` — URLs (filled by BridgeBootstrap)

### ต้องตั้งก่อน publish
1. `PlaceSecrets.luau` — Place IDs ทั้ง 5
2. `BridgeSecrets.luau` — Bridge URLs + key
3. `PrismCatalogAssets` — Developer Product IDs สำหรับ packs
4. `GameConfig.DeathValley.CreatorPayout.groupId`
5. `ROBLOX_CREATOR_GROUP_ID` ใน bridge `.env`

---

## 11. Remotes สำคัญ (Death Valley)

**Setup:** `DeathValleyRemoteSetup.server.luau`  
**Handlers:** `DeathValleyLoadoutHandlers.server.luau`, `DeathValleySocialHandlers.server.luau`

| Remote | Phase | ใช้ |
|--------|-------|-----|
| `GetLoadoutFull`, `SaveLoadoutPreset`, `ApplyLoadoutPreset` | L | Preset slots |
| `ShareLoadoutPreset`, `GeneratePresetShareCode`, `RedeemPresetShareCode` | M/N | Share |
| `BrowsePresetMarket`, `PublishPresetMarket`, `AcquirePresetMarket` | O | Bazaar |
| `TeleportToFriend`, `GetFriendJoinPreview` | O | Join friend |
| `GetFeaturedCarousel`, `PurchasePresetPack` | P | Carousel + packs |
| `GetCreatorRevenueSummary`, `RequestCreatorPayout` | Q/R | Creator economy |
| `CreateUgcCreatorPack`, `GetMyUgcCreatorPacks` | R | UGC packs |
| `GetSeasonalPopUpShop` | R | Seasonal shop payload |

---

## 12. Validation & Studio Test

```bash
cd "/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game"

# Rojo project valid
python3 -m json.tool default.project.json > /dev/null

# Phase S symbols
rg "UgcCreatorPack|SeasonThemes|payout-export-cron|priceTiers|seasonTheme" src/ bridge/

# Bridge module
cd bridge && python3 -c "import creator_payout; print('ok')"
```

### Studio checklist (EternityCity)
1. Canal Promenade → **Preset Bazaar** kiosk
2. SkyRail → **Seasonal Pop-Up · {Season}**
3. Loadout terminal → Bazaar tab → season label, carousel, payout, UGC sell
4. `GameConfig.StudioDev.SimulatePlaceKey = "EternityCity"`

---

## 13. งานถัดไป (Backlog)

| Priority | งาน | สถานะ |
|----------|-----|--------|
| P0 ✅ | Place IDs + Dev Products + Rojo publish | **live** |
| P0 ✅ | Group ownership transfer `791898614` | **done 9 Jun 2026** |
| P0 ✅ | Bridge production `api.utopiaofeternity.com` | **live** |
| P0 ✅ | Phase T payout sync | **done** — `DEATH-VALLEY-PHASE-T-PAYOUT-SYNC.md` |
| P0 ⏳ | Public/Limited Configure Save | **blocked** ~10 Jun 2026 (waiting period) |
| P1 ✅ | Prism Keys chain (pickups + place guard) | **code ready** — Studio verify after Public |
| P2 ✅ | Support Desk UI + Bridge fan report | **wired** |
| P3 | Blockbench Tier S UGC meshes | offline — `docs/ugc/OFFLINE-WORK-CHECKLIST.md` |
| P3 | License Manager (Roblox Dashboard) | **after Public Save** |

---

## Meziyah Ecosystem Integration

Agent ทุกตัว (Hermes, Cursor, Paperclip) ที่ทำงานโปรเจกตนี้:

| Resource | Path |
|----------|------|
| Boot wing | `utopia-of-eternity` |
| Registry | `~/blue-topaz-ai/config/projects/utopia-of-eternity.yaml` |
| Clawdi skill | `~/blue-topaz-ai/skills/utopia-of-eternity/SKILL.md` |
| Obsidian memory | `~/Obsidian/knowledge_base/UTOPIA-OF-ETERNITY-PROJECT-MEMORY.md` |
| Obsidian mirror | `~/Obsidian/knowledge_base/projects/utopia-of-eternity/` |
| Cursor rule | `~/.cursor/rules/utopia-of-eternity-meziyah.mdc` |
| MemPalace | `mempalace.yaml` (game root) · wing `utopia_of_eternity` |

```bash
~/blue-topaz-ai/scripts/agent-boot-contract.sh \
  --wing utopia-of-eternity --task-type coding --query "..."
```

---

## 14. อ้างอิงภายนอก

| รายการ | Path |
|--------|------|
| Design plan ต้นฉบับ | `~/.cursor/plans/roblox_ip-safe_game_design_3a5374d5.plan.md` |
| Eternity City visual plan | `~/.cursor/plans/eternity_city_visual_upgrade_4abf9c47.plan.md` |
| Agent transcript session นี้ | `~/.cursor/projects/Users-macbook/agent-transcripts/` (ค้นหา `Phase R`) |
| Obsidian memory copy | `~/Obsidian/knowledge_base/UTOPIA-OF-ETERNITY-PROJECT-MEMORY.md` |
| Meziyah registry | `~/blue-topaz-ai/config/projects/utopia-of-eternity.yaml` |
| Meziyah skill | `~/blue-topaz-ai/skills/utopia-of-eternity/SKILL.md` |
| Meziyah graph (ถ้ามี) | `~/Meziyah/graphify-out/` |

---

**บันทึกโดย:** Cursor Agent · Session Death Valley Loadout Phases I→R · 9 มิ.ย. 2026  
**Post-transfer update:** 9 มิ.ย. 2026 — Group `791898614` owner · Community visibility ON · Public Save deferred
