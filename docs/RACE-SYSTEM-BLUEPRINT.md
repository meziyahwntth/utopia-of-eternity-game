# Blueprint: ระบบเผ่า (Race System)

> 15 มิ.ย. 2026 · ต่อยอด lore `world/RACES-AND-HELLBOUND-LORE-2026-06.md` + `CLASS-JOB-SYSTEM-BLUEPRINT.md` (interlock) + นโยบาย `POLICY-ECONOMY-PVP-ANTIGRIEF.md`
> อิงของจริง: `Progression/SpawnRouter.luau` (route new→NeonUtopia), `PlayerLevelService`, `CombatService`/(ClassService อนาคต), GameConfig.Places
> **ลำดับ: ทำหลัง Class/Job** (RaceConfig.classAffinity อ้าง class ids) · โค้ด → Cursor · รออนุมัติก่อนลงมือ

## 1. เผ่า (4 เล่นได้ + Orc สูญพันธุ์)
| เผ่า | เมืองบ้านเกิด (homeCity) | affinity (โบนัสเบา) | บุคลิก |
|---|---|---|---|
| **Human** | NeonUtopia | สมดุลทุกคลาส (ยืดหยุ่นสุด) | เทคโนโลยี รอบด้าน |
| **Elf** | Solhaven | Mage/Hunter | แสง/ธรรมชาติ/เวท |
| **Dark Elf** | Nocturne | Assassin/Warlock | เงา/ลอบเร้น/เวทมืด |
| **Alien** | EternityCity | จิตพลัง/เทค (สกิลเฉพาะเผ่า) | อารยธรรมก้าวหน้า/ข้ามมิติ |
| **Orc** | — (Hellbound, สูญพันธุ์) | — | อนาคต: Revenant Orc / ศัตรู-บอส |

**กฎ (ตาม policy):** เลือกเผ่า**ฟรี** · เผ่า = **affinity เบา + บุคลิก/ภาพ ไม่ lock class** · **ห้ามขายเผ่าเพื่อพลัง** (cosmetic skin เผ่าขายได้) · ทุกเผ่า **solo-viable**

## 2. RaceConfig schema (ReplicatedStorage/Modules/RaceConfig.luau)
```lua
export type RaceId = "Human"|"Elf"|"DarkElf"|"Alien"
export type RaceDef = {
  id: RaceId, label: string, labelTH: string,
  homeCityKey: string,           -- ตรง GameConfig.Places key (NeonUtopia/Solhaven/Nocturne/EternityCity)
  statMods: { hp: number, atk: number, walkSpeed: number },  -- โบนัสเบา (เช่น 1.0±0.05) — balance ใน config
  classAffinity: { string },     -- class ids ที่ได้โบนัสเล็กน้อย (อ้าง ClassConfig)
  racialPassive: { id: string, desc: string },   -- always-on เบา ๆ
  racialSkill: { id: string, cooldown: number }?, -- active เฉพาะเผ่า (optional)
  meshBodyId: string?,           -- placeholder Next-Gen Art (custom skinned mesh ต่อเผ่า) — ใส่ทีหลัง
  lore: string,                  -- ตำนานสั้นต่อเผ่า
}
-- helper: RaceConfig.get(id), RaceConfig.all(), RaceConfig.isPlayable(id)
```
- statMods/affinity เบามาก (กัน power creep + รักษา no-P2W + ไม่ทำลายสมดุล PvP)

## 3. RaceService (server-authoritative)
- `getRace(player)` / `setRace(player, raceId)` — เก็บ DataStore (pcall ครบ) + cache per session; load ตอน PlayerAdded
- เลือกครั้งแรกตอนสร้างตัว (ยังไม่มี race ใน save) ; **re-select** = config (ฟรีจำกัดครั้ง/เสียกุญแจ — ตั้ง default ปรับได้, ไม่ใช่ robux-only กัน P2W feel)
- apply statMods เข้า Humanoid (WalkSpeed) + ส่งต่อให้ CombatService/ClassService รวม (race × class stack) — เบาทั้งคู่
- validate racialSkill: เช็ก player race ก่อนอนุญาตใช้ (กัน exploit) — เหมือน skill-of-class check

## 4. ไฟล์ที่ต้องเพิ่ม
```
ReplicatedStorage/Modules/  RaceConfig.luau
ServerScriptService/Progression/  RaceService.luau · RaceHandlers.server.luau
StarterPlayer/StarterPlayerScripts/  RaceSelectClient.client.luau (UI สร้างตัว, mobile-first)
```
แก้: `SpawnRouter` (route ตาม homeCity ของเผ่า), `ClassService`/`CombatService` (รวม race statMods), `SecurityRemoteBootstrap` (register RequestRaceSelect)

