# BLUEPRINT — Map Generation & Character Spawn Rebuild

**โปรเจกต์:** Utopia of Eternity (Roblox · Luau `--!strict`)
**วันที่:** 10 มิถุนายน 2026
**สถานะ:** รออนุมัติ (ยังไม่เขียนโค้ด)
**ขอบเขต:** แก้ root cause ของ Context/Death Loop ในขั้น "สร้างแผนที่" และ "สร้างตัวละครใน Map" เท่านั้น — **ไม่แตะ** blockers ด้าน economy/security (คนละเฟส)
**อ้างอิงฐาน:** `docs/HANDOVER_REPORT.md`

---

## 1. บริบทปัจจุบัน (ยืนยันจากโค้ดจริง)

โลกถูกสร้างแบบ **procedural greybox ด้วย Luau** ไม่ใช่ terrain ปั้นมือ ลำดับ boot:

```
GameBootstrap.server.luau
  → BridgeBootstrap:Apply()                 โหลด PlaceSecrets เข้า GameConfig
  → WorldBootstrap:BuildCurrent()           WorldPlaceGuard:GetCurrentPlaceKey() → BUILDERS[key]:Build()
  → WorldStudioSpawnGuard.start()           (เฉพาะ Studio: RunService:IsStudio())
  → waitForWorldReady(60) → ensureEmergencyFloor → loadDeferredCharacters
```

ไฟล์ที่เกี่ยวข้องโดยตรง (โดเมน World):

| ไฟล์ | บทบาทปัจจุบัน |
|------|----------------|
| `World/WorldBootstrap.luau` | routing table `BUILDERS` + `BuildCurrent()` |
| `World/WorldPlaceGuard.luau` | `GetCurrentPlaceKey()`, `ShouldBuild()`, `ModelExists()` |
| `World/WorldBuildState.luau` | singleton สถานะ build แบบ event (`pending/ready/failed`) — **ออกแบบดี** |
| `World/WorldStudioSpawnGuard.luau` | defer spawn, void guard, sanctuary teleport |
| `World/*WorldBuilder.luau` (5 ตัว) | สร้าง greybox ต่อ place |
| `World/WorldBuildShared.luau`, `WorldBuildBudget.luau` | helper ร่วม |

---

## 2. Root Cause ของ Loop (หลักฐานระดับบรรทัด)

> หมายเหตุ: bug ชุดแรก (ShouldBuild ตอน `PlaceId==0`, GameBootstrap crash จาก syntax, PrismKeyPickupKit หาย, `FallenPartsDestroyHeight` throw) **แก้แล้วจริง** ในโค้ด ส่วนด้านล่างคือรากที่ **ยังเหลือ** และทำให้ loop กลับมาได้

| # | ปัญหา | หลักฐาน | ผลที่เกิด |
|---|-------|---------|-----------|
| A | **สัญญา State ถูกเคารพแค่ 1 ใน 5 builder** | มีแค่ `EternityCityWorldBuilder` เรียก `WorldBuildState.markReady()/markFailed()` (บรรทัด 250, 320, 323) — Hub/Solhaven/Nocturne/DeathValley ไม่เรียกเลย | บน 4 place นั้น `_status` ค้าง `"pending"` → `waitForWorldReady(60)` block เต็ม 60s แล้ว fallback ไป scan ชื่อ model |
| B | **4 ใน 5 builder ไม่มี pcall** | `EternityCity` ห่อ build ด้วย pcall เดียว, อีก 4 ตัวไม่มี | error กลางทาง = build ตายทั้งก้อน ไม่มี `markFailed` → ทุก waiter ค้าง → ตัวละครตกเหว → loop |
| C | **SpawnGuard ทำงานเฉพาะ Studio** | `GameBootstrap` เรียก `WorldStudioSpawnGuard.start()` ใต้ `if studioDeferSpawn` (`RunService:IsStudio()`) แต่ comment ในโมดูลอ้างว่ากัน loop "บน cloud places" | บน server จริง guard หลับ — build ช้า/ล้มเหลว = ตกเหวกู้ไม่ได้ |
| D | **Map ↔ Character ผูกกันด้วยการ scan ชื่อ string** | `waitForWorldReady` fallback ไปหา `WORLD_MODEL_NAMES` ที่ hardcode | ความพร้อม spawn ขึ้นกับ string match ไม่ใช่ contract — เปราะ |
| E | **Re-entrancy แก้ครึ่งเดียว** | `characterLocks` กัน stabilize ซ้อนได้ แต่ `stabilizeCharacter` เรียก `waitForWorldReady(60)` อยู่ในล็อก ขณะ VoidGuard ยิงทุก 0.35s | ภายใต้ pending ตัวละครค้าง 60s ดูเหมือนแขวน/loop |

