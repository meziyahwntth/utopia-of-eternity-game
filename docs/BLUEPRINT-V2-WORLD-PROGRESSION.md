# BLUEPRINT V2 — World, Progression & Economy Overhaul
**โปรเจกต์:** Utopia of Eternity (Roblox · Luau strict · Rojo)
**สถานะ:** ร่างเพื่อขออนุมัติ — *ยังไม่เขียนโค้ดจนกว่าจะได้รับ approval*
**วันที่:** 12 มิ.ย. 2026
**อิงสถาปัตยกรรมเดิม:** `ServerScriptService/{World,DeathValley,Commerce,Security,Dungeon,Progression}`, `ReplicatedStorage/Modules` (GameConfig, Prism*), `StarterPlayer/StarterPlayerScripts`, bridge FastAPI

> 🆕 **อัปเดต 15 มิ.ย. 2026:** ทิศทาง World/Races/Lore/Policy ล่าสุดอยู่ที่ `MASTER-BLUEPRINT.md §13` + เอกสารลูก `world/*` · `POLICY-ECONOMY-PVP-ANTIGRIEF.md` · `CLASS-JOB-SYSTEM-BLUEPRINT.md` — เผ่า (Human/Elf/Dark Elf/Alien + Orc สูญพันธุ์ที่ Hellbound), บทบาท 5 เมือง, no-P2W/PvP zoning, Class/Job, solo-friendly. เอกสารนี้ (V2) ยังใช้สำหรับโครง World/Progression/Economy เดิม.

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

---

## J. สถาปัตยกรรม Combat Server-Authoritative (§2.5) 🗡️
> อ้างอิง MASTER-BLUEPRINT §11.1 — รายละเอียดสำหรับ Cursor implement

### J1. โครงสร้าง Module Script ฝั่ง Server

```
ServerScriptService/
  Combat/
    CombatService.luau          ← Module หลัก: Sanity Check 3 ชั้น + HP management
    AutoBattleService.luau      ← เก็บ auto-battle state per player (on/off + targetId)
    CombatHandlers.server.luau  ← wire RemoteEvents → CombatService
  Security/
    RateLimitGuard.luau         ← MemoryStore token bucket per player per action
ReplicatedStorage/Modules/
    CombatConfig.luau           ← weapon ranges, attack speeds, damage tables
StarterPlayer/StarterPlayerScripts/
    AutoBattleClient.client.luau ← target lock UI + animation + FireServer
```

### J2. Flow การทำงาน (ลำดับชัดเจน)

```lua
-- 1. Client เปิด Auto-Battle
AutoBattleToggle.MouseButton1Click → AutoBattleService:SetAutoMode(player, true)

-- 2. Client loop (RunService.Heartbeat ทุก AttackTick)
local nearest = findNearestEnemy(maxRange)  -- client-side only
if nearest then
  remoteAttack:FireServer(nearest.NPC_Id, currentSkillId)
end

-- 3. Server: CombatService.processAttack(player, npcId, skillId)
local function processAttack(player, npcId, skillId)
  -- CHECK 1: Distance
  local dist = (player.Character.HumanoidRootPart.Position
               - npc.HumanoidRootPart.Position).Magnitude
  if dist > CombatConfig.MaxRange[weaponTier] then return false end

  -- CHECK 2: Rate Limit (token bucket via MemoryStore)
  if not RateLimitGuard:consume(player.UserId, "attack") then return false end

  -- CHECK 3: Line of Sight
  local ray = workspace:Raycast(
    player.Character.HumanoidRootPart.Position,
    (npc.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position),
    raycastParams  -- exclude player + npc models
  )
  if ray and ray.Instance and not ray.Instance:IsDescendantOf(npc) then
    return false  -- กำแพงกั้น
  end

  -- ผ่านทั้ง 3 → apply damage
  local dmg = CombatConfig.BaseDamage[weaponTier] * skillMultiplier[skillId]
  npc:TakeDamage(dmg)  -- server-authoritative
  return true
end
```

