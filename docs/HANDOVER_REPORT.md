# HANDOVER REPORT — Utopia of Eternity (Roblox)

**Date:** 9 มิถุนายน 2026  
**Handover to:** Claude Cowork / Next Agent  
**Project root:** `/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game/`  
**Universe ID:** `10293115628` · **Group:** `791898614` (Utopia of Eternity)

---

## 1. Project Architecture & Data Flow

```
Roblox Client (StarterPlayerScripts UI)
        │ RemoteFunction / RemoteEvent
        ▼
ServerScriptService
  ├── GameBootstrap.server.luau
  │     BridgeBootstrap → WorldBootstrap:BuildCurrent() → WorldStudioSpawnGuard
  ├── SecurityCore.server.luau (BanRegistry, RemoteGuard*, GriefingGuard*)
  ├── DeathValley/ (46 modules — survival, LFG, loadout, seasons)
  ├── World/ (25 modules — greybox builders per place)
  ├── Commerce/, Dungeon/, Progression/, Hellbound/, Shuttle/, Mount/
  └── Secrets/ (PlaceSecrets, CatalogSecrets, BridgeSecrets — gitignored)

ReplicatedStorage/Modules/
  ├── GameConfig.luau (routing, sanctuary, bridge URLs)
  ├── Prism* configs (fashion, dungeon, survival, commerce)
  └── PlaceTeleport.luau (5-place teleport matrix)

Persistence:
  DataStore (PrismKey, DeathValley, BanRegistry, Leaderboard)
  MemoryStore (LFG market, preset share, friend presence, UGC packs)
  Attributes (session state, zone gates, ownership flags)

External:
  bridge/ FastAPI :8011 — log analyzer, fan-scan, creator payout, face capture
  Roblox Open Cloud (notifications, payout export)
```

**World build pattern:** Luau procedural greybox — NOT hand-sculpted Studio terrain.
`GameBootstrap` → `WorldBootstrap:BuildCurrent()` → `WorldPlaceGuard:ShouldBuild(placeKey)` → place-specific `*WorldBuilder`.

**Studio local rbxlx:** `PlaceId == 0` → uses `GameConfig.StudioDev.SimulatePlaceKey` (currently `"EternityCity"`).

---

## 2. Current Implementation (สำเร็จแล้ว)