**สรุปแก่น:** โดเมน "สร้าง map" กับ "สร้าง character" ผูกกันแบบ implicit (scan ชื่อ + state ที่ไม่ทุก builder เซ็ต) ทำให้ความล้มเหลวของฝั่งหนึ่งลามเป็น loop อีกฝั่ง

---

## 3. สถาปัตยกรรมเป้าหมาย (Modular)

แยก **2 โดเมน** เชื่อมด้วย contract เดียว (`WorldBuildState`) — เลิกพึ่ง name-scan

```
┌─ WORLD DOMAIN ───────────────────┐    Ready/    ┌─ PLAYER DOMAIN ──────────────────┐
│ BuildOrchestrator                │    Failed    │ SpawnService  (always-on)        │
│  • วน builders ตาม route          │    event     │  • subscribe WorldBuildState     │
│  • ห่อ pcall + budget + idempotent│ ───────────▶ │  • CharacterAutoLoads = gate     │
│  • จุด "เดียว" ที่ set state       │ (WorldBuild  │  • loadDeferredCharacters()      │
├──────────────────────────────────┤   State)     ├──────────────────────────────────┤
│ IWorldBuilder  (5 ตัว)            │              │ VoidRecovery  (แยกจาก spawn)      │
│  • คืน BuildResult {ok,model,…}   │              │  • เจ้าของ FallenPartsDestroyHeight│
│  • "สร้าง part" ล้วน ไม่ยุ่ง state │              │  • Heartbeat watch เดียว          │
└──────────────────────────────────┘              │  • teleport ไม่ block 60s ในล็อก  │
         ▲                                         └──────────────────────────────────┘
         │ placeKey
   PlaceRouter (= WorldPlaceGuard เดิม, แหล่ง placeKey เดียว)
```

**หลักการเปลี่ยน 5 ข้อ (จับคู่กับ root cause):**

1. **Builder เป็น pure** → คืน `BuildResult` ไม่เรียก `markReady` เอง (แก้ A, B)
2. **Orchestrator เป็นจุดเดียวที่ห่อ pcall + set state** → ทุก place ได้ contract เท่ากันอัตโนมัติ (แก้ A, B)
3. **SpawnService เปิดเสมอ** gate ด้วย config ไม่ใช่ `IsStudio()` (แก้ C)
4. **VoidRecovery แยกจาก Spawn** → teleport ไม่ถือ 60s-wait ในล็อก (แก้ E)
5. **ตัด name-scan fallback** → spawn อ่านจาก `WorldBuildState` อย่างเดียว (แก้ D)

---

## 4. Component Contracts (Interface)

### 4.1 `IWorldBuilder` — รูปแบบที่ทุก builder ต้องทำตาม

```lua
export type BuildResult = {
    ok: boolean,
    model: Model?,      -- model ที่สร้าง (nil ถ้า skip/fail)
    skipped: boolean,   -- true = ไม่ใช่ place นี้ หรือ build ซ้ำ
    reason: string?,    -- ข้อความ error เมื่อ ok=false
}

-- ทุก *WorldBuilder ต้อง implement:
function Builder:Build(ctx: BuildContext): BuildResult
```

