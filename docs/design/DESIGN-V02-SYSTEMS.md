# Design Volume 02 — Systems (Utopia of Eternity)

**Version:** 0.2 · **Date:** 8 มิถุนายน 2026  
**Companion:** `GDD-UTOPIA-OF-ETERNITY.md` · `IP-AUDIT-UTOPIA-OF-ETERNITY.md`

---

## I. Security — Category I: Griefing & Economy (implemented in Luau)

### I.1 สิ่งที่ผู้เล่น Roblox บ่น (จากสื่อ/ชุมชน)

| ปัญหา | แหล่ง | แนวทาง Utopia |
|-------|-------|----------------|
| Economy inflation / duping / alt farms | Grow a Garden Discord/Reddit, trade dupe articles | `EconomyInflationGuard` — velocity cap, dump detection, circuit breaker |
| Griefing ใน co-op horror | 99 Nights — ทำลาย base, ออกกลางเกม, difficulty ไม่ลด | `GriefingGuard` + หุบเขามรณะ `DifficultyDownscaleOnLeave` |
| Random match toxic | 99 Nights wiki / guides | **Friends-only default** + Roblox Party API |
| PvP spawn kill | เกม open world ทั่วไป | Sanctuary 120–280 stud + `PVP_ARENA` แยกโซน |

### I.2 โมดูลที่ implement แล้ว

| Module | หน้าที่ |
|--------|---------|
| `GriefingGuard` | Sanctuary violation, PvP same-victim spam, หุบเขามรณะ co-op sabotage, trade grief |
| `EconomyInflationGuard` | Single delta cap, velocity window, dump pattern, circuit break per item |
| `SevereOffenseGate` | Honeypot / executor / server flood → **แบนถาวรทันที** |
| `EmulatorDetector` | Multi-account cluster → device block 7 วัน (ครั้ง 1) / ถาวร (ครั้ง 2) |
| `LogExportBridge` | ส่ง batch log ไป Bridge API สำหรับ AI offline analysis |

> **หมายเหตุ IP ban:** Roblox Luau **ไม่มี raw IP** — ใช้ `ApplyDeviceBlock` + `ExcludeAltAccounts` แทน (เทียบเท่าใน platform)

### I.3 โทษ (Sentinel ladder)

| ระดับ | พฤติกรรม | โทษ |
|-------|----------|-----|
| Mild | Schema fail, minor grief | Warn + suspicion |
| Moderate | PvP grief, economy velocity | Temp ban 7 วัน |
| Severe | Honeypot, executor, flood, malicious | **Permanent ban + device block** |
| Emulator alt farm | Strike 1 / 2 | Device 7 วัน / **ถาวร** |

---

## II. Social & Friends — เล่นกับเพื่อน

### II.1 Roblox Party (platform)
- รองรับ Roblox **Party API** (2025) — เพื่อน 6 คน join instance เดียว
- ปุ่ม **"เล่นกับเพื่อน"** ใน Hub → สร้าง private shard / follow friend

### II.2 In-game Party (หุบเขามรณะ + co-op)
- Party 4 คน · **Friends-only default** (เปิด public ได้ใน settings)
- Invite ผ่าน Roblox friend list + in-game code ชั่วคราว
- **Difficulty scales with party size** แต่ **ลดเมื่อมีคนออก** (ต่างจาก 99 Nights)

### II.3 Sanctuary = Social hub (ขยายทุกเมือง)

| เมือง | รัศมี (stud) | Spawn points | สิ่งอำนวยความ |
|-------|-------------|--------------|----------------|
| Hub | 120 | 3+ | Museum, teleport, dance floor |
| Solhaven | 120 | 3+ | Trade post, garden gate |
| Nocturne | 120 | 3+ | Clue board, cipher kiosk |
| Utopia of Eternity | **280** | **8+** | Monorail, photo booth, fashion |
| หุบเขามรณะ | 120 | 3+ | จุดไฟชีวิต, co-op queue |

ทุก Sanctuary: **No PvP · No horror spawn · NPC ผู้ช่วย · ร้านค้า · emote zone**

---

## III. หุบเขามรณะ — Co-op Horror (เรียนรู้จาก 99 Nights)

### III.1 Pain points จากชุมชน 99 Nights
1. เพื่อน random ทำลาย base / ขโมยของ  
2. คนออกกลางเกม → difficulty ไม่ลด → รอดไม่ได้  
3. ยากหา teammate ที่ไว้ใจได้  

