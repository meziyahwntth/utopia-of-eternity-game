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

## Landmark #7 Marina Showroom Strip — ตรวจรับผ่าน

- ไฟล์ใหม่ EternityCityMarinaShowroomLandmark.luau (~175 parts): โชว์รูมกระจก 3 หลัง +
  แท่นโชว์ + mock vehicle, pier railings + PierLamp ×16 + deck lines, ป้าย 1
- Playtest: `[LM7] pads=21 lamps=16 sign=1 white=1 shopPrompts=3` ✓
  (kiosk commerce 3 ร้านอยู่ครบ, nearwhite ยังเป็น 1 = SanctuaryCanopy)
- ⚠️ หมายเหตุ: VehiclePad attribute ติด 21 parts (validate ระบุ 4) — mock vehicle
  ทุกชิ้นถูกแท็กด้วย ยังไม่มี logic ใช้ attribute นี้จึงไม่กระทบ แต่ถ้าอนาคตทำระบบ
  spawn รถบนแท่น ต้อง dedupe ก่อน
- **Landmark ครบทั้ง 7 ตาม handover แล้ว** — ยังไม่ push

## Vehicle Showcase — ตรวจรับผ่าน

- LM7 push แล้ว (98ac242) · ShowroomVehicleDisplay.luau ใหม่ (224 บรรทัด):
  spawn รถโชว์ 3 รุ่นจาก VehicleMountCatalog (sports_car/big_bike/pickup_truck)
  บนแท่น VehiclePad (dedupe 21→3), BillboardGui ชื่อรุ่น, หมุน 0.3 rad/s,
  ViewInShopPrompt → OpenEternityShop (เช็ค canUseShop key 15+ ตามเดิม ไม่ bypass)
- Playtest: `[VSC] pads=3 models=3 prompts=3 white=1` + `[ROT] delta=0.3` ✓
- Commit 0484666 ค้าง local — ตรวจรับแล้ว push ได้ในรอบถัดไป
- ทิศทางใหม่จาก Praphan: เน้นวัยรุ่น/retention ตาม DESIGN-RESEARCH-TEEN-RETENTION.md
  เริ่ม Summer Music Festival เฟส 1 (เวที+countdown+photo zone)

## Summer Festival เฟส 1 "Eternity Soundwave" — ตรวจรับผ่าน

- ไฟล์ใหม่: EternityCityFestivalStage (เวที 32×20 + LED wall 12 + speaker 4 + laser 6 ต้น),
  EternityCityPhotoZones (ring/wing/arch ×3), FestivalCountdownService + client countdown
- GameConfig: season SummerFestival (15 มิ.ย. – 31 ส.ค. 2026) + festival lighting save/revert
- Playtest: `[FES] led=12 spk=4 laser=12 photo=3 signs=2 tgt=true white=1` +
  `[LAS] LaserBeam delta=0.4` (เสา static ตามดีไซน์) ✓
- Commit 22e6084 ค้าง local — ตรวจรับแล้ว push ได้รอบถัดไป
- แผนต่อ (DESIGN-RESEARCH): เฟส 2 daily streak + quest board → fashion show →
  mount trading → Eternity Pass

## เฟส 2 Daily Streak + Quest Board — ตรวจรับผ่าน (รอบแก้ remotes)

- รอบแรก FAIL: remote 5 ตัวไม่ถูกสร้าง (SecurityRemoteBootstrap WaitForChild("Remotes")
  ไม่มี timeout + boot order ไม่การันตี → infinite yield ทั้ง UI)
- Fix 579273b: FindFirstChild + Instance.new idempotent ตาม pattern RemoteGuard
- Playtest: `[P2F] remotes=5/5 quests=3 streak=1` + countdown client loop ✓
- ระบบที่ได้: streak 7 วัน (5→30 shards + title), quest board 3/วัน จาก pool 8
  (track server-side ทั้งหมด), claim ผ่าน RemoteGuard rate-limit
- **11 มิ.ย.: Praphan Save Limited & Public สำเร็จ — ข้อห้าม publish ยกเลิกทั้งหมด**
  (ดู CURSOR-PROMPT-P2-CLOUD-HANDOFF.md) — ถัดไป: push 2 commits + publish + cloud test

## 2026-06-11 — Cloud-test EternityCity v2 (PASS)