### J3. CombatConfig Schema
```lua
-- ReplicatedStorage/Modules/CombatConfig.luau
return {
  MaxRange = {
    Sword = 10,   -- studs
    Bow   = 50,
    Staff = 30,
  },
  AttackSpeed = {  -- วินาที/ครั้ง (rate limit)
    T1 = 1.0, T2 = 0.9, T3 = 0.8, T4 = 0.7, T5 = 0.6,
  },
  BaseDamage = {
    T1 = 10, T2 = 20, T3 = 35, T4 = 55, T5 = 80,
  },
  SkillMultiplier = {
    ["BasicAttack"] = 1.0,
    ["PowerSlash"]  = 1.8,
    ["AoeSpin"]     = 1.2,
  },
}
```

### J4. Remotes ที่ต้องเพิ่มใน SocialRemoteSetup (หรือ CombatRemoteSetup ใหม่)
```lua
ensure("RemoteEvent", "CombatAttackRequest")   -- Client→Server (Fire)
ensure("RemoteEvent", "CombatResultClient")    -- Server→Client (damage VFX, HP update)
ensure("RemoteFunction", "AutoBattleToggle")   -- Client↔Server (on/off)
```

---

## K. ระบบภาษี Clan War — Tax Distribution DB (§2.6) 💰
> อ้างอิง MASTER-BLUEPRINT §11.2 — รายละเอียดสำหรับ Cursor implement

### K1. DataStore Schema

```lua
-- TerritoryStore: key = "territory_v1_{zoneId}"
export type TerritoryData = {
  ownerClanId: string,
  taxRate: number,            -- 1..5 (percent) — clan leader ตั้ง
  maintenanceCostBase: number,-- คำนวณ ณ เวลา war win
  fortHp: number,             -- 100 → ลด -5%/สัปดาห์ (min 40)
  weeksClaimed: number,
  lastWarCycleId: string,
  clanVaultBalance: number,   -- สะสม 50% ของภาษี
  memberDividends: {          -- {[userId: string]: number} รอ claim
    [string]: number
  },
  serverBuffActive: boolean,  -- 20% → drop rate +5% ทั่วเขต
  lastDistributedAt: number,  -- os.time()
}

-- ClanVaultStore: key = "clanvault_v1_{clanId}"
export type ClanVaultData = {
  balance: number,            -- ยอดรวม
  npcGuardSlots: number,      -- จำนวน NPC ยามที่ซื้อไว้
  barrierLevel: number,       -- กำแพงสงคราม tier 1–5
  lastWithdrawnBy: string,    -- userId leader ที่ถอนล่าสุด
  lastUpdatedAt: number,
}
```

### K2. TaxDistributionService — Flow

```
[ShopRentalService / TradeService]
  → emit TaxCollected(zoneId, amount)
  → TaxDistributionService:onTaxCollected(zoneId, amount)
      ├─ 50% → TerritoryData.clanVaultBalance += amount*0.5
      │         ClanVaultStore:save()
      ├─ 30% → แบ่งให้สมาชิก Veteran+ (ตาม GuildService.getRankedMembers)
      │         TerritoryData.memberDividends[userId] += share
      └─ 20% → apply ServerBuff("DropRateBonus", zone, 0.05, duration=7days)
                TerritoryData.serverBuffActive = true
```

### K3. Maintenance Cost Formula (Exponential)
```lua
local multipliers = { [1]=1.0, [2]=1.5, [3]=2.5, [4]=4.0, [5]=6.5 }
local BASE_MAINTENANCE = 100  -- เครดิตต่อสัปดาห์
local maintenanceCost = BASE_MAINTENANCE * multipliers[taxRate]
```

### K4. DefensiveFatigueService — Weekly Cron
```lua
-- รันทุก 7 วัน (ผ่าน task scheduler หรือ MemoryStore sorted set timer)
for zoneId, territory in TerritoryStore:getAll() do
  if territory.ownerClanId ~= "" then
    territory.fortHp = math.max(40, territory.fortHp - 5)
    territory.weeksClaimed += 1
    TerritoryStore:save(zoneId, territory)
  end
end
```

