# Lineage II (MMORPG core) + FPS — ควรลงเมืองใด

> 15 มิ.ย. 2026 · อิงโค้ดจริง + [[FIVE-CITIES-REVISIT-2026-06]] · เป้า: ชน benchmark ก่อน deploy

## สถานะจากโค้ด (ตรวจจริง — ไม่เดา)
- **ClanWar** = zoneId **config-driven** (ผูกเมืองไหนก็ได้) — มี TerritoryStore/ClanVault/Tax/DefensiveFatigue แล้ว
- **ยังไม่มีระบบ Class/Job** (มีแค่ key-level 1–149 + 7 tier) ← **ชิ้นที่ขาดที่สุดเทียบ Lineage II / Vesteria / World//Zero**
- **DeathValley** มีโครง PvE grind/boss ครบ: MegaZones, MilitaryBase, WeeklyBoss, Dungeon, Combat
- **ยังไม่มี FPS/Arena/PvP** ใด ๆ ในโปรเจกต์

---

## คำถาม 1: Lineage II ควรลงเมืองใด?
**คำตอบ: ไม่ใช่ "เมืองเดียว" — Lineage II คือ "แกนของทั้งเกม" แบ่งเป็น 2 ครึ่ง ลงคนละเมือง**

Lineage II/Ragnarok มี 2 ครึ่งชัดเจน → map ตามจุดแข็งเมืองที่มีอยู่:

### ครึ่ง A — เมืองหลวง/การเมือง/เศรษฐกิจ/Siege → **EternityCity** (flagship)
- มี **ClanWar + territory + ภาษี** อยู่แล้ว = "ตีปราสาท/ยึดเขต" ของ L2 → ตั้ง zone ภาษี/ป้อมที่ EternityCity
- เพิ่ม: guild hall, marketplace/auction (ต่อยอด trading + shop rental), social endgame
- = "เมืองหลวงที่คนมาอวดของ/ตั้งกิลด์/ทำสงครามชิงเขต"

### ครึ่ง B — Open-world grind / party raid boss / rare drop → **DeathValley** (Hellbound)
- มี MegaZones/MilitaryBase/WeeklyBoss/Dungeon/Combat อยู่แล้ว = "ทุ่งล่ามอน + บอสประจำโซน" ของ L2
- **horror = flavor "โซนอันตรายเลเวลสูง"** (เหมือน Tower of Insolence/Forsaken Plains ของ L2) — กลางวันฟาร์ม/เตรียม, กลางคืน horror escalation
- rare drop 0.1% + party เพื่อปราบ raid boss = หัวใจ L2/Swordburst3/Dungeon Quest

### แกนกลาง (NEW, global) — **ระบบ Class/Job** = ชิ้นที่ต้องสร้างเพิ่ม
- เทียบ Vesteria (Warrior/Mage/Hunter → sub-class) / World//Zero (10+ class, tier 2-3) / Rogue Lineage (Base→Super→Ultra)
- เป็น **layer ทั่วทั้งเกม** ทับ key-level/tier เดิม: เลือกสายตอนถึง level กำหนด → sub-class ทีหลัง, สกิลต่างกัน (ต่อยอด Skill Bar + CombatService ที่มีแล้ว)
- **Job-change trainer NPC** วางที่ **EternityCity** (เมืองหลวง) + อาจมี Solhaven
- ผูกกับ gear-hunt loop: ItemCrafting/CardFusion/weapon-tier/grandeur ที่ blueprint มีแล้ว

> สรุป Q1: **EternityCity = เมืองหลวง/siege/economy · DeathValley = ทุ่งล่า/raid boss · + สร้างระบบ Class/Job ใหม่เป็นแกนทั้งเกม** (อย่ายัดทุกอย่างลงเมืองเดียว)

---

## คำถาม 2: FPS ควรลงเมืองใด หรือสร้างเมืองเพิ่ม?
**คำตอบ: อย่ายัด FPS เข้า combat MMORPG, อย่าทำเป็นเมืองเปิดที่ 6, ทำเป็น "โหมดแยก instanced opt-in" — และแนะนำ "เลื่อนไปทำทีหลัง"**

เหตุผล:
1. **ชนกันทางระบบ:** combat ปัจจุบันเป็น **tab-target/Auto-Lock + Skill Bar** (มุมมอง 3rd person) — คนละ paradigm กับ FPS (เล็งเอง first-person). รวมกัน = พังทั้งสมดุลและ control
2. **lore:** ปืน/FPS เข้าได้เฉพาะฝั่งเมืองมนุษย์ (NeonUtopia/Nocturne) — เมืองลอยฟ้า/sanctuary/นรกแฟนตาซีไม่เข้า
3. **anti-cheat/เศรษฐกิจ:** FPS PvP ต้อง sandbox แยกจาก economy MMORPG (กันบอท/กันโกง คนละชุด) — blueprint กำหนด ranged = **PvE-only ห้ามโดนผู้เล่น** อยู่แล้ว ถ้าจะมี PvP FPS ต้องแยกโลก
4. **scope มหาศาล:** จะชน Frontlines/RIVALS ต้องทุ่มเท่าเกมเดี่ยว ๆ หนึ่งเกม — ตอนนี้ core ยังไม่ครบ (class system ยังไม่มี, 5 เมืองยัง greybox)

**ทางที่แนะนำ (เรียงตามความคุ้ม):**
- **(A) เลื่อน FPS ไปก่อน** จนกว่า MMORPG core + 5 เมือง + แข่งรถ + horror จะ ship และผ่าน quality bar — โฟกัสไม่แตก ✅ แนะนำ
- **(B) ถ้าจะทำ: instanced battleground เป็น Place แยก** (เหมือน Hellbound เป็น place แยก) เข้าผ่าน terminal/portal ที่ **NeonUtopia** (เมืองมนุษย์เทค ปืนเข้า lore) — sandbox เต็มที่ ชน Frontlines ได้โดยไม่กระทบ MMORPG
- **(C) ทางถูก/เร็วกว่า FPS เต็ม: PvP arena minigame** ใน **Nocturne** ใช้ combat 3rd person ที่มีอยู่ (ไม่ใช่ FPS แท้ แต่ scope เล็กกว่ามาก) — ได้ความมัน PvP เร็วกว่า

> สรุป Q2: **ไม่สร้างเมืองเปิดที่ 6 · FPS = โหมด instanced แยก (entry ที่ NeonUtopia) และควรเลื่อนไปทำหลัง core เสร็จ** ถ้าอยากได้ PvP เร็ว → arena 3rd-person ที่ Nocturne

---

## ข้อควรระวังเชิงกลยุทธ์
เกมตอนนี้กว้างมากแล้ว (MMORPG + แข่งรถ + horror + cozy + social). เพิ่ม FPS pillar = เสี่ยงแตกโฟกัสจน core ไม่เสร็จสักอย่าง. **ลำดับแนะนำ:** ปิด Class/Job system (ชิ้นที่ขาด) → เติม L2 loop ที่ EternityCity+DeathValley → แล้วค่อยพิจารณา FPS เป็น expansion
ทุกอย่างยึด [[feedback-graphics-benchmark]]: ไม่ชน/เทียบเท่า benchmark = ไม่ deploy

## ถัดไป
ถ้าเห็นด้วย → ผมทำ **Blueprint ระบบ Class/Job** (สาย, sub-class, skill tree, job-change, ผูก Skill Bar/CombatService) เป็นชิ้นถัดไปของ MMORPG core แล้วแตก Cursor prompt-pack