- Publish fix (Cursor 27f7c30): rojo build + Open Cloud API POST แทน rojo upload; key ใหม่ universe-places:write
- เปิด place 94486544638073 จาก cloud: Asset Manager (list view) → double-click "Utopia of Eternity" → หน้าต่างใหม่ DataModel version=2
- Play ผล:
  - [CT2] streak=1 qb=1 cd=12 remotes=5 (ClaimQuestBonus,GetStreakInfo,GetQuestInfo,ClaimQuestReward,ClaimStreakReward)
  - [Q] quests=3 (GetQuestInfo round-trip จริง)
  - [CT4] showroom=34 display=7 (3× Model:DisplayVehicle) billboards=24
  - Daily Streak popup แสดงเอง + Claim สำเร็จ → "Day 1 streak: +5 Luminite"
  - FestivalCountdown client loop started
- Minor: nearwhite=3 — DomeShell (อนุญาต) + UtopiaShuttle.PrismTransitStop.Canopy + PrismHoverShuttle.ShuttleRoot (2 ชิ้นควร recolor รอบหน้า)
- Minor: [DeathValley] PlayerStore.load returned nil for PorscheUTP — skipping seed (Studio cloud context)
- DV cloud test: N/A — place DV ยังไม่ publish (นโยบาย: publish เฉพาะ EternityCity)

## 2026-06-11 — Fashion Show + shuttle recolor (961f2f3) — PASS

- Solo playtest TestMode: Round 25 วิ่งครบ Registration→Dressing→Runway→Voting→Results (ไม่ cancel หลัง Join)
- Round ที่ไม่มีคน join: cancelled 0/1 players ถูกต้อง วน Idle→Registration ต่อเนื่อง (Round 1→28)
- [FS] Registration 28 stage=true remotes=4/4 lum=3 (participant reward) title=nil (solo ไม่มีโหวต — ตามดีไซน์) nw=1 DomeShell
- Shuttle recolor ผ่าน: nearwhite เหลือ DomeShell ชิ้นเดียว
- Minor (แจ้ง Cursor รอบหน้า): UI countdown แสดง "0s left" ค้างบ่อย (อัปเดตเฉพาะตอนเปลี่ยน state?) — Round 24 เคยแสดง 7s ถูกต้อง
- หมายเหตุ env: Chrome แย่ง frontmost เป็นพักๆ ระหว่าง playtest (น่าจะจาก deeplink handler) — แก้โดย minimize start page window แล้วคลิกหน้าต่าง playtest ตรงๆ

## 2026-06-11 — Heightmap Importer test (place ใหม่) — PASS

ทดสอบ import `assets/terrain/eternitycity-heightmap-v1.png` + colormap (1024×1024 16-bit) ใน place เปล่า
Size 2048×256×2048, Position default (0,0,0)

**ผล:** terrain ครบทุกองค์ประกอบ — city plateau วงกลมเรียบ, อ่าวทะเล, คลองเชื่อม plateau→อ่าว, beach ring, แนวภูเขาขอบแมพ

**ข้อค้นพบสำคัญ (สำหรับรอบ production):**
1. Importer **ไม่เติมน้ำ** — ต้อง `Terrain:ReplaceMaterial(region, 4, Air, Water)` ใต้ sea level เอง (ทดสอบแล้วเวิร์ค)
2. ภาพถูก **flip แกนตั้ง** ตอน import — อ่าวออกแบบไว้ SE ไปโผล่ NW → ต้อง flip PNG ตอน generate (v2)
3. Position Y=0 → terrain กิน -128..+128 → **Baseplate บังเกือบหมด** — production ควรตั้ง Position Y=128 ให้ terrain อยู่ 0..256
4. Colormap จับคู่ material ได้ (grass/rock ตรง) แต่ concrete plateau ออกขาว — ปรับสี colormap ให้ใกล้ material จริงขึ้น
5. ดู terrain ใน Studio: ลบ Atmosphere + FogEnd=100000 ก่อน ไม่งั้นหมอกบังหมด
6. Place ทดสอบ ไม่ save

Gen script เก็บเข้า repo แล้ว: `scripts/gen-eternity-terrain.py`

## 2026-06-11 — Publish v3 + Terrain v2 acceptance — PASS

**Publish:** EternityCity 94486544638073 → **v3** (HTTP 200, build จาก 9f9ac9a)
- แก้ publish-place.sh 2 จุด: `set -a` ครอบ source .env (python subprocess ไม่เห็น key เพราะไม่ export — root cause "KEY missing" ทั้งที่ key อยู่ครบ) + mktemp macOS ไม่รองรับ suffix หลัง XXXXXX

