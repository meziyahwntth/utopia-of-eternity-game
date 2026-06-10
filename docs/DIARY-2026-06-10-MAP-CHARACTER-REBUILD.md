# DIARY — Map/Character Rebuild Implementation (10 มิ.ย. 2026)

**Agent:** Claude Cowork · **อ้างอิง:** docs/MAP-CHARACTER-REBUILD-BLUEPRINT.md (อนุมัติแล้ว)
**สถานะ:** ✅ ครบ 5 component + playtest ผ่าน (EternityCity, PlaceId=0)

## สิ่งที่ทำ

### ไฟล์ใหม่ (4) — `src/ServerScriptService/World/`
| ไฟล์ | บทบาท |
|------|-------|
| `WorldBuilderTypes.luau` | `BuildResult`/`BuildContext` + helper `success/skip/fail` |
| `BuildOrchestrator.luau` | จุดเดียวห่อ pcall + set WorldBuildState; idempotent; normalize legacy builder (คืน nil = success ถ้า state ยัง pending, เคารพ state ที่ legacy set เอง) |
| `SpawnService.luau` | always-on spawn gate; รอ waitReady(GameConfig.WorldBuild.ReadyTimeoutSeconds=60) → **CharacterAutoLoads=true เสมอ** → loadDeferredCharacters; failed/timeout → emergency floor ก่อนปล่อย; มี respawnPlayer ให้ shim |
| `VoidRecovery.luau` | เจ้าของ FallenPartsDestroyHeight + Heartbeat watch (0.35s, Y<-80); recover() ไม่ block ยาว; characterLocks กัน re-entrancy |

### ไฟล์ที่แก้
- `GameBootstrap.server.luau` — เขียนใหม่ตาม Blueprint §6: defer spawn ทันที → Bridge → VoidRecovery → BuildOrchestrator:Run() → SpawnService.start(); **ตัด IsStudio() gating ทั้งหมด**
- `*WorldBuilder.luau` ×5 — pure builder คืน BuildResult; EternityCity ถอด pcall+markReady/markFailed ออก (ย้ายขึ้น orchestrator)
- `WorldBootstrap.luau` — expose `BUILDERS`; `BuildCurrent()` = wrapper เรียก orchestrator (lazy require กัน cycle)
- `WorldStudioSpawnGuard.luau` — เหลือ shim re-export (ผู้ใช้ที่เหลือ: DeathValleyReviveService.respawnPlayer)
- `GameConfig.luau` — เพิ่ม `WorldBuild.ReadyTimeoutSeconds = 60`
- `default.project.json` — ลงทะเบียน 4 ไฟล์ใหม่

### บั๊กที่เจอและแก้ระหว่าง playtest
1. **`EternityCitySkyRailPlazaLandmark:190`** — `CFrame.new(platform.CFrame * CFrame.new(...))` ห่อ CFrame ซ้ำ → throw ตอน build (orchestrator จับได้รอบแรกทันที — เดิม bug นี้ทำให้ city build ล้มแบบเงียบ) แก้โดยถอด wrapper; grep ทั้ง src ไม่มี pattern นี้ที่อื่น
2. **Character ไม่ spawn เลย** (ยืนยันจาก playtest: Character=nil หลัง 100s) — GameBootstrap เดิมเรียก loadDeferredCharacters ตอน boot ก่อนผู้เล่น join และไม่เคยคืน `CharacterAutoLoads=true` → root cause C ตาม Blueprint; แก้ด้วย SpawnService

### ผล playtest สุดท้าย (rbxlx จาก rojo build, SimulatePlaceKey=EternityCity)
```
[Utopia] Eternity City built — aurora · marina · canal · gates · Sky Lounge 50 · loadout plaza
[BuildOrchestrator] EternityCity → ready (skipped=false)
[SpawnService] characters released — ready= true
[CHECK3] PorscheUTP -121.9, 4.49, 117.2   ← ตัวละครยืนบนพื้น ไม่มี void loop
```
Error ที่เหลือ = MemoryStore "must publish" (ปกติใน local playtest — blocker คนละเฟส ตาม HANDOVER §3.2)

## Session ต่อ (10 มิ.ย. 2026 — รอบสอง)

