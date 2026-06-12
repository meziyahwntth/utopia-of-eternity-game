# BLUEPRINT V2 — World, Progression & Economy Overhaul
**โปรเจกต์:** Utopia of Eternity (Roblox · Luau strict · Rojo)
**สถานะ:** ร่างเพื่อขออนุมัติ — *ยังไม่เขียนโค้ดจนกว่าจะได้รับ approval*
**วันที่:** 12 มิ.ย. 2026
**อิงสถาปัตยกรรมเดิม:** `ServerScriptService/{World,DeathValley,Commerce,Security,Dungeon,Progression}`, `ReplicatedStorage/Modules` (GameConfig, Prism*), `StarterPlayer/StarterPlayerScripts`, bridge FastAPI

> เอกสารนี้แปลความต้องการที่คุณส่งมาเป็นสถาปัตยกรรมแบบ **modular** — แยกแต่ละระบบเป็น module ชัดเจน เพื่อไม่ให้เกิด Context Loop แบบ AI ตัวก่อน ทุกระบบเป็น **server-authoritative** (client แค่ส่ง intent, server ตัดสิน) เพื่อรองรับข้อกำหนด "กันบอท/กันโกงเข้มงวด"

---

## 0. สรุปภาพรวม (Executive Summary)

ความต้องการใหม่แบ่งได้เป็น **5 กลุ่มใหญ่**:

| กลุ่ม | ระบบ |
|------|------|
| **A. โลก/แผนที่** | เมือง Utopia ลอยฟ้าเหนือเมฆ · เมืองเกิด Neon Utopia (เมืองมนุษย์) · ขนส่งทางอากาศ · Hellbound เป็นดาวต่างมิติ + Hyper Space |
| **B. กล้อง & UX** | 3 มุมมอง (1st / 3rd / มุมสูง) |
| **C. ความปลอดภัย** | กันบอท/กัน AFK farm เข้มงวด (GM) |
| **D. Progression** | Player Level จากกุญแจเรียงเลข · 7 Tier · Quest กุญแจ · จิตอาสา/วิญญาณวีรชน |
| **E. ไอเทม & เศรษฐกิจ** | Item tier ตามความอลังการ · ranged PvE-only · น้ำหนัก · gating ตาม level · เหรียญนำโชค · กฎซื้อด้วยกุญแจ/robux |

---

## A. โลก / แผนที่ (World)

### A1. เมือง Utopia of Eternity ลอยฟ้าเหนือเมฆ 🌥️
**แนวคิด:** เมืองสรวงสวรรค์ ยกขึ้นไปลอยเหนือชั้นเมฆ

**การออกแบบ:**
- เพิ่ม `WorldBuildConfig.EternityCity.SkyAltitude` (เช่น `+2000` studs) — builder ทุกตัวบวก offset นี้กับตำแหน่ง Y ฐาน
- Module ใหม่ `World/CloudDeckBuilder.luau` — สร้างชั้นเมฆใต้เมือง (ผสม `Clouds` instance ใน Atmosphere + แพปุยเมฆโปร่งแสงรอบขอบเมือง เพื่อให้ "ยืนบนเมฆ" ได้จริง)
- ปรับ `Lighting/Atmosphere/Sky` ให้โทนสวรรค์ (ฟ้าใส, แสงทอง, หมอกขาวบาง)
- **Kill-floor / Safety net:** เพิ่ม `World/VoidGuard.luau` — ถ้าผู้เล่นตกใต้ระดับเมฆ → teleport กลับจุดปลอดภัยในเมือง (กันร่วงตายฟรี)
- กระทบ `EternityCityWorldBuilder`, `EternityTerrainSetup` — ต้องบวก SkyAltitude ทุกจุดที่อ้าง absolute Y

**ของเดิมที่ใช้ต่อ:** hero mesh + landmark (Marina/Aurora/Canal/SkyRail) ลอยขึ้นไปพร้อมเมืองอัตโนมัติเพราะอิงตำแหน่งฐานเดียวกัน