## 5. Integration notes (อิงโค้ดจริง)
- **SpawnRouter:** ปัจจุบัน new→NeonUtopia. เพิ่ม: ถ้ามี race แล้ว → route ไป homeCity ของเผ่า. ⚠️ เมืองเป็น **Place แยก** → cross-place spawn = ใช้ PlaceTeleport (มีอยู่). **MVP**: ผู้เล่นใหม่ทุกเผ่าเริ่มที่ NeonUtopia (onboarding) ก่อน แล้ว home-city routing เป็น enhancement หลัง
- **Class/Job:** RaceConfig.classAffinity อ้าง ClassConfig ids → ต้องมี Class/Job ก่อน (หรือกำหนด ids เป็น string คงที่)
- **Next-Gen Art:** meshBodyId ต่อเผ่า = งาน art track (ChatGPT concept → mesh+PBR) — ใส่ทีหลัง, ตอนนี้ placeholder

---

# Cursor Prompt-Pack (วางทีละ prompt, commit แยก) — ทำหลัง Class/Job

## PROMPT 1 — RaceConfig (data)
```
สร้าง src/ReplicatedStorage/Modules/RaceConfig.luau (Luau strict) ตาม schema ใน docs/RACE-SYSTEM-BLUEPRINT.md §2
นิยาม 4 เผ่าเล่นได้ (Human/Elf/DarkElf/Alien) + homeCityKey ตรง GameConfig.Places · statMods เบา (1.0±0.05) · classAffinity อ้าง class ids จาก ClassConfig · racialPassive + racialSkill (optional) · lore ต่อเผ่า · meshBodyId=nil (placeholder)
helper: get(id), all(), isPlayable(id). อ่าน GameConfig.luau + ClassConfig.luau ก่อนให้ key/id ตรง
```

## PROMPT 2 — RaceService + Handlers (server-authoritative)
```
สร้าง src/ServerScriptService/Progression/RaceService.luau + RaceHandlers.server.luau (Luau strict)
- getRace/setRace เก็บ DataStore (pcall ครบ) + cache; load ตอน PlayerAdded
- เลือกครั้งแรกตอนยังไม่มี race; re-select = config cost (ฟรีจำกัด/กุญแจ ไม่ใช่ robux-only)
- apply statMods → Humanoid.WalkSpeed + expose getRaceStatMods(player) ให้ CombatService/ClassService รวม
- validate racialSkill ตาม race ผู้เล่น (กัน exploit)
- Handlers: RemoteFunction "RequestRaceSelect" + RemoteEvent "RaceChanged" ผ่าน RemoteGuard:Register — แก้ SecurityRemoteBootstrap
อ่าน PlayerLevelService + ClassService(ถ้ามี) + SecurityRemoteBootstrap ก่อน
```

## PROMPT 3 — RaceSelectClient UI (สร้างตัว, mobile-first)
```
สร้าง src/StarterPlayer/StarterPlayerScripts/RaceSelectClient.client.luau (Luau strict)
- เปิดอัตโนมัติเมื่อผู้เล่นยังไม่มี race (fetch จาก RaceService) — หน้าจอ "เลือกเผ่า"
- แสดง 4 เผ่า: ภาพ/ไอคอน (placeholder), lore, affinity, statMods, racial skill → ปุ่มยืนยัน → RequestRaceSelect
- mobile-first: Scale + UIAspectRatioConstraint + touch zone ใหญ่ (ตาม Mobile-UX audit) + auto-hide ไม่เกี่ยว (modal)
```

## PROMPT 4 — Integration (SpawnRouter + stat stacking)
```
แก้ src/ServerScriptService/Progression/SpawnRouter.luau: ถ้าผู้เล่นมี race + ผ่าน onboarding → route ไป homeCity ของเผ่า (ใช้ PlaceTeleport). MVP: ถ้ายังไม่พร้อม cross-place ให้คงเริ่มที่ NeonUtopia แล้ว log ไว้
แก้ CombatService/ClassService: รวม race statMods × class statMods (เบาทั้งคู่) ในการคำนวณ damage/HP/speed
ทดสอบ require ผ่านทุกไฟล์
```

## หลัง Cursor เสร็จ — Cowork
Rojo-sync → command-bar verify (RaceConfig/RaceService require, remotes, RaceSelectClient) → playtest (เลือกเผ่า→statMods apply→racial skill→spawn home city) → publish → memory/diary

## Definition of Done
- [ ] เลือกเผ่าได้ตอนสร้างตัว (server validate) · re-select ตาม config
- [ ] statMods (race) มีผล + stack กับ class · racialSkill ใช้ได้เฉพาะเผ่าตน (server check)
- [ ] SpawnRouter route ตาม homeCity (หรือ MVP NeonUtopia + log) · UI mobile-first
- [ ] เผ่าฟรี ไม่ขายเพื่อพลัง · ทุกเผ่า solo-viable · ไม่พังเกมเดิม (ไม่มี race = default)