### Playtest ครบทั้ง 5 place ✅
เทคนิค: แก้ `SimulatePlaceKey` ใน GameConfig.Source ผ่าน command bar (in-memory, ไม่แตะดิสก์) → Play ในหน้าต่างเดียว ไม่ต้อง rebuild
| Place | Orchestrator | Spawn Y |
|-------|--------------|---------|
| EternityCity | ready ✓ | 4.50 ✓ |
| Hub | ready ✓ | 4.50 ✓ |
| Solhaven | ready ✓ | 4.50 ✓ |
| Nocturne | ready ✓ | 4.50 ✓ |
| DeathValley | ready ✓ | 4.49 ✓ |

### Phase A Security — ตรวจสอบ + ปิดช่องโหว่ที่เหลือ ✅
ยืนยันจากโค้ดจริง + playtest log ว่างานตาม HANDOVER §3.2 ถูกทำไปแล้วเกือบหมด (เซสชัน 9 มิ.ย.):
- `DEV_GRANT_FREE = false` ทั้ง 2 ไฟล์ + `ENABLE_DEV_GRANT = false` ✓ (อ่านโค้ดยืนยัน)
- `SecurityRemoteBootstrap.server.luau` wire RemoteGuard:Register + GriefingGuard hooks ✓ อยู่ใน project.json ✓ รันจริง (log: "RemoteGuard: HealChannelComplete_Guarded + CoOpSabotageReport registered" + "GriefingGuard: sanctuary + PvP hooks online")
- MemoryStore: init ทุกไฟล์ (5 ไฟล์/7 จุด) ห่อ pcall แล้ว + จุดใช้งานห่อ pcall ทุกจุด ✓

**บั๊กที่เจอใหม่และแก้:** `DungeonZoneRuntime.getRuntime` ไม่มีอยู่จริง — heal handler ใน SecurityRemoteBootstrap เป็น dead code เงียบ → เพิ่ม registry (`create()` ลงทะเบียน zoneId→runtime) + `getRuntime(zoneId)` แบบ additive
**ยังไม่ได้ทดสอบ runtime:** heal handler ต้องเล่นถึง dungeon zone — ตรวจ static แล้ว ต้อง rebuild rbxlx ก่อน playtest ครั้งหน้า

### Shim removal ✅ (Cursor ทำ, Cowork ตรวจรับ)
WorldStudioSpawnGuard.luau ถูกลบ + DeathValleyReviveService ใช้ SpawnService ตรง + project.json อัปเดต
ตรวจรับ: grep src ไม่เหลือ reference ✓, playtest build ใหม่: ready=true + spawn Y=4.99 ✓, ไม่มี error ✓
Workflow ใหม่: งานโค้ด → เขียน prompt ให้ Cursor, Cowork ทำเฉพาะ computer-use (ประหยัด usage limit)

### Heal handler test → เจอบั๊ก CRITICAL ของ Shield (10 มิ.ย. รอบสาม)
ทดสอบผ่านเส้นทางเกมจริง: SaveLoadout(CombatMedic+medic_supply) ✓ → EnterZone duo_depth ✓ → แต่ remote HealChannelComplete_Guarded **ไม่มีอยู่ใน ReplicatedStorage.Remotes** (folder ว่าง honeypots ก็หาย)
สืบจนพบ: **EvasionDetector:9 init DataStore ที่ top-level ไม่มี pcall** → ใน local playtest throw "must publish to access DataStore" → require chain ใน SecurityCore ตายที่บรรทัด 22 → RemoteGuard:Init/GriefingGuard:Init/HoneypotRemotes ไม่รันเลย = **Utopia Shield ดับทั้งระบบใน Studio** (และเป็น single point of failure บน prod)
บั๊กที่สอง: RemoteGuard:Register เงียบๆ ข้ามการสร้าง remote เมื่อถูกเรียกก่อน Init (race, ไม่ warn) — log "registered" จึงหลอกว่าสำเร็จ
→ ส่ง prompt ให้ Cursor แก้ (pcall pattern + audit Security/ ทั้งโฟลเดอร์ + ensureRemotesFolder ใน Register) — รอตรวจรับ

### ตรวจรับ Cursor fix + อ่าน [FINAL] (10 มิ.ย. รอบสี่ — Cowork ใหม่)