---

### A2. Neon Utopia — เมืองมนุษย์ (จุดเกิดแรก) 🌃
**แนวคิด:** ผู้เล่นใหม่เกิดที่ "เมืองมนุษย์" สไตล์ neon/cyberpunk ก่อน แล้วค่อยขึ้นเครื่องบินไป Utopia

**การออกแบบ (ต้องเลือก — ดู §G ข้อ 2):**
- **แนะนำ:** ทำ Neon Utopia เป็น **Place แยก** (PlaceKey ใหม่ `NeonUtopia`) — สเกลใหญ่ได้, แยก streaming, ไม่กินงบ part ของ Utopia
- Module ใหม่ `World/NeonUtopiaWorldBuilder.luau` (greybox ก่อน → hero mesh ทีหลังเหมือนเมืองอื่น)
- ตั้ง `SpawnLocation` หลัก + ป้าย onboarding ในนี้
- **Spawn routing:** `Progression/SpawnRouter.luau` — ผู้เล่นใหม่ (ไม่มี save) → Neon Utopia เสมอ; ผู้เล่นเก่า → จุดล่าสุด/เมืองที่ปลดล็อก

---

### A3. ขนส่งทางอากาศ (Air Transport) — Neon Utopia → Utopia
**แนวคิด:** ขึ้น "Transport airplane" จาก Neon Utopia ไป Utopia โดยจ่ายค่าโดยสารเป็น **กุญแจ หรือ robux**

**การออกแบบ:** (ต่อยอดระบบ Shuttle/PrismTransitStop เดิม)
- Module ใหม่ `World/AirTransportService.luau` + `AirTransportConfig`
- โมเดล: ลานจอด (Departure Gate) + เครื่องบิน + ประตูเก็บค่าโดยสาร (Fare Gate)
- **Fare (config ได้):** จ่ายด้วย *กุญแจ 1 ดอก* **หรือ** *robux จำนวน X* (ผู้เล่นเลือก) — ตัวเลขเริ่มต้นรอคุณกำหนด (ดู §G)
- ปลายทาง = `TeleportService` ไป Place `EternityCity` พร้อม transition VFX (ขึ้นบิน → เมฆ → ถึงเมืองลอยฟ้า)
- เก็บ ledger การจ่าย (กัน exploit) ผ่าน DataStore + pcall

---

### A4. Hellbound = ดาวต่างมิติ + Hyper Space 🌀
**แนวคิด:** เปลี่ยนคำอธิบาย/โครงสร้าง "ดวงดาวเฮลล์บาวน์ (หุบเขามรณะ)" ให้เป็นดาวใน **อีกมิติหนึ่ง** — เดินทางด้วยยานขนส่งทางอากาศ + กระโดด **Hyper Space** ข้ามมิติ

**การออกแบบ:**
- อัปเดต lore/docs: Hellbound = ดาวต่างมิติ (Death Valley อยู่บนนั้น)
- ใช้ AirTransportService ตัวเดียวกัน แต่ route = "Hyper Space Jump" → `TeleportService` ไป Place `DeathValley`
- VFX เฉพาะ: hyperspace tunnel / starfield warp + loading screen "เข้าสู่มิติเฮลล์บาวน์"
- จุดขึ้นยาน Hyper Space อาจอยู่ที่ Utopia (เมืองลอยฟ้า) หรือ Neon Utopia — รอคุณเลือก (§G)
- กระทบ docs เดิม (Hellbound/Death Valley), เพิ่ม `World/HyperSpaceGate.luau`

---

## B. กล้อง 3 มุมมอง 🎥

**ความต้องการ:** 1st person, "บุคคลที่ 2", มุมสูง

