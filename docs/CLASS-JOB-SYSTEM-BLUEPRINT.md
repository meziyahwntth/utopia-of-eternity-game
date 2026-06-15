# Blueprint: ระบบ Class/Job (MMORPG core ชิ้นที่ขาด)

> 15 มิ.ย. 2026 · ต่อยอดของจริง: `CombatConfig` (Sword/Bow/Staff + Skills + per-skill cooldown), `CombatService` (server-authoritative + skill cooldown), `SkillBarClient`, `PlayerLevelService` (key-level 1–149), `PlayerTierConfig` (7 tiers)
> เป้า: สายอาชีพแบบ Vesteria / World//Zero / Rogue Lineage · server-authoritative กัน exploit · mobile-first
> โค้ด → Cursor ([[feedback-delegate-to-cursor]]) · ทบทวน/อนุมัติก่อนเริ่ม

## 1. โครงสร้างสายอาชีพ (3 ขั้น ผูกกับ tier เดิม)
ขั้นการเปลี่ยนอาชีพ align กับ tier bands ที่มีอยู่:

| ขั้น | Level gate | tier ที่ตรง | หมายเหตุ |
|---|---|---|---|
| **Class 1 (Base)** | Lv 10 | Tier 1 (1–15) | เลือกหลัง onboarding ที่ NeonUtopia/EternityCity |
| **Class 2 (Sub-class)** | Lv 40 | สุด Tier 3 | แตกสายย่อย |
| **Class 3 (Advanced)** | Lv 100 | Tier 7 (Hero) | end-game (เฟสหลัง) |

### สาย (อิง weapon type ที่มีอยู่ Sword/Bow/Staff)
```
Warrior (Sword)  → Guardian (tank) · Berserker (DPS) · Paladin (tank/support)
Mage (Staff)     → Elementalist (AoE nuke) · Sage (heal/support) · Warlock (DoT/curse)
Hunter (Bow)     → Ranger (sustained) · Assassin (burst/melee-hybrid) · Trickster (utility/trap)
```
- Class 3 = แตกต่อจาก sub-class (ออกแบบทีหลัง — ใส่ schema เผื่อไว้)
- **ranged (Bow/Staff) = PvE-only** ตาม blueprint E2 (CombatService filter เป้า Player)

## 2. ต่อยอด CombatConfig (skills เป็น per-class)
ปัจจุบัน `CombatConfig.Skills` เป็น global 3 สกิล → เปลี่ยนเป็น **per-class skill set** (SkillBar อ่านจากคลาสที่ active)
```lua
-- ใหม่: ClassConfig.luau (ReplicatedStorage/Modules)
export type SkillId = string
export type ClassDef = {
  id: string, label: string, labelTH: string,
  weaponType: "Sword"|"Bow"|"Staff",
  baseClass: string?,          -- nil = base; ไม่ nil = sub-class ของใคร
  unlockLevel: number,         -- 10 / 40 / 100
  statMods: { hp: number, atk: number, range: number, cdMult: number },
  skills: { SkillId },         -- 4–6 สกิล แสดงบน Skill Bar
}
-- skills อ้าง id ใน CombatConfig.SkillMultiplier/SkillCooldown (เพิ่มสกิลใหม่ที่นั่น)
```
- เพิ่มสกิลใหม่ต่อสายใน `CombatConfig.SkillMultiplier` + `SkillCooldown` (คงของเดิม BasicAttack/PowerSlash/AoeSpin ใช้เป็น default ตอนยังไม่เลือกคลาส)

## 3. Server-authoritative (ต่อ CombatService เดิม)
- เก็บ `playerClass[userId]` ใน DataStore (pcall) → load ตอน join
- **CombatService.processAttack เพิ่ม CHECK ใหม่:** skillId ต้องอยู่ใน skill set ของคลาสผู้เล่น (กันยิงสกิลข้ามคลาส) — ถ้าไม่ใช่ → reject
- damage = base × skillMultiplier × **class.statMods.atk** ; cooldown × **class.statMods.cdMult**
- job-change validate: level ≥ unlockLevel + (ถ้าเป็น sub) baseClass ตรง + ชำระค่า (กุญแจ/robux/quest) → server ตัดสิน

## 4. ไฟล์ที่ต้องเพิ่ม
```
ReplicatedStorage/Modules/
  ClassConfig.luau            ← นิยามคลาส/สาย/skill set/stat (data-driven)
ServerScriptService/Progression/
  ClassService.luau           ← get/set class, job-change validation, level gate, DataStore(pcall)
  ClassHandlers.server.luau   ← wire remotes (ผ่าน RemoteGuard:Register)
StarterPlayer/StarterPlayerScripts/
  ClassSelectClient.client.luau ← UI เลือก/เปลี่ยนอาชีพ (mobile-first, Scale)
ServerScriptService/World/
  (NPC job-change trainer ที่ EternityCity — builder/anchor)
```
แก้: `CombatConfig` (per-class skills), `CombatService` (skill-of-class check + stat mods), `SkillBarClient` (อ่าน skills จากคลาส active), `SecurityRemoteBootstrap` (register remotes ใหม่)

