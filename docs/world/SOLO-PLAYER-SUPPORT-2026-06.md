# รองรับผู้เล่นเดี่ยว / ไม่ชอบสังคม (Solo-Friendly Design)

> 15 มิ.ย. 2026 · Praphan: "ต้องมีพื้นที่สำหรับผู้เล่นเดี่ยว มีเยอะ"
> หลักการ: social เป็น **ตัวเลือก/โบนัส ไม่ใช่บังคับ** — solo ต้องเล่นจบ progression หลักได้ด้วยตัวคนเดียว

## หลักการแกน (cross-cutting)
1. **ไม่ gate progression หลักไว้หลัง party-only** — key-level 1–149, class/job, gear หลัก ต้องทำคนเดียวได้ครบ
2. **Difficulty scaling ตามจำนวนผู้เล่น** — บอส/ดันเจี้ยน HP/ดาเมจ scale ลงเมื่อเล่น 1 คน (party = เร็วขึ้น/รางวัลมากขึ้น ไม่ใช่ "เงื่อนไขผ่าน")
3. **NPC แทนปาร์ตี้** — ใช้ของที่ blueprint มีแล้ว: **Pets** (ช่วยตี/บัฟ แบบ World//Zero), **Mercenary/Bounty** (จ้าง NPC/ผู้เล่นช่วย), companion → solo ไม่เหงา/ไม่ตัน
4. **Auto-Battle/Auto-Lock** (มีแล้ว) — ช่วย solo ฟาร์มซ้ำไม่เมื่อยมือ (Lineage W philosophy)
5. **Class/Job ต้อง solo-viable ทุกสาย** — แม้สาย support (Sage/Paladin) ต้องมี self-sustain พอ solo ได้ (อย่าออกแบบให้ "ไร้ค่าถ้าไม่มีปาร์ตี้")
6. **Instanced/ส่วนตัว** — เนื้อหา solo เป็น instance ส่วนตัว ไม่ต้องแย่ง spawn/แข่งกับคนอื่น
7. **social hook = โบนัส** — จิตอาสา/ปาร์ตี้/clan ให้ "เพิ่ม" (EXP/drop/ค่าเงิน) ไม่ใช่ "ปลดล็อก" เนื้อหา

## solo ได้อะไรในแต่ละเมือง
| เมือง | เนื้อหา solo | หมายเหตุ |
|---|---|---|
| **Solhaven** (cozy/economy) | **ศูนย์กลางสาย solo** ⭐ — crafting, สวน/ปลูก, ตกปลา, ร้านเช่า, idle/cozy loop | แบบ Grow a Garden/Adopt Me — เล่นคนเดียวเพลินไม่ต้องยุ่งใคร |
| **NeonUtopia** (แข่งรถ) | time-trial vs **ghost** + career/แต่งรถ solo | แข่งกับเวลา/AI ไม่ต้องรอคน |
| **EternityCity** (flagship) | landmark, progression ส่วนตัว, ร้าน, quest เดี่ยว | clan war = ตัวเลือก ไม่บังคับ |
| **Nocturne** (nightlife/PvP) | quest กลางคืน solo + PvE; PvP/arena = สมัครใจ | solo ไม่ต้องโดนลาก PvP |
| **DeathValley** (horror) | **solo horror instance** (แนว The Mimic/Jim's Computer) + ดันเจี้ยน scale 1 คน | co-op = ตัวเลือกที่ "ง่ายขึ้น" ไม่ใช่บังคับ |

## ต่อยอดของจริงในโปรเจกต์
- **มีอยู่แล้ว:** Pet (`PetClient`/pet system), Mercenary/Bounty (`MercenaryService`/`BountyBoardClient`), Auto-Battle, Auto-Lock, Solhaven cozy, DeathValley dungeon/weekly boss, ranged PvE-only
- **ต้องเพิ่ม/ปรับ:**
  - **Party-size difficulty scaling** ใน `DeathValleyCombatService`/`WeeklyBossService`/dungeon (scale HP/dmg/reward ตามจำนวนผู้เล่นในโซน/instance)
  - **Solo instance flag** สำหรับ horror chapter + dungeon (เข้าคนเดียวได้, instance ส่วนตัว)
  - ตรวจ Class/Job ([[../CLASS-JOB-SYSTEM-BLUEPRINT.md]]) ให้ทุก sub-class **solo-viable** (statMods/skill มี self-heal/sustain พอ)
  - ทบทวน Volunteer/Party reward = "เพิ่ม" ไม่ "gate"

## ข้อควรระวัง
- อย่าทำ solo "ง่ายเกิน" จนทำลายเศรษฐกิจ — party ควร **คุ้มกว่าเล็กน้อย** (เร็ว/รางวัลมากกว่า) เพื่อจูงใจสังคมโดยไม่บังคับ
- balance ผ่าน config (scaling factor) ปรับได้

## ถัดไป
รวมหลักการนี้เข้า Blueprint Class/Job (solo-viable) + ทำ **Party-Size Scaling** เป็น Cursor prompt เพิ่ม (ต่อจาก Class/Job หรือคู่ขนาน)