**⚠️ จุดต้องยืนยัน:** "บุคคลที่ 2" (2nd person) ในเชิงเทคนิคไม่ใช่มุมมาตรฐาน — เกมทั่วไปมี 1st / **3rd** (มุมหลังตัวละคร) / top-down ผมเดาว่าคุณหมายถึง **3rd person (มุมหลังตัวละคร)** จะยืนยันใน §G

**การออกแบบ:** `StarterPlayerScripts/CameraModeController.client.luau`
- ปุ่ม/ฮอตคีย์สลับ 3 โหมด:
  1. **First Person** — `Player.CameraMode = LockFirstPerson`
  2. **Third Person** — กล้องหลังตัวละคร (default Roblox + ปรับระยะ)
  3. **Top-Down (มุมสูง)** — custom camera มองจากด้านบน (ดีสำหรับวางแผน/เดินเมือง)
- จำค่าที่เลือกไว้ใน DataStore (per player preference)

---

## C. กันบอท / กัน AFK Farm เข้มงวด (Anti-Bot / Anti-Farm) 🛡️

อิงแนวทาง Roblox 2025: **server-authoritative**, ตรวจ behavior, auto-action กับ modified client

**การออกแบบ:** ต่อยอด `Security/` (Utopia Shield เดิม 22 ไฟล์)
- `Security/AntiBotGuard.luau` — heuristics:
  - การกระทำซ้ำแบบ deterministic (เดินวนเป๊ะ, คลิกเป็นจังหวะเครื่องจักร)
  - ไม่มีการขยับกล้อง/input variance เป็นเวลานานแต่ยังได้ reward
  - timing ต่ำกว่ามนุษย์ (action rate เกินเพดาน)
- `Security/FarmGuard.luau` — กุญแจ/รางวัลจะดรอป **เฉพาะเมื่อมี genuine activity** (ผ่าน server validation) — บอท AFK ฟาร์มไม่ได้
- `Security/HumanityCheck.luau` — บัญชีต้องสงสัย → challenge (เช่น mini-captcha/quiz) ก่อนรับรางวัลใหญ่
- Action rate-limit ทุก RemoteEvent ผ่าน `RemoteGuard:Register` (มี roadblock เดิมที่ยังไม่ wire — จะรวมแก้)
- ใช้ MemoryStore เก็บ session behavior fingerprint; ban/flag pipeline → bridge FastAPI log
- **เสริมจากวิจัย:** ตรวจ speed/teleport/health/damage manipulation; พึ่ง auto-ban ระดับแพลตฟอร์มของ Roblox สำหรับ modified client ร่วมด้วย

---

## D. Progression — Level, Tier, Quest, จิตอาสา

### D1. Player Level จากกุญแจเรียงเลข (Sequential Key Level) 🔑
**กฎ:** Level = ความยาวลำดับกุญแจ **ต่อเนื่องจาก #1** ที่เก็บได้
- เก็บ #1 → Level 1, เก็บ #2 → Level 2 …
- ดรอปเป็น**ระบบสุ่ม** → ถ้าได้ #5 แต่ยังขาด #3,#4 → **ไม่เลื่อน** (เก็บ #5 ไว้ในคลัง รอเติมช่องว่าง)
- Level = max N ที่ครอบครองกุญแจ #1..#N ครบทุกดอก

**การออกแบบ:** `Progression/PlayerLevelService.luau`
- เก็บ `ownedKeys: {[number]: true}` ใน DataStore
- คำนวณ level = นับต่อเนื่องจาก 1
- กุญแจมีหมายเลข **1–149** (ตรงกับ 149 level)