**Terrain v2 acceptance (local, utopia-playtest.rbxlx จาก 9f9ac9a):**
- Import: Size 2048×256×2048, Position (0,128,0) — heightmap+colormap v2
- `[T2] plateau nonair=9` ที่ PlateauCenterStud (-104,72,82) ✓
- `[A1] bayWater=4186` ที่ BayCenterStud (696,53,-578) ✓ — fillWater อัตโนมัติจาก prepareForBuild, orientation v2 ตรง design แล้ว
- `layout=imported-v2` ✓ builder ข้าม greybox ground/coast/mountains
- Fashion Stage snap (-234,70,197) บน plateau ✓
- `[A2] nearwhite=0` ✓ (ดีกว่า spec ≤1)
- Countdown ticking: Registration 7s→3s→Idle 4s ✓ ทุกวินาที
- Minor (ไม่ block): บางจังหวะหลัง state transition ขึ้น "0s left" สั้นๆ ก่อน poll 10s รอบใหม่ sync — เด่นเฉพาะ TestMode ที่ state สั้น (5s) กว่า poll
- Sentinel จับ speed exploit จากการพิมพ์ WASD ลง viewport — security ทำงานปกติ
- Terrain v2 save ลง utopia-playtest.rbxlx แล้ว (save ก่อน Play)

**ค้าง:** publish terrain ขึ้น cloud ต้อง Save place ที่มี terrain (rbxlx build จาก rojo ไม่มี terrain — ต้อง import ใน Studio แล้ว Publish to Roblox As หรือใช้ rbxlx ที่ save แล้ว POST เอง — รอผู้ใช้ตัดสิน)

## 2026-06-11 — Art pass v3 acceptance (fc3859f) — PASS

**Heightmap v3 สัดส่วน (วัดอิสระโดย Cowork):** sea 17.6% · land 82.4% · ที่ราบ 68-76 = 60.4% · mount 6.0%
— แก้ปัญหา "ทะเลเยอะเกินครึ่ง" ตามผู้ใช้สั่ง (v2: sea 38% + beach 28%)

**Acceptance (local, build fc3859f + terrain v3 import Pos Y=128):**
- `[T3] plateau nonair=18` ที่ PlateauCenterStud ใหม่ (-64,72,62) ✓
- `[B1] bayWater=4784` ที่ BayCenterStud ใหม่ (856,53,-818) ✓ fillWater อัตโนมัติ
- Fashion Stage snap (-194,70,177) ตาม TerrainProfile ใหม่ ✓
- nearwhite=0 ✓
- Countdown: ค่าแม่นทันทีหลัง state เปลี่ยน (10s→…) ticking ทุกวินาที ไม่มี "0s left" ค้าง ✓ (fix AttributeChangedSignal ทำงาน)
- Pearl & Gold มองเห็นจริง: spires เป็น pearl-white + cyan glow (เดิม silhouette ดำ), stage marble+gold trim ✓
- Terrain v3 save ลง utopia-playtest.rbxlx แล้ว

**หมายเหตุ (minor, ไม่ block):**
1. attribute `TerrainLayout` ยังรายงานสตริง "imported-v2" ทั้งที่เป็น v3 — แค่ label, ฝากแก้รอบหน้า
2. แสง PointLight ที่ Fashion Stage จ้าจัด ภาพ wash เป็นขาวทอง — ฝากลด intensity รอบจูนถัดไป

**สถานะ publish:** terrain ยัง local ตามคำสั่งผู้ใช้ — cloud = v3 (9f9ac9a code) ยังไม่มี terrain/art pass (fc3859f ยังไม่ publish)

## 11 มิ.ย. 2026 — UtopiaPlaza + EternityTower acceptance PASS (FIX-4)

- Hero mesh pipeline: Meshy Image-to-3D → decimate local → MeshId `103489658289034` (UtopiaPlaza, ×15) / `110883199256677` (EternityTower, ×60)
- Debug 4 รอบ: (1) wiring ขาด → (2) augment ผิด branch/hydrate timing → (3) MeshId เขียนรันไทม์ไม่ได้ → CreateMeshPartAsync + pcall isolation + budget 18,500 → (4) ScaleTo ใช้กับ MeshPart ไม่ได้ → Size=MeshSize×Scale + แยกอาคาร procedural ออกจาก mesh step
- ผลรัน (Studio Run): UtopiaPlaza 3,048 parts · EternityTower 223 parts · HeroMeshActive="UtopiaPlaza,EternityTower" · hero mesh ×2 ปรากฏ · SpawnService ready=true · ไม่มี CONTRACT_FAIL
- โครงสร้าง: UP escalator=8, lift=6, skylight=1, LEVEL signs=40 · ET stage=11, helipad=10, helicopter=1, glass rail=8
- ค้าง: เดิน playtest จริง (ลิฟท์ tween, บันไดเลื่อน collision) ตอน cloud-test · terrain v3 ต้อง re-import ก่อน publish รอบเดียว
- Meshy pipeline อัตโนมัติพร้อม: scripts/meshy-hero-mesh.py + MESHY_API_KEY ใน bridge/.env (วางโดยผู้ใช้)