## 5. Loop ผู้เล่น
เกิด → Lv10 เลือก Base class (trainer NPC) → ฟาร์ม/เควสขึ้นเลเวล → Lv40 แตก sub-class → ล่าบอส/หา gear ตามสาย → Lv100 advanced → clan war/endgame
ผูกกับ: gear-hunt (DeathValley), siege/economy (EternityCity), key-level เดิม

## 6. กันพลาด/หลักการ
- **ไม่ทำลายของเดิม:** ผู้เล่นที่ยังไม่เลือกคลาส = ใช้ default skill set (BasicAttack/PowerSlash/AoeSpin) เกมเดิมเล่นได้ปกติ
- server-authoritative ทุกจุด (เลือก/เปลี่ยน/ยิงสกิล) · rate-limit ผ่าน RemoteGuard
- balance ผ่าน config ล้วน (ปรับ statMods/skill ไม่ต้องแตะ logic)
- mobile-first: UI เลือกคลาสปุ่มใหญ่ Scale + ผูก Mobile-UX audit

---

# Cursor Prompt-Pack (วางทีละ prompt, commit แยก)

## PROMPT 1 — ClassConfig (data)
```
สร้าง src/ReplicatedStorage/Modules/ClassConfig.luau (Luau strict)
ตาม schema ใน docs/CLASS-JOB-SYSTEM-BLUEPRINT.md §2: ClassDef (id/label/labelTH/weaponType/baseClass/unlockLevel/statMods/skills)
นิยาม: 3 base class (Warrior/Mage/Hunter) unlockLevel=10 + 9 sub-class unlockLevel=40 (ตาม §1)
อ่าน CombatConfig.luau ก่อน — skill id ต้องสอดคล้อง; เพิ่ม SkillMultiplier+SkillCooldown สำหรับสกิลใหม่ต่อสาย (4–6 สกิล/คลาส) คงของเดิมไว้เป็น default
export type + helper: ClassConfig.get(id), ClassConfig.getSubclassesOf(baseId), ClassConfig.canChange(currentClassId, targetClassId, level)
```

## PROMPT 2 — ClassService + Handlers (server-authoritative)
```
สร้าง src/ServerScriptService/Progression/ClassService.luau + ClassHandlers.server.luau (Luau strict)
- ClassService: getClass(player)/setClass(player,classId) เก็บ DataStore (pcall ครบ) + cache per session; load ตอน PlayerAdded
- job-change validation: ใช้ ClassConfig.canChange + PlayerLevelService (level ≥ unlockLevel, sub ต้อง baseClass ตรง); ค่าเปลี่ยนอาชีพ = config (กุญแจ/robux/quest — ตั้ง default ปรับได้)
- Handlers: wire RemoteFunction "RequestClassChange" + RemoteEvent "ClassChanged" ผ่าน RemoteGuard:Register (rate-limit) — แก้ SecurityRemoteBootstrap ด้วย
อ่าน PlayerLevelService.luau + SecurityRemoteBootstrap.server.luau ก่อน เพื่อใช้ API/รูปแบบเดิม
```

## PROMPT 3 — CombatService integration (skill-of-class + stat mods)
```
แก้ src/ServerScriptService/Combat/CombatService.luau:
- เพิ่ม CHECK: skillId ที่ยิงต้องอยู่ใน ClassConfig.get(playerClass).skills (ดึง class จาก ClassService) — ไม่ใช่ → reject (กันยิงข้ามคลาส)
- damage = base × skillMultiplier × statMods.atk ; cooldown × statMods.cdMult
- ผู้เล่นไม่มีคลาส → ใช้ default เดิม (ไม่พังเกมเก่า)
อ่านไฟล์ก่อนแก้ คง 3-check เดิม (distance/rate/LoS) + server cooldown ไว้
```

## PROMPT 4 — Skill Bar + Class Select UI (mobile-first)
```
แก้ SkillBarClient.client.luau: อ่าน skill set จากคลาส active (ผ่าน ClassChanged event + initial fetch) แทน CombatConfig.Skills global
สร้าง ClassSelectClient.client.luau: UI เลือก/เปลี่ยนอาชีพ (เปิดเมื่อคุยกับ trainer NPC), แสดงสาย/สกิล/stat, ปุ่มยืนยัน → RequestClassChange
ทั้งคู่ mobile-first: Scale + UIAspectRatioConstraint + touch zone ใหญ่ (สอดคล้อง Mobile-UX audit)
```

## หลัง Cursor เสร็จ — Cowork
Rojo-sync → command-bar verify (ClassConfig/ClassService require ผ่าน, remotes มี) → playtest (เลือกคลาส→สกิลเปลี่ยน→ยิงข้ามคลาสถูก reject) → publish v12+ → memory/diary

## DoD
- [ ] เลือก base class ที่ Lv10, sub-class ที่ Lv40 ได้ (server validate)
- [ ] Skill Bar เปลี่ยนตามคลาส · ยิงสกิลข้ามคลาสถูกปฏิเสธฝั่ง server
- [ ] stat mods มีผลกับ damage/cooldown · ผู้เล่นไม่มีคลาสเล่นได้ปกติ
- [ ] trainer NPC ที่ EternityCity · UI mobile-first