### D2. 7 Player Tiers + ฉายา 🏅
| Tier | Level | ชื่อ (EN) | ชื่อ (TH) |
|------|-------|----------|----------|
| 1 | 1–15 | Newbie / Novice | ผู้เล่นใหม่ |
| 2 | 16–25 | Apprentice / Beginner | ผู้ฝึกหัด |
| 3 | 26–40 | Adept / Journeyman | ชำนาญการขั้นต้น |
| 4 | 41–60 | Veteran / Seasoned | ผู้เจนสนาม |
| 5 | 61–80 | Expert / Elite | ผู้เชี่ยวชาญ |
| 6 | 81–99 | Master / Champion | ปรมาจารย์ |
| 7 | 100–149 | **Hero** | **วีรบุรุษ / วีรสตรี** (ตามเพศตัวละคร) |
| End-game | (max) | Grandmaster / Legend / Sovereign | ระดับตำนาน |

**การออกแบบ:** `ReplicatedStorage/Modules/PlayerTierConfig.luau` (data-driven: band → title, สี, perks, ฉายาแยกเพศสำหรับ Hero)

### D3. Quest กุญแจ (Key Quest System) 📜
- เก็บกุญแจผ่าน **ระบบเควส** (objective → reward = กุญแจหมายเลขถัดไป) + ดรอปสุ่มเสริม
- `Progression/QuestService.luau` + `QuestConfig` (objective types, rewards, prerequisite)
- ผู้เล่นใหม่ Lv 1–15 → ได้กุญแจสุ่ม #1–#15

### D4. จิตอาสา + วิญญาณวีรชน (Volunteer / Hero Souls) 💛
**แนวคิด:** ให้รางวัลคนช่วยมือใหม่ (ทำดีเพื่อสังคม)
- ผู้เล่นที่ช่วยมือใหม่ทำเควส (เช่น เข้าปาร์ตี้ด้วยกัน) → ได้กุญแจ **ระดับเดียวกัน** ถึงแม้ตัวเองผ่านระดับนั้นไปแล้ว
- กุญแจที่สะสม → เอาไป **แลก "วิญญาณวีรชน"** ที่ **หุบเขามรณะ** → แลกรางวัลอื่นต่อ
- `Progression/VolunteerService.luau` + `DeathValley/HeroSoulsExchange.luau`
- **กัน abuse:** ต้องช่วยจริง (มือใหม่ทำ objective สำเร็จขณะอยู่ปาร์ตี้ + เงื่อนไขเวลา/ระยะ) ไม่ใช่แค่ยืนใกล้ — ผูกกับ AntiBotGuard

---

## E. ไอเทม & เศรษฐกิจ (Items & Economy)

### E1. Item Tier ตามความอลังการ (Grandeur Rank) ✨
- **ทุกไอเทม**มี 2 มิติ:
  1. **Required Level/Tier** (ผูกกับ level ผู้เล่น)
  2. **Grandeur Rank** (อันดับความสวยงาม/อลังการ) — ใช้กับ เสื้อผ้า/เครื่องประดับ/พาหนะ/อาวุธ (ของแบบเดียวกันแต่แบ่งอันดับ)
- Data-driven: เพิ่ม field `RequiredLevel`, `GrandeurRank` ใน catalog (ต่อยอด Prism catalog + unified shop-rental catalog 58 เซ็ตเดิม)

### E2. Ranged Weapon = PvE-only, ดาเมจตาม tier 🏹
- อาวุธยิงไกล **โจมตีได้เฉพาะ มอนสเตอร์/บอส/NPC** — **ห้ามโดนผู้เล่นด้วยกัน**
- ยิ่ง tier สูง → ดาเมจยิ่งแรง
- `DeathValley/CombatService` (ของเดิม) + filter: ถ้าเป้าเป็น Player → ปฏิเสธดาเมจ (server-side); ตาราง damage ตาม WeaponTier

### E3. ระบบน้ำหนัก (Weight System) ⚖️
- ไอเทมมีน้ำหนัก, ผู้เล่นมีเพดานน้ำหนัก
- **เกินเพดาน → เคลื่อนที่ -50%, โจมตี -50%**
- `Progression/WeightService.luau` — รวมน้ำหนักที่สวมใส่/ถือ, apply penalty ผ่าน Humanoid (WalkSpeed) + combat modifier