## 11 มิ.ย. 2026 (กลางคืน) — Walkability pass + Terrain v3 + Publish v4 ✅

- แก้ walkability เอง (user อนุมัติข้าม Cursor): lift Heartbeat rider-follow, escalator span แก้หลุดตึก, ramp เจาะช่องพื้น (quadrant holes), บันได hotel switchback ต่อ corridor, ET floor plate เจาะช่องบันได/บันไดเลื่อน, เวที/audience/helipad จัดตำแหน่งใหม่ — commit 45e047e
- เดินทดสอบจริงผ่านหมด: UP escalator y=92, lift 74↔214 (พา player), hotel F6 y=156, ET stairs+escalator y=92, concert deck 142, helipad 141 + helicopter
- Terrain v3 re-import ใน Studio: heightmap+colormap v3, CELLS=4,294,468, ใต้เมือง flat y=69, MAXY 171 → Save to File
- Publish ผ่าน Open Cloud API ด้วยไฟล์ที่เซฟ (มี terrain — ไม่ใช้ rojo build ที่ทับ terrain): `utopia-publish-eternitycity.command` → HTTP 200, placeId=94486544638073, **versionNumber=4**, log ใน PUBLISH-ETERNITYCITY-LOG.txt
- งานถัดไป: Landmark #4 Sky Rail Plaza (ใช้ meshy-hero-mesh.py), recolor Shuttle canopy, DV combat loop

## 12 มิ.ย. 2026 — Backlog 3 งาน + Publish v5 ✅

- **Shuttle recolor**: ตรวจพบทำเสร็จแล้วตั้งแต่ 961f2f3 (nearwhite=0 ใน v3 acceptance) — backlog stale ปิดได้เลย
- **DV combat loop** (commit ก่อน publish): config Combat (BaseDamage 20, range 16, cooldown 0.45s, shards Whisper 2/Stalker 3/LegionEcho 8) · WraithFactory: applyDamage/findNearestActive/setOnKilled (hit flash + ตายแล้วลบจาก active ทันที → wave จบเร็วผ่าน getActiveCount()==0 เดิม) · DeathValleyCombatService (server-authoritative, no-P2W) · remotes AttackWraith/WraithKilled + rate limit 12/6s · CombatHUD client: ปุ่ม F bind เฉพาะช่วง wave (กัน conflict DungeonZone1HUD), toast +shards, mobile ContextActionService
  - Playtest จริง (SimulatePlaceKey=DeathValley in-memory): ATK1 "Hit — 20 HP left" → cooldown block → ATK3 "Wraith destroyed! +2 shards" → shards 30→32, kills=1, HUD "Wraith Wave (2)" อัปเดต, NIGHT_SURVIVED=1 ✓
  - หมายเหตุ: wave ไม่ spawn ถ้า Beacon Fuel=0 (Breach loop) — เติมผ่าน DepositBeaconFuel ก่อนทดสอบ; fuel drain เร็ว (~2/s?) ควรรีวิวภายหลัง
- **Landmark #4 Sky Rail Plaza hero mesh**: ภาพ concept จากผู้ใช้ → Meshy ผ่าน utopia-meshy-skyrailplaza.command (Mac-side, สคริปต์ meshy-hero-mesh.py, gen 100% + download 32MB) → decimate ใน sandbox: ต้อง merge_vertices ก่อน (Meshy OBJ เป็น triangle soup 2.85 v/f, ไม่งั้น cull พังเหลือ 20 faces) + cull แบบ relative → 17,745 faces, 1 component, area 99.9% → SkyRailPlaza-18k.obj → 3D Importer upload → **rbxassetid://106585159616794** → GameConfig.HeroMeshes (Scale 55 → 105×27×28) + attach 2 จุด (fresh-build หลัง buildSkyRailPlaza + augment ใน ensureHeroLandmarks) — สคริปต์ patch แล้ว
  - Playtest: SRP_MESH=true (104.6×27×28.2) + UP/ET mesh ครบ, SpawnService ready ✓
- **Publish**: terrain v3 re-import (CELLS 4,294,468) → Save to File (2.88MB) → POST ผ่าน utopia-publish-eternitycity.command → **HTTP 200, versionNumber=5**
- command bar ใต้ dock ใช้ไม่ได้ → ลาก handle ⋮ ให้ลอย แล้วใช้ triple_click+cmd+a+type+คลิก Run ของ bar ลอย