> Builder **ห้าม** เรียก `WorldBuildState`, `pcall` รอบตัวเอง, หรือยุ่ง `CharacterAutoLoads` — แค่สร้าง part แล้วคืนผล

### 4.2 `BuildOrchestrator` — เจ้าของ state คนเดียว

```lua
-- เรียกจาก GameBootstrap แทน WorldBootstrap:BuildCurrent()
function BuildOrchestrator:Run(): BuildResult
    local key = PlaceRouter:GetCurrentPlaceKey()
    local builder = BUILDERS[key]
    if not builder then WorldBuildState.markFailed("no builder: "..key); return ... end

    local ok, result = pcall(function() return builder:Build(self:makeContext(key)) end)
    if ok and result.ok then
        WorldBuildState.markReady()
    elseif ok and result.skipped then
        WorldBuildState.markReady()           -- ไม่มีอะไรต้องสร้าง = พร้อม
    else
        WorldBuildState.markFailed(result and result.reason or tostring(result))
    end
    return ...
end
```

### 4.3 `SpawnService` — always-on, อ่าน state

```lua
function SpawnService.start(opts: { deferUntilReady: boolean })
    if opts.deferUntilReady then Players.CharacterAutoLoads = false end
    task.spawn(function()
        local ready = WorldBuildState.waitReady(Config.WorldReadyTimeout)
        if not ready then VoidRecovery.ensureEmergencyFloor() end  -- พร้อม floor สำรองก่อนปล่อยคน
        Players.CharacterAutoLoads = true
        SpawnService.loadDeferredCharacters()
    end)
end
```

### 4.4 `VoidRecovery` — แยก concern การกู้คนตกเหว

```lua
function VoidRecovery.start()                         -- เปิดเสมอ (Studio + cloud)
    pcall(function() Workspace.FallenPartsDestroyHeight = -2048 end)
    -- Heartbeat watch (throttle 0.35s) — เจ้าของเดียว
end
function VoidRecovery.recover(character: Model)        -- teleport ไป sanctuary, ไม่ block 60s
```

---

## 5. แผนระดับไฟล์ (File-level Change Plan)

### ไฟล์ใหม่ (`src/ServerScriptService/World/`)
| ไฟล์ | เนื้อหา |
|------|---------|
| `BuildOrchestrator.luau` | logic ข้อ 4.2 — จุดเดียวที่ set state |
| `WorldBuilderTypes.luau` | `BuildResult`, `BuildContext` (export type) |
| `SpawnService.luau` | logic ข้อ 4.3 (always-on) |
| `VoidRecovery.luau` | logic ข้อ 4.4 (แยกจาก SpawnGuard) |

### ไฟล์ที่แก้
| ไฟล์ | การแก้ |
|------|--------|
| `GameBootstrap.server.luau` | เรียก `BuildOrchestrator:Run()` + `SpawnService.start()` + `VoidRecovery.start()` แทน 3 บรรทัดเดิม; **ลบ** เงื่อนไข `if studioDeferSpawn` รอบ guard |
| `HubWorldBuilder.luau` ฯลฯ (×5) | เปลี่ยน `:Build()` ให้ **คืน `BuildResult`** ตัด `markReady/markFailed` ออกจาก EternityCity (ย้ายขึ้น orchestrator) |
| `WorldStudioSpawnGuard.luau` | ลดเหลือ shim ที่ re-export `SpawnService`+`VoidRecovery` (กัน require chain เดิมพัง) หรือ **ลบ** หลังย้าย require ครบ |
| `WorldBootstrap.luau` | คง `BUILDERS` table ไว้ (orchestrator ใช้ต่อ); `BuildCurrent()` กลายเป็น wrapper เรียก orchestrator |
| `default.project.json` | เพิ่ม 4 ไฟล์ใหม่เข้า Rojo map |