**[FINAL] ที่ Fable 5 รันไว้ก่อนส่งมอบ (05:51:04 ใน utopia-playtest.rbxlx บน Desktop root):**
```
save= true   enter= true   remote= true   honeypot= false   healCount= 0
```

**วิเคราะห์:**
- `remote= true` → HealChannelComplete_Guarded ถูกสร้าง (SecurityRemoteBootstrap + ensureRemotesFolder fix ทำงาน)
- `honeypot= false` → HoneypotRemotes:Deploy() ไม่รัน — SecurityCore ยังมี step ที่ throw แบบเงียบก่อนถึง line 76
- `healCount= 0` → heal handler รันแต่ return ก่อน increment; สาเหตุที่น่าจะเป็น:
  (a) `DungeonZoneRuntime.getRuntime` ไม่ใช่ฟังก์ชัน (build เก่า) → guard `getRuntime and ...` short-circuit → nil
  (b) หรือ runtime.zonePlayers[player.UserId] nil (player เข้า zone แต่ initContribution ไม่รัน)
- SecurityCore ทุก Init/Deploy ไม่มี pcall → crash เงียบ → Deploy ไม่รัน

**Action:** ส่ง prompt ใหม่ให้ Cursor (CURSOR-PROMPT-SECURITY-DIAGNOSE-FIX.md บน Desktop):
1. ครอบ pcall ทุก step ใน SecurityCore + print timestamp ระหว่างแต่ละ step
2. เพิ่ม warn log ใน heal handler ทุก early-return branch
3. รัน rojo build → output ไป `/Users/macbook/Desktop/utopia-playtest.rbxlx`
4. Pass criteria: `honeypot= true  healCount= 1` + `[SecurityCore] ALL STEPS COMPLETE`

### ผล Cursor + [FINAL2] ✅ (10 มิ.ย. รอบห้า)

**Root cause ที่ Cursor วินิจฉัยได้:**
`BanBroadcast:StartListening()` เรียก `MessagingService:SubscribeAsync` ซึ่ง yield ค้างบน local (unpublished) file → thread หยุดตลอดกาล → ไม่มีวันถึง `HoneypotRemotes:Deploy()` แม้ไม่มี error ใด ๆ (pcall กัน error ได้ แต่กัน yield ไม่ได้)

**Fix:** ห่อ `BanBroadcast:StartListening()` ใน `task.spawn` ใน SecurityCore — boot thread ไม่ block, รัน Deploy ต่อไปได้

**ผล [FINAL2]:** `save= true  enter= true  remote= true  honeypot= true  healCount= 1` ✅

**เพิ่มเติมจาก pcall diagnostic:**
- `BackdoorScanner:Scan()` — `Script.Source` ต้องการ PluginOrOpenCloud capability → fail ทุก runtime (Studio + production) ไม่ใช่แค่ Studio local; ถูก pcall จับแล้ว ไม่ตาย แต่ scan ไม่ทำงาน → ควรย้ายเป็น CI check ในรอบถัดไป
- `DeathValleyLoadoutHandlers:424` — `attempt to index nil with 'creatorBalance'` (DataStore nil ใน Studio) → บันทึกเป็น task #16 แก้รอบต่อไป

**ไฟล์ที่ Cursor แก้:**
- `src/ServerScriptService/SecurityCore.server.luau` — helper `runStep(label, fn)` + ครอบทุก 17 step + `task.spawn` สำหรับ `BanBroadcast:StartListening`
- `src/ServerScriptService/SecurityRemoteBootstrap.server.luau` — heal handler diagnostic logs ทุก branch