### K5. Modules ที่ต้องสร้าง (Phase P5)
```
ServerScriptService/ClanWar/
  ClanWarService.luau            ← war scheduling, zone capture, winner logic
  TaxDistributionService.luau    ← 50/30/20 split, ServerBuff apply
  TerritoryStore.luau            ← DataStore wrapper (pcall ครบ)
  ClanVaultStore.luau            ← Clan Vault DataStore wrapper
  DefensiveFatigueService.luau   ← weekly HP decay cron
ReplicatedStorage/Modules/
  ClanWarConfig.luau             ← tax rates, maintenance multipliers, war schedule, fatigue rate
  TaxConfig.luau                 ← split ratios (50/30/20), buff duration, buff magnitude
```

---

## L. Retention & Interdependency (§2.7) 🔗
> อ้างอิง MASTER-BLUEPRINT §11.3

### L1. Low-Tier Material Sink — ItemCraftingConfig Schema
```lua
-- ReplicatedStorage/Modules/ItemCraftingConfig.luau
return {
  Grandeur = {
    ["★★★ Sword"] = {
      baseItem = "★★ Sword",
      materials = {
        { id = "StoneFragment", qty = 500 },   -- drop จาก Lv1-15 mobs
        { id = "IronOre",       qty = 200 },   -- drop จาก Lv16-30 mobs
        { id = "MagicCrystal",  qty = 50  },   -- drop จาก Dungeon boss
      },
      creditCost = 1000,
    },
    -- ... เพิ่ม recipe อื่น
  },
  CardFusion = {
    -- Card socket upgrade ต้องการ low-tier card × N
  },
}
```

### L2. Mercenary System — Module Structure
```
ServerScriptService/Mercenary/
  MercenaryService.luau      ← post/accept/complete escort job
  BountyService.luau         ← post/accept/claim bounty
  MercenaryHandlers.server.luau ← wire remotes
StarterPlayerScripts/
  BountyBoardClient.client.luau ← NPC board UI, job list, accept button
ReplicatedStorage/Modules/
  MercenaryConfig.luau       ← escort timeout, min/max pay, bounty limits
```

### L3. Sky Treasure Event — Module Structure
```
ServerScriptService/LiveOps/
  SkyTreasureService.luau    ← cron every 2hr, spawn, 3min countdown, reward
StarterPlayerScripts/
  SkyTreasureClient.client.luau ← server announcement banner, minimap marker, timer
ReplicatedStorage/Modules/
  SkyTreasureConfig.luau     ← spawnPoints[], rewardPool[], intervalSeconds=7200
```

### L4. Sky Treasure Flow
```
SkyTreasureService (server):
  every 7200 seconds:
    zones = SkyTreasureConfig.spawnPoints  -- จุดที่เป็นไปได้
    chosen = Random.new():NextInteger(1, #zones) * 3  -- สุ่ม 3 จุด
    for each zone:
      MessagingService:PublishAsync("UtopiaLiveOps", {
        event = "SkyTreasure", zone = zone, endsAt = os.time()+180
      })
      spawn treasure chest model at zone.Position
      wait 180 seconds
      → ผู้เล่นที่อยู่ในรัศมี 20 studs นานสุด → reward (tie-break: ผู้เล่นแรก)
      despawn chest
```

---

## M. อัปเดตโครงสร้างไฟล์รวม (หลัง §2.5–2.7)

```
ServerScriptService/
  Combat/       CombatService · AutoBattleService · CombatHandlers
  ClanWar/      ClanWarService · TaxDistributionService · TerritoryStore
                ClanVaultStore · DefensiveFatigueService
  Mercenary/    MercenaryService · BountyService · MercenaryHandlers
  LiveOps/      SkyTreasureService
  (เดิม)
  World/        CloudDeckBuilder · VoidGuard · NeonUtopiaWorldBuilder ...
  Progression/  PlayerLevelService · QuestService · VolunteerService ...
  Security/     AntiBotGuard · FarmGuard · HumanityCheck · RateLimitGuard(ใหม่)
ReplicatedStorage/Modules/
  CombatConfig · ClanWarConfig · TaxConfig · MercenaryConfig
  SkyTreasureConfig · ItemCraftingConfig · (เดิม: GameConfig, Prism*)
StarterPlayerScripts/
  AutoBattleClient · BountyBoardClient · SkyTreasureClient · (เดิม)
```

---

*BLUEPRINT-V2-WORLD-PROGRESSION อัปเดต 13 มิ.ย. 2026 (§J–M: Research 2.5–2.7 architecture)*