| Area | Status |
|------|--------|
| **5 MVP Places** | Hub, Solhaven, Nocturne, EternityCity, DeathValley — greybox builders |
| **Eternity City Landmarks** | Marina Ring (#1), Aurora Spire (#2), Canal Promenade (#3) |
| **Publish** | `scripts/publish-place.sh EternityCity` → place `94486544638073` |
| **Prism Keys** | Cross-place persistence, pickups, trade, ghost NPC |
| **Death Valley** | Phases A–T (survival, seasons, LFG, loadout market, payout bridge) |
| **Utopia Shield** | 22 Security modules in repo (partially wired — see blockers) |
| **Commerce** | 20 shop districts, fashion catalogs, Developer Products (7 P0) |
| **Bridge** | FastAPI health, log-analyzer, fan-scan, payout sync |
| **Studio playtest** | `~/Desktop/utopia-playtest.rbxlx` + `scripts/studio-playtest-build.sh` |
| **Luau syntax fixes** | 14+ Prism modules, spawn guard, place guard (Jun 2026 session) |

---

## 3. The Roadblock (จุดที่ติดขัด)

### 3.1 แผนที่ไม่ขึ้น + Death Loop (แก้แล้ว — root cause คู่)

1. **`WorldPlaceGuard:ShouldBuild()`** — local rbxlx `PlaceId==0` เทียบกับ cloud Place ID → skip build → empty workspace  
   **Fix:** ใช้ `SimulatePlaceKey` เมื่อ `PlaceId==0`

2. **`GameBootstrap` crash ก่อนถึง `WorldBootstrap`** — invalid Luau `Module.Field: Type = value` ใน 14 ไฟล์ Prism config  
   **Fix:** แปลงเป็น `Field = {} :: Type`

3. **`PrismKeyPickupKit` ไม่อยู่ใน `default.project.json`** → require chain fail  
   **Fix:** เพิ่มใน project.json

4. **`WorldStudioSpawnGuard`** — `FallenPartsDestroyHeight` throw ใน Play → build หยุดก่อน spawn  
   **Fix:** `pcall` + ย้าย `BuildCurrent()` มาก่อน `start()`

### 3.2 ยังไม่แก้ / Production blockers

| Issue | Severity |
|-------|----------|
| `DEV_GRANT_FREE = true` ใน Commerce + PresetPack | CRITICAL |
| `ProcessReceipt` always `PurchaseGranted` | CRITICAL |
| `DevGrantEternityItem` remote เปิดใน production path | CRITICAL |
| `HealChannelComplete` ไม่มี channel proof | CRITICAL |
| `RemoteGuard:Register` ไม่ถูกเรียกเลย | HIGH |
| `GriefingGuard` ไม่ถูก wire เข้า gameplay | HIGH |
| 6× MemoryStore + `EvasionDetector` init ไม่มี pcall | HIGH |
| `SimulatePlaceKey=EternityCity` ทำให้ DV bootstrap ข้ามใน Studio | MEDIUM |

---

## 4. Tech Stack

| Layer | Technology |
|-------|------------|
| Game engine | Roblox Studio 0.724.x |
| Language | Luau (`--!strict`) |
| Sync | Rojo 7.4.4 (`default.project.json`) |
| Lint (pinned) | Selene 0.27.1 (not in CI) |
| Bridge | Python 3.14 + FastAPI (`bridge/main.py` :8011) |
| Publish | `rojo` + Open Cloud API (`scripts/publish-place.sh`) |
| Automation | Peekaboo (F5 Play), cua-driver (Studio focus) |
| Docs | Markdown in `docs/` (61 files, ~145MB incl. visual-ref PNGs) |
| Secrets | `src/ServerScriptService/Secrets/*.luau` + `bridge/.env` |

---

## 5. โครงสร้างโฟลเดอร์ปัจจุบัน

```
utopia-of-eternity-game/
├── default.project.json          # Rojo map (466 lines)
├── aftman.toml                   # Rojo, Selene, Wally pins
├── README.md
├── docs/                         # 61 .md + visual-ref images (~145MB)
│   ├── 00-START-HERE.md
│   ├── PROJECT-MASTER-HANDBOOK.md
│   ├── HANDOVER_REPORT.md        # ไฟล์นี้
│   ├── design/, death-valley/phases/, commerce/, legal/, systems/
│   └── visual-ref/eternity-city/VISUAL-BIBLE.md
├── scripts/                      # 9 automation scripts
│   ├── publish-place.sh
│   ├── validate-p0-publish.py
│   ├── validate-world-place-guard.py
│   └── studio-playtest-build.sh
├── src/                          # 191 .luau (หลังลบ orphan)
│   ├── ServerScriptService/      # 134 files
│   │   ├── GameBootstrap.server.luau
│   │   ├── SecurityCore.server.luau
│   │   ├── BridgeBootstrap.luau
│   │   ├── CatalogBootstrap.luau
│   │   ├── DeathValley/          # 46 modules
│   │   ├── World/                # 25 modules (+ 3 Eternity landmarks)
│   │   ├── Security/             # 22 modules
│   │   ├── Dungeon/              # 5 modules (Zone1Service ลบแล้ว)
│   │   ├── Progression/          # 7 modules
│   │   ├── Commerce/             # 2 modules
│   │   ├── Hellbound/            # 5 modules
│   │   ├── Shuttle/              # 4 modules
│   │   ├── Mount/                # 4 modules
│   │   ├── Face/                 # 1 module
│   │   └── Secrets/              # 6 (3 live gitignored + 3 .example)
│   ├── ReplicatedStorage/Modules/  # 30 modules
│   ├── StarterPlayer/StarterPlayerScripts/  # 26 client scripts
│   └── ServerStorage/WorldKits/  # ArchRibKit.luau
└── bridge/                       # FastAPI + .venv (~38MB)
    ├── main.py
    ├── creator_payout.py
    ├── face_capture.py
    └── .env.example
```

---

## 6. ไฟล์สำคัญ (Key Files)

### Boot & World
| File | Role |
|------|------|
| `GameBootstrap.server.luau` | Studio spawn defer + world build order |
| `BridgeBootstrap.luau` | Load PlaceSecrets → GameConfig |
| `WorldBootstrap.luau` | Route to place builder |
| `WorldPlaceGuard.luau` | ShouldBuild + SimulatePlaceKey |
| `WorldStudioSpawnGuard.luau` | Void guard, sanctuary spawn |
| `EternityCityWorldBuilder.luau` | Flagship city + landmarks |
| `GameConfig.luau` | Central config (450 lines) |

### Security
| File | Role |
|------|------|
| `SecurityCore.server.luau` | Security stack bootstrap |
| `RemoteGuard.luau` | **Unused** — Register never called |
| `GriefingGuard.luau` | **Unwired** — no gameplay hooks |
| `BanRegistry.luau` | Ban persistence |

### Economy (needs hardening)
| File | Role |
|------|------|
| `CommerceShopService.server.luau` | Shop + `DEV_GRANT_FREE` + ProcessReceipt |
| `DeathValleyLoadoutPresetPackService.luau` | Pack purchases |
| `MountRewardHandlers.server.luau` | `DevGrantEternityItem` remote |

### Publish & Validate
| File | Role |
|------|------|
| `scripts/publish-place.sh` | Single-place Open Cloud publish |
| `scripts/validate-p0-publish.py` | Place IDs + Dev Products check |
| `scripts/validate-world-place-guard.py` | SimulatePlaceKey guard test |
| `Secrets/PlaceSecrets.luau` | 5 place IDs (gitignored) |

---

## 7. ขนาดโค้ด & Token Estimate

| Metric | Value |
|--------|------:|
| **Luau files** | 191 |
| **Luau bytes** | 935,969 (~913 KB) |
| **Luau lines** | 29,761 |
| **Est. tokens (Luau only, ÷4)** | ~234,000 |
| **src/ folder size** | 1.3 MB |
| **scripts/ (py+sh)** | ~51 KB code |
| **bridge/ Python (excl .venv)** | ~15 KB source |
| **docs/ (incl. images)** | ~145 MB |
| **Full project (excl. venvs)** | ~185 MB |

**สำหรับ Cowork context window:**
- โหลดเฉพาะ `src/` ≈ **234K tokens** (เกิน context เดียว — ใช้ graphify / scoped grep)
- โหลดเฉพาะ `World/` + `GameBootstrap` ≈ **~25K tokens**
- Audit report + HANDOVER ≈ **~8K tokens**

---

## 8. คำสั่งที่ใช้บ่อย

```bash
cd "/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game"

# Build local playtest
rojo build default.project.json -o ~/Desktop/utopia-playtest.rbxlx

# Validate
python3 scripts/validate-p0-publish.py
python3 scripts/validate-world-place-guard.py

# Publish single place (ต้องอนุมัติ — ห้าม publish-all โดยไม่ถาม)
bash scripts/publish-place.sh EternityCity

# Studio Play
open -a RobloxStudio --args -localPlaceFile ~/Desktop/utopia-playtest.rbxlx -task EditFile
```

---

## 9. งานถัดไป (Priority)

1. **Phase A Security** — ปิด `DEV_GRANT_FREE`, แก้ ProcessReceipt, ปิด DevGrant remote
2. **Landmark #4** — Sky Rail Plaza (`EternityCitySkyRailLandmark.luau`)
3. **Wire RemoteGuard + GriefingGuard** เข้า remotes จริง
4. **MemoryStore pcall** — 6 ไฟล์ Death Valley + EvasionDetector
5. **CI** — GitHub Actions: rojo build + validate scripts

---

## 10. นโยบายที่ต้องจำ (9 Jun 2026)

- ห้าม automate Roblox website จนกว่าผู้ใช้จะสั่ง Public Save (~10 Jun 2026)
- ห้าม `publish-all-places.sh` โดยไม่ได้รับอนุมัติชัด
- เปิด Studio ผ่าน Dashboard → Group Utopia of Eternity → Edit (ไม่ใช้ Hub deep link)
- Eternity City Place ID: `94486544638073`

---

*Generated by Cursor Agent — Project Handover 9 Jun 2026*