### E4. Item Gating ตาม Level + Overweight + เหรียญนำโชค 🪙
- ใส่ไอเทม**สูงกว่า level ตัวเอง** → ถูกปรับเป็น **น้ำหนักเกินทันที** (แต่เก็บในกระเป๋า/โกดังได้)
- ผู้เล่น level สูง → ใช้ไอเทม**ต่ำกว่า**ตัวเองได้อิสระ
- **เหรียญนำโชค (Lucky Coin)** จากกิจกรรม → ปลดล็อกเงื่อนไขนี้**ชั่วคราว**:
  | เหรียญ | ปลดล็อก |
  |--------|---------|
  | ทองแดง (แดง) | 1 เดือน |
  | เงิน | 2 เดือน |
  | ทอง | 3 เดือน |
  *(การจับคู่ระยะเวลา–เหรียญ รอคุณยืนยัน §G)*
- ครบกำหนด → ไอเทมถูก **ถอดเก็บเข้ากระเป๋าส่วนตัวอัตโนมัติ**
- `Progression/ItemGatingService.luau` + `Commerce/LuckyCoinService.luau` (เก็บวันหมดอายุใน DataStore, เช็คตอน equip + timer)

### E5. กฎการซื้อ/แลกไอเทม ตาม Level 💳
| Level | วิธีได้ไอเทม |
|-------|------------|
| 1–25 | ใช้**กุญแจแลก** ได้เลย — **ไม่ต้องใช้ robux** |
| 26+ | (1) **กุญแจ + robux** ตามจำนวนกำหนด **หรือ** (2) **robux อย่างเดียว แต่ ×5** เทียบแบบ (1) |
- `Commerce/PurchaseService.luau` + pricing rule engine ตาม player level (ต่อยอด CatalogSecrets/ProcessReceipt เดิม — และต้องแก้ roadblock `DEV_GRANT_FREE`/`ProcessReceipt` ก่อนเปิดจริง)

---

## F. นำ Engagement เกมดังมาประยุกต์ (จากการค้นคว้า) 🎯

จากเกมท็อป Roblox 2025–26 (Brookhaven, Blox Fruits, Grow a Garden, Steal a Brainrot):

| หลักการที่เวิร์ค | ประยุกต์กับ Utopia |
|-----------------|-------------------|
| Onboarding สั้น | Neon Utopia สอนเล่น 5 นาที → ขึ้นเครื่องบินไป Utopia |
| Social hook แรง (ปาร์ตี้/ขโมย/แข่ง) | ระบบ **จิตอาสา/ปาร์ตี้** + leaderboard tier + guild |
| Progression เห็นชัด | **Key level 1–149** + ฉายา 7 tier โชว์เด่น |
| Monetization optional-but-aspirational | Lv 1–25 เล่นฟรีด้วยกุญแจ; ไอเทม grandeur สูง = "grail" อยากได้ |
| Live-ops/อัปเดตต่อเนื่อง | อีเวนต์ตามฤดู (มีระบบ Season อยู่แล้ว — LoyKrathong) + เหรียญนำโชคจากอีเวนต์ |
| Player-driven economy | ต่อยอด **ร้านเช่า** (Shop Rental) ที่ทำไว้แล้ว + trading |
| Collection/FOMO | กุญแจสะสม + cosmetic grandeur จำกัดเวลา |
| Idle/cozy pacing | กิจกรรมเก็บเล็กผสมน้อยในเมืองลอยฟ้า |

---

## G. การตัดสินใจ (Decisions) ✅ — ยืนยันแล้ว 12 มิ.ย. 2026