### III.2 การออกแบบ หุบเขามรณะ ของเรา

| ฟีเจอร์ | รายละเอียด |
|---------|------------|
| **Friends-first** | Default friends-only instance |
| **Shared Beacon** | ไฟร่วม — ทุกคนช่วยเติม fuel |
| **Dynamic difficulty** | Scale ตาม party size · **downscale เมื่อ disconnect** |
| **No base grief** | ไม่มี player-placed base ที่ทำลายได้ — ใช้ จุดไฟชีวิต แทน |
| **Role ping** | Scout / Keeper / Rescuer / Guard (ไม่บังคับ class แต่ buff เล็กน้อยเมื่อร่วม role) |
| **Night Survived** | Meta progress — ไม่ hard fail ทั้ง party ถ้า 1 คนตาย (revive ที่ Beacon) |

**Phase A (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-A-SURVIVAL.md` — Beacon Lv1–3, prep/wave loop, Whisper/Stalker/Legion Echo wraiths, revive, exit portal, horror FX opt-out

**Phase B (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-B-EXPANSION.md` — Night modifiers (every 5 nights), Whispering Grove + Hollow Lake POI, Beacon Lv3 session checkpoint, Horizon Rings (5/15/20 nights), Hellbound path stub

**Phase C (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-C-PERSISTENCE.md` — DataStore checkpoint, playable Hellbound travel pipeline, Mega Dungeon zones 2–5, weekly rotating boss (Ring 3)

**Phase D (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-D-LIVEOPS.md` — Eternity City Hellbound Terminal (cross-place), Spirit Chamber combat, Military Base LFG board, season leaderboard

**Phase E (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-E-CROSSWORLD.md` — Commerce ticket auto-depart, Spirit Chamber co-op, cross-server LFG (MessagingService), global leaderboard UI (key L), Horizon Ring 4 + seasonal shrine

**Phase F (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-F-GLOBAL-MATCHMAKING.md` — season-scoped OrderedDataStore global leaderboard (cross-place names + true rank), LFG queue matchmaking with auto-party / teleport

**Phase G (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-G-SOCIAL-REWARDS.md` — direct party invite (cross-server), 12-season historical leaderboard, end-of-season ranked Luminite rewards

**Phase H (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-H-ROLLOVER-SOCIAL.md` — friends-list LFG invite, season titles/cosmetics on reward tiers, top-25 auto-distribute at season rollover

**Phase I (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-I-PRESENTATION-ADMIN.md` — overhead title billboard, cosmetic aura client FX, Studio admin force rollover (F9)

**Phase J (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-J-COSMETIC-PERSISTENCE.md` — cosmetic picker UI (C), DataStore persistence, admin reset season pointer (F9)

**Phase K (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-K-LOADOUT-HUB.md` — title picker (T), 3D Viewport preview, Hub loadout terminals, cross-place equip

**Phase L (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-L-UNIFIED-MIRROR.md` — unified tab UI (V/T/C), 3× preset slots, Hub mirror showcase for other players

**Phase M (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-M-PRESET-SHARE-PLAZA.md` — share preset with friends, mirror auto-rotate, Eternity City loadout plaza

**Phase N (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-N-CROSS-SERVER-SOCIAL.md` — cross-server preset notify, share codes, Solhaven/Nocturne plaza, friend online + city toast

**Phase O (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-O-FRIEND-JOIN-BAZAAR.md` — teleport to friend, offline notify digest + push hook, preset bazaar marketplace

**Phase P (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-P-PACKS-FEATURED-PUSH.md` — Robux preset packs, featured carousel, Open Cloud bridge sender

**Phase Q (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-Q-COMMERCE-CREATOR-ROTATION.md` — Commerce District preset bazaar, creator revenue ledger, seasonal carousel rotation

**Phase R (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-R-PAYOUT-UGC-SEASONAL.md` — group payout bridge export, UGC-linked creator packs, seasonal pop-up shop

**Phase S (implemented):** `docs/death-valley/phases/DEATH-VALLEY-PHASE-S-PAYOUT-UGC-POLISH.md` — UGC price picker, payout history UI, payout cron, seasonal pop-up visual polish
---

## IV. Prism Keys — ปริศนาหลายปี

- จำนวนรวม **ซ่อน** (`Prism Keys: ??`)
- กุญแจดอกที่ **1** = fixed tutorial chain  
- กุญแจดอกที่ **2+** = **rotate ตำแหน่งทุก patch** (seed จาก patch version + server salt)
- ต้อง **เดินทางข้ามเมือง** — clue ใน Hub Museum ไม่บอกตำแหน่งตรง 100%
- บางดอกต้อง หุบเขามรณะ nights + Nocturne cipher + Solhaven treasure

### IV-A. Eternity City access + key placement

| กุญแจที่มี | สิทธิ์เข้าเมือง |
|-----------|----------------|
| **< 10 ดอก** | **Preview Tour** — เฉพาะ Eternity Sanctuary (280 stud) · teleport กลับได้ |
| **≥ 10 ดอก** | เข้า-ออกเมืองได้ (ยังไม่ครบทุก zone) |
| **≥ 11 ดอก** | Canal Promenade + Hover Showroom (**ต้องมีกุญแจ #11**) |
| **≥ 15 ดอก** | Sky Rail Plaza + Premium Shop (**ต้องมีกุญแจ #15**) |
| **≥ 20 ดอก** | Full access — Sky Lounge 50 (**ต้องมีกุญแจ #20**) |

**Placement rules**

| ช่วงดอก | Spawn ได้ที่ |
|--------|-------------|
| **1–10** | **ห้าม** ใน Eternity City — Hub / Solhaven / Nocturne / Death Valley เท่านั้น |
| **11, 15, 20** | **เฉพาะ** Eternity City (gate keys) |
| **12–14, 16–19** | เมืองอื่น (ไม่ใช่ Eternity City) |
| **21+** | rotate ตาม `GameConfig.PrismKeys` |

**หมายเลขกุญแจ 1–99:** ดอก 1–5 = #1–#5 · ดอก 6+ สุ่ม #6–25 จนมี #25 · แล้ว #26–40 จนมี #40 · #41–60 · #61–80 · #81–99 ตามลำดับ

**แลกกุญแจ:** วิญญาณแลกกุญแจ · หุบเขามรณะ ด่าน 3–5 · 10 นาที/ด่าน · 3→1 หมายเลข · 1 นาที deadline · ไม่ทัน = *"คนอะไร ทำอะไรก็เชื่องช้างุ่มง่าม น่ารำคาญ"*

**Milestone rewards:** เมื่อได้รับหมายเลข 1/5/10/15/20 · **25** = Prism Live Mirror

**Code:** `PrismKeyRandomPools.luau` · `PrismKeyService.luau` · `PrismKeyGhostNpcService.luau` · `PrismKeyProgression.luau` · `EternityCityAccessGuard.luau` · `MountRewardService.luau`

---

## IV-B. Social Dungeons — ทุกเมือง

> **ปลูกนิสัยเข้าสังคม:** solo เข้าได้แต่ไม่รอด · ต้องมีเพื่อน

| ขนาดทีม | เข้าล่าบอส (50%) | ชนะ (75%) |
|---------|------------------|-----------|
| 2 | 1 | 2 |
| 5 | 3 | 4 |
| 10 | 5 | 8 |
| 20 | 10 | 15 |
| 50 | 25 | 38 |

- ทุกเมืองมี dungeon 2 แห่ง (10 dungeons รวม MVP)
- **Full spec:** `docs/SOCIAL-DUNGEON-SYSTEM.md` · `PrismDungeonConfig.luau`

---

## V. Helper NPC (Rotating — ไม่ทำเกมง่ายเกิน)

- **สูงสุด 1 NPC ต่อเมือง** ต่อ patch  
- ปรากฏเฉพาะผู้เล่น **Reputation ≥ 80** (help report, trade fair, co-op clear)  
- **ไม่บ่อย:** อย่างน้อย **2 patches** ระหว่าง visit  
- ให้ buff เล็กน้อย (cosmetic coupon, clue hint tier 1, ไม่ใช่ pay-to-win stat)

---

## VI. Seasonal Events

| Event | ช่วง | หมายเหตุ |
|-------|------|----------|
| Halloween | ต.ค. | Horror cosmetic ใน หุบเขามรณะ opt-in |
| Christmas | ธ.ค. | Hub lights, gift exchange (non-P2W) |
| New Year | ม.ค. | Fireworks Utopia of Eternity |
| Songkran | เม.ย. | Water emote Solhaven |
| Loy Krathong | พ.ย. | River Utopia of Eternity + Hub |

**อนาคต:** server region TH / US / EU — event calendar ตาม timezone ประเทศ

---

## VII. ยานพาหนะ + สัตว์พาหนะ (ที่นั่งตาม spec)

**Source of truth:** `VehicleMountCatalog.luau` · Visual ref: `docs/visual-ref/eternity-city/MOUNT-VEHICLE-CATALOG.md`

### VII-A. Travel modes + door rules

| โหมด | ตัวอย่าง |
|------|---------|
| **Land** | Big Bike, Sports Car, Sedan, Pickup, Van, Jeep |
| **Air** | Private Jet, Public Transport Airplane |
| **Water** | Speedboat, Public Transport Boat, Swan |
| **Tri** | Amphibious Flying Motorcycle, Flying Car-Boat Hybrid, Pegasus, Legendary Swan |

| ประตู | ใช้เมื่อ |
|------|---------|
| **GullWing** | ยานปิดทุกชนิด — กระจก/ประตูเปิดขึ้น |
| **OpenTop** | Pickup, Sports Car, Speedboat, Jeep, Flying Car-Boat Hybrid |
| **None** | สัตว์พาหนะ |

**Transit (ไม่ใช่ personal mount):** Prism Hover Shuttle · Public Transport Bus/Airplane/Boat

### VII-B. Seat table (catalog ids)

| id | ที่นั่ง | โซน summon |
|----|--------|-----------|
| sedan | **8** | Outskirts |
| pickup_truck | **14** | Outskirts |
| big_bike | **4** | Outskirts |
| dog / cat / rabbit | **2** | Sanctuary |
| tiger / lion | **3** | Sanctuary |
| unicorn | **3** | Sanctuary |
| swan | **4** | Water |
| dragon | **8** | Sanctuary |
| legendary_swan | **4** | Tri |
| prism_hover_shuttle | **20** | Sanctuary transit |
| public_transport_airplane | **40** | SkyLane |
| speedboat | **4** | Water |

**Hover flight (ทุกยานลอย):** เปลี่ยนทิศทางทันที · ไม่มี runway takeoff/landing · ใช้ hover corridor แทน sky lane แบบเฮลิคอปเตอร์

**Prism Hover Shuttle — inter-city transit:**
- จอดที่ **Sanctuary transit stop** ทุกเมือง (canopy + glow lane)
- ออกตามเวลา **ทุก 15 นาที** — **ไม่รอ** ที่นั่งครบ (`WaitForFullSeats = false`)
- Route: Hub → Solhaven → Nocturne → Utopia of Eternity → หุบเขามรณะ → วนกลับ
- Journey cinematic ต่อ leg: Low cruise (เห็นผู้เล่น) → Cloud layer (ซ่อน avatar ต่ำ) → Heaven sky → `TeleportService` → Descend → dock Sanctuary
- Cross-place ใช้ party teleport หลัง heaven phase (5 Places แยกกัน — ไม่ลอยข้าม Place ทางกายภาพ)
- Eternity variant: `ShuttleGreyboxBuilder:BuildEternityVariant` — glass band + gull-wing panels

**Mount Pad:** summon/dismiss เฉพาะ Sanctuary · ground mount ใน Outskirts · Utopia of Eternity มี vertical transport + hover corridor

**Eternity Premium Shop (key 15+):** ยาน Tri-mode + อาวุธ cosmetic Robux — เฉพาะ Eternity City · NPC VehicleAdvisor

---

## VIII. Utopia of Eternity — เมือง flagship (ไม่จำกัดเวลาสร้าง)

### VIII.1 Scale
- **ใหญ่ที่สุด** ใน universe — เดินไม่ไหวโดย design  
- Vertical: monorail, elevator, sky bridge, flying mounts 20 ที่นั่ง

### VIII.2 Geography
- ทะเล + ชายหาด + อ่าว  
- แม่น้ำไหลผ่านใจกลาง + ล้อมรอบเมือง  
- Solarpunk / paradise visual — **วิจิตร อลังการ ล้ำยุค**

**Implementation (MVP greybox):** `EternityCityWorldBuilder` — coastline + mountain backdrop + marina ring, spire cluster (5–7 + geodesic domes), double Sky Rail ribbon + Reflective Plaza, S-curve canal, zone gates 11/15/20, `EternityCityLighting`, `EternityCityAccessGuard`. Districts: Aurora Spire, Canal Promenade, Sky Rail Plaza, Hover Showroom, Premium Shop, Twilight Overpass. See `docs/visual-ref/eternity-city/VISUAL-BIBLE.md` · `docs/WORLD-BUILD-MICROCURVE-SPEC.md`.

**Sky Lounge Floor 50:** ภายใน Aurora Mega Mall — กระจก panorama 360°, selfie zones, social seating · ปลด key **20**

**Prism weapons (cosmetic):** `PrismWeaponCatalog.luau` — key 20 เลือก 1 Legendary ฟรี · key 15+ ซื้อชุดเต็มใน Premium Shop · ref `docs/visual-ref/prism-weapons/`

### VIII.3 Social / UGC / Commerce
- **Selfie spots** มากมาย (photo mode built-in, watermark เล็ก)  
- Fashion district, emote stage, creator showcase  
- **8+ Sanctuary spawn** กระจายทั่วเมือง
- **Aurora Mega Mall** — ห้างหลัก: Wardrobe, Salon, Beauty, Aesthetics, World Culture Pavilion
- **Marina Showroom** — Prism Motors, Service Center (premium paint), Neon Alley Tune (budget)
- **Sky Rail Plaza** — Mount Emporium, Stable Care, Weapon Gallery, Seasonal Pop-Up
- **Canal Boutique Row** — Accessory Lane, Luminling Pet Clinic
- ชุดเทศกาล: ปีใหม่ · ตรุษจีน · สงกรานต์ · ลอยกระทง · คริสต์มาส · ฮัลโลวีน
- ชุดประจำชาติ 20 ประเทศ (Heritage + Modern) — ดู `docs/FASHION-AND-SHOPS-DESIGN.md`
- ทุกร้าน = **Commerce Peace Zone** (`GameConfig.CommercePeaceZone`)
- Greybox: `CommerceDistrictBuilder.luau` — 17 ร้าน + Mega Mall + Marina + Live Mirror kiosk (key 25)
- **Face:** Template Forge + Prism Live Mirror (กุญแจ 25, live camera only) — `docs/FACE-CREATION-SYSTEM.md`

---

## IX. Onboarding — ผู้เล่นใหม่

- ระบบ **Guide NPC + UI checklist** (ปุ่มเปิด/ปิดได้)  
- ครอบคลุม: Sanctuary, teleport, Luminlings, Prism Keys intro, หุบเขามรณะ opt-in  
- ไม่ block veteran — skip ได้ทันที

---

## X. MMORPG / MOBA patterns ที่นำมาใช้ (ไม่ clone IP)

| แหล่ง | Pattern | ใช้ใน Utopia |
|-------|---------|--------------|
| Ragnarok / Yulgang | Reputation, mentor | Helper NPC + good behavior score |
| Lineage | Castle siege **concept** | Seasonal Hub event (non-PvP pay) |
| RO / MMORPG | Trade with lock | EconomyInflationGuard + atomic trade |
| AoV / ROV | Role clarity | หุบเขามรณะ co-op roles |
| Roblox Party | Co-play | Friend join same instance |

---

## XI. Research summary — Roblox fun factors

1. **เล่นกับเพื่อน = session ยาวขึ้น ~1.9x** (Roblox DevForum Party data)  
2. **ไม่โดน grief economy** = retention (Grow a Garden lesson)  
3. **Sanctuary ปลอดภัย** = social hangout (Brookhaven lesson แต่ original world)  
4. **Photo / fashion** = free marketing (Utopia of Eternity)  
5. **Mystery ยาว** = creator content (Prism Keys ??)

---

## XII. Code map

```
GameConfig.luau          — MountSeats, EternityCityAccess, หุบเขามรณะ, PrismKeys, Seasons, Sanctuary
VehicleMountCatalog.luau — full vehicle/mount catalog + door rules
PrismWeaponCatalog.luau  — key 20 + Premium Shop weapons
PrismKeyProgression.luau — gates + milestone rewards
EternityCityWorldBuilder.luau / EternityCityAccessGuard.luau / EternityCityLighting.luau
MountRewardService.luau / EternityVehicleShop.luau
Security/
  GriefingGuard.luau
  EconomyInflationGuard.luau
  SevereOffenseGate.luau
  EmulatorDetector.luau
  FanExperienceGuard.luau
  LogExportBridge.luau
SecurityCore.server.luau — bootstrap ทั้งหมด
docs/DESIGN-V03-FAN-LICENSE-PROGRAM.md — Eternity Forge
```

**Bridge (อนาคต):** FastAPI endpoint รับ `LogExportBridge` batch → Granite/DeepSeek classify → admin dashboard