## งานที่เหลือ
- GitHub push: สร้าง repo `meziyahwntth/utopia-of-eternity-game` (Public) แล้ว push (task #15)
- แก้ DeathValleyLoadoutHandlers nil creatorBalance (task #16)
- BackdoorScanner → พิจารณาย้ายเป็น CI check (ไม่เร่งด่วน)

## นโยบายที่ถือตาม
ไม่ publish / ไม่แตะ Roblox website · ไม่แตะ economy/security blockers · Strict Truth Mode (อ่านโค้ดจริงก่อนแก้ทุกไฟล์ · ยืนยันทุกอย่างด้วย playtest log)

### Landmark #4 Sky Rail Plaza ✅ (Cursor ทำ, Fable ตรวจรับ 10 มิ.ย.)
hasStatic() hybrid skip ใน 8 landmark + SkyRailPlazaLandmark full (317 บรรทัด ~300 parts)
VALIDATE-LANDMARK4.txt: RESULT PASS · playtest: pad=1 trim=4 prompts=2 stops=2 spawnY=4 ✓
ถัดไป: Landmark #5 Aurora Mega Mall → #6 Twilight Overpass → Death Valley content

### Landmark #5 Aurora Mega Mall ✅ (Cursor ทำ, Fable ตรวจรับ)
502 บรรทัด ~400-500 parts · VALIDATE-LANDMARK5.txt: PASS
Playtest: floors=5 ramps=4 lounge=1 sofas=6 mirror=1 key25=1 spawnY=4 ✓
ถัดไป: Landmark #6 Twilight Overpass

### Landmark #6 Twilight Overpass ✅ (Cursor ทำ, Fable ตรวจรับ)
VALIDATE-LANDMARK6.txt: PASS · playtest: deck=1 ramps=2 arches=5 keystones=5 stage=1 spawnY=4 ✓
**Eternity City landmarks ครบ 1-6 แล้ว** (+#7 Marina Showroom มีอยู่เดิม)
ถัดไป: Death Valley content (Spirit Chamber, Peak Colony, Military Base, POI/Zone art pass)

### DV Spirit Chamber ✅ (Cursor ทำ, Fable ตรวจรับ)
VALIDATE-DV-SPIRIT.txt: PASS · playtest DeathValley (in-memory SimulatePlaceKey):
chambers=3 spawns=15 gates=6 boss=1 spawnY=4 ✓ ตรง spec ทุกค่า
ถัดไป: Peak Colony → Military Research Base → POI/Zone art pass

### DV Peak Colony ✅ (Cursor ทำ, Fable ตรวจรับ)
VALIDATE-DV-PEAK.txt: PASS · playtest: kids=47 domes=2 pad=1 shuttle=1 spawnY=3 ✓
ถัดไป: Military Research Base → POI art pass → Zone 2-5 art pass

### DV Military Base ✅ (Cursor ทำ 2 รอบ, Fable ตรวจรับ)
รอบแรกไม่ผ่าน: rooms=0 (buildRoom define หลัง caller — forward-reference nil) +
ReviveService:49 spam (isDeathValleyPlace define หลังจุดเรียก — หลงมาจาก shim removal)
รอบสอง: gates=2 stations=5 lfg=1 rooms=2 spawnY=4 + ReviveService error=0 ✓
DV content เหลือ: POI art pass (Whispering Grove, Hollow Lake) + Zone 2-5 art pass

## DV POI Art Pass — ตรวจรับผ่าน (รอบแก้)

- รอบแรก FAIL 2 ชั้น: (1) Studio เปิดไฟล์เก่า (spawnY=71 หลอน) — เปิดไฟล์ใหม่แก้ได้
  (2) build ตายกลาง buildWhisperingGrove: `Enum.Material.Foliage` ไม่มีจริงใน Roblox
  → throw ตอน canopy ตัวแรก, orchestrator pcall กลบเป็น warning (trunks=1 whispers=0)
- Cursor แก้ → LeafyGrass + เพิ่ม diagnostic print หน้า sub-builder ทุกตัว (VALIDATE-FIX-DV-POI.txt PASS)
- Playtest ยืนยัน: `[POI] trunks=10 whispers=5 scares=2 shadows=2 signs=2` ✓
- หมายเหตุ in-memory switch: SimulatePlaceKey อยู่ใน **GameConfig.luau** (ไม่ใช่ WorldBuildConfig)
- บั๊กเดิมพบใหม่ (ไม่บล็อก POI): SanctuarySpawn_1 (-33,1,-59) อยู่ใต้ขอบ terrain FillBlock
  (top y=70) → ผู้เล่น spawn บนยอดเขา y=72 — ควรย้าย spawn หรือเลื่อน FillBlock รอบหน้า

## DV Zone 2-5 + WeeklyBossArena Art Pass — ตรวจรับผ่าน

- Cursor ทำ art pass: กำแพง arena ตามธีม 4 โซน, boss platform + torch, เสาประตู + ป้าย,
  ขอบ WeeklyBossArena (+204 parts, ~1,809/7,000 MaxParts) — VALIDATE-DV-ZONES.txt PASS
- Cursor ดักบั๊กเองก่อน build: `Enum.Material.Basalt` ไม่ใช่ Material enum → Slate
- Playtest ยืนยัน: `[ZONES] torch=24 signs=4 weekly=4 pads=4 arenas=5 wba=1` ✓
  (arenas=5 เพราะ Zone1Builder:116 มี BossArena เดิม — ไม่ใช่ของรอบนี้)
- คิวงาน art pass จาก HANDOVER-TO-FABLE5.md **ครบทั้งหมดแล้ว**
- งานค้างถัดไป: แก้ SanctuarySpawn_1 ใต้ terrain mountain (spawn บนยอดเขา y=72),
  BackdoorScanner → CI, push งานสะสม

## Fix DV SanctuarySpawn_2 ใต้ terrain mountain — ตรวจรับผ่าน

- Root cause: วง spawn 72 studs (DefaultRadiusStuds 120 × 0.6) ทำ spawn_2 (−36,1,−62.4)
  จมใน terrain FillBlock z[−100,−60] → player ถูกดันขึ้นยอดเขา y=72
- Fix (Cursor): หดวง spawn เฉพาะ DV → addSanctuarySpawns(model,3,90,budget) = วง 54 studs
  (1 บรรทัด, ไม่แตะ WorldBuildShared/place อื่น/terrain) — VALIDATE-FIX-DV-SPAWN.txt PASS
- Playtest: spawns (−27,1,−47)/(−27,1,46)/(54,1,−1) + playerY=4 ✓ (เดิม 72)
- หมายเหตุ: push แล้ว 2 commits ก่อนหน้า (2ae4813 POI, 321a96d Zones) — fix นี้ยังไม่ push

## BackdoorScanner → CI + push — ตรวจรับผ่าน

- Cursor ลบ BackdoorScanner.luau (dead code — Script.Source อ่านไม่ได้ใน live game)
  + ตัด require/runStep ใน SecurityCore + ตัด entry ใน default.project.json
- เพิ่ม CI step "Backdoor pattern scan" ใน job security-scan (word-boundary regex,
  ข้าม comment lines, scan ปัจจุบัน = 0 hits) — VALIDATE-BACKDOOR-CI.txt PASS
- Push แล้ว: 1f4ea0b (spawn fix) + 1d38f42 (CI) → origin/main, working tree clean
- Playtest ยืนยัน: [SecurityCore] ALL STEPS COMPLETE — Shield online ✓ (boot ไม่พังหลังลบ)
- บทเรียน: command bar ใน play mode = Client context → มองไม่เห็น ServerScriptService
  เช็คของฝั่ง server ให้ดูจาก server log prints แทน

## Eternity City Recolor — แก้ขาวโพลน — ตรวจรับผ่าน (3 รอบ)

- ปัญหาจาก Praphan: เมืองขาวโพลนแยกอาคารไม่ออก
- รอบ 1: เพิ่ม Steel/Slate/Midnight/Teal + แก้ Brightness 2.2→1.2 + atmosphere — เหลือ 247 ขาว
  (audit grep แค่ `profile.Palette.Pearl` หลุด alias `palette.Pearl` ใน landmark ทั้ง 6 ไฟล์)
- รอบ 2: ไล่ตามลิสต์ [WHITE2] ครบ — เหลือ 72 (ArchRibKit ใน ServerStorage/WorldKits นอก scope)
- รอบ 3: ส่ง palette Steel/Slate จาก AuroraSpireLandmark → CreateAll (fallback กลางคงไว้ให้
  Hub/Solhaven/Nocturne) — playtest: `[WHITE4] nearwhite=1 (DomeShell/SanctuaryCanopy ข้อยกเว้น)`
- บทเรียน audit สี: ห้าม scope แค่ World/ — kit ใน ServerStorage ก็สร้าง part ใต้เมืองได้
- ยังไม่ push (recolor 3 รอบค้างใน working tree)