1. **กล้อง "บุคคลที่ 2"** = ✅ **3rd person (มุมหลังตัวละคร)**
2. **Neon Utopia** = ✅ **Place แยก**
3. **จุดขึ้น Hyper Space ไป Hellbound** = ✅ **ที่ Utopia (เมืองลอยฟ้า)**
4. **เริ่มเฟส** = ✅ **P0 ก่อน** → ตรวจแล้วพบว่า **P0 เสร็จหมดแล้ว** (validate-p0-publish ผ่าน) → ไปต่อ P1
5. *(รอกำหนด)* ค่าโดยสารเครื่องบิน (กุญแจ/robux) — ตั้ง default ไว้ก่อน ปรับใน config ได้
6. *(รอกำหนด)* เหรียญนำโชค ทองแดง=1ด./เงิน=2ด./ทอง=3ด. — ใช้ default นี้ก่อน

### สถานะ P0 (ตรวจจริง 12 มิ.ย. 2026 — ทุกข้อ DONE)
DEV_GRANT_FREE=false · ProcessReceipt validate ตาม pending · DevGrantEternityItem disabled · RemoteGuard:Register wired · GriefingGuard Init+hooks wired · MemoryStore pcall ครบ · `validate-p0-publish.py` PASS

---

## H. แผนการสร้างแบบเป็นเฟส (Phased Rollout)

> ทำทีละเฟส ทดสอบผ่านก่อนไปต่อ — กัน Context Loop

| Phase | งาน | ทำไมก่อน |
|-------|-----|---------|
| **P0 (เร่งด่วน)** | ปิด `DEV_GRANT_FREE`, แก้ `ProcessReceipt`, wire `RemoteGuard`/`GriefingGuard`, MemoryStore pcall | เป็น production blocker เดิม — ต้องปิดก่อนเปิดระบบเงิน |
| **P1 World** | เมืองลอยฟ้า + VoidGuard + Neon Utopia greybox + SpawnRouter | ฐานของทุกอย่าง |
| **P2 Transport** | AirTransport (Neon→Utopia) + HyperSpace (→Hellbound) + fare | เชื่อมโลก |
| **P3 Progression** | PlayerLevelService + TierConfig + QuestService | แกนเกม |
| **P4 Items/Economy** | Item tier + Weight + Gating + LuckyCoin + PurchaseService + Ranged PvE | ต่อยอด progression |
| **P5 Volunteer** | VolunteerService + HeroSoulsExchange | social loop |
| **P6 Anti-Bot** | AntiBotGuard + FarmGuard + HumanityCheck | เข้มงวดทั้งระบบ |
| **P7 Camera/UX** | CameraModeController 3 มุม | ขัดเงา |
| **P8 Live-ops** | อีเวนต์/leaderboard/season จาก §F | คงผู้เล่น |

---

## I. โครงสร้างไฟล์ใหม่ (สรุป Modules ที่จะเพิ่ม)

```
ServerScriptService/
  World/        CloudDeckBuilder · VoidGuard · NeonUtopiaWorldBuilder
                AirTransportService · HyperSpaceGate
  Progression/  PlayerLevelService · QuestService · VolunteerService
                WeightService · ItemGatingService · SpawnRouter
  Commerce/     PurchaseService · LuckyCoinService
  DeathValley/  HeroSoulsExchange · (ปรับ CombatService → ranged PvE filter)
  Security/     AntiBotGuard · FarmGuard · HumanityCheck
ReplicatedStorage/Modules/
                PlayerTierConfig · QuestConfig · AirTransportConfig
                WeightConfig · ItemTierConfig (+field ใน catalog เดิม)
StarterPlayer/StarterPlayerScripts/
                CameraModeController · (UI: level/tier HUD, transport, quest)
```

ทุก module = single responsibility, สื่อสารผ่าน RemoteEvent/Function ที่ผ่าน RemoteGuard, อ่าน config จาก ReplicatedStorage — ปรับสมดุลได้โดยไม่แตะ logic

---

*จบร่าง — รอ feedback/approval ก่อนเริ่ม Phase ใด ๆ*