### ไม่แตะ
`WorldPlaceGuard.luau` (ใช้เป็น PlaceRouter ต่อ), `WorldBuildState.luau` (contract เดิมดีอยู่แล้ว), `WorldBuildShared/Budget.luau`, builder ภายใน (marina/aurora/canal ฯลฯ), economy/security ทั้งหมด

---

## 6. ลำดับการทำงานใหม่ (Target Sequence)

```
GameBootstrap
  → BridgeBootstrap:Apply()
  → VoidRecovery.start()                 (FallenParts + watch เปิดก่อน ปลอดภัยสุด)
  → BuildOrchestrator:Run()              → pcall builder → markReady / markFailed
  → SpawnService.start({deferUntilReady=true})
        └─ waitReady(timeout)
              ├─ ready  → CharacterAutoLoads=true → loadDeferredCharacters
              └─ failed → ensureEmergencyFloor → CharacterAutoLoads=true → load (คนลงบน floor สำรอง ไม่ตกเหว)
```

ผลลัพธ์: **ไม่มีทางที่ตัวละครจะ spawn ก่อน floor พร้อม** และ **ทุก place ส่งสัญญาณ ready/failed เท่ากัน** → loop หายที่ต้นเหตุ

---

## 7. แผน Migration (แบบไม่พังของเดิม)

1. **เพิ่มไฟล์ใหม่ 4 ตัว** (orchestrator, types, spawn, void) — ยังไม่ wire เข้า boot
2. **แปลง builder ทีละตัว** ให้คืน `BuildResult` (เริ่ม Hub → ทดสอบ → ที่เหลือ)
3. **สลับ `GameBootstrap`** ไปใช้ orchestrator/spawn/void
4. **ลด `WorldStudioSpawnGuard` เป็น shim** แล้วค่อยลบเมื่อ require หมด
5. อัปเดต `default.project.json` + validate

แต่ละขั้น build playtest ผ่านได้ก่อนไปขั้นถัดไป (ไม่ big-bang)

---

## 8. Validation / Test Plan

| ตรวจ | วิธี |
|------|------|
| Rojo build ผ่าน | `rojo build default.project.json -o ~/Desktop/utopia-playtest.rbxlx` |
| Place guard ยังถูก | `python3 scripts/validate-world-place-guard.py` |
| ทุก place ยิง ready | playtest แต่ละ `SimulatePlaceKey` (Hub/Solhaven/Nocturne/EternityCity/DeathValley) → log `markReady` ครบ |
| ไม่มี void loop | spawn แล้ว Y > -20 ภายใน 1 รอบ teleport, ไม่มี teleport ซ้ำเกิน 1 ครั้งตอนปกติ |
| Build fail → กู้ได้ | จงใจ throw ใน builder หนึ่ง → ต้องลง emergency floor ไม่ใช่ตกเหว |

---

## 9. ความเสี่ยง & Rollback

- **เสี่ยง:** require chain เดิมที่อ้าง `WorldStudioSpawnGuard` โดยตรง → กันด้วย shim (ข้อ 7.4) ก่อนลบ
- **เสี่ยง:** behavior ต่างระหว่าง Studio กับ cloud → gate ด้วย `Config` ค่าเดียว ทดสอบทั้งสองโหมด
- **Rollback:** ทุกขั้นเป็น commit แยก; ย้อน `GameBootstrap` กลับ 3 บรรทัดเดิมได้ทันที (orchestrator เป็น additive)

---

## 10. นอก Scope (เฟสถัดไป — ไม่ทำในงานนี้)

`DEV_GRANT_FREE`, `ProcessReceipt`, `DevGrantEternityItem`, `RemoteGuard`/`GriefingGuard` wiring, MemoryStore pcall — ตาม HANDOVER §3.2 / §9

---

*เอกสารนี้รออนุมัติก่อนเริ่ม implement ตามแผนข้อ 3 ของ project instructions*
