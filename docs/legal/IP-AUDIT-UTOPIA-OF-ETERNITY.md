# IP Audit — Utopia of Eternity

**Date:** 8 มิถุนายน 2026 · **Scope:** ชื่อเกม · 6 เมือง + หุบเขามรณะ · ระบบ/ตัวละคร/ยานพาหนะในแผน

> นี่คือการประเมินความเสี่ยง (risk assessment) ไม่ใช่คำปรึกษากฎหมาย — ก่อน publish ควรให้ทนายตรวจซ้ำถ้าเกม viral

---

## 1. ชื่อเกม: **Utopia of Eternity**

| การค้นหา | ผล | ความเสี่ยง |
|----------|-----|------------|
| Roblox ชื่อตรง `"Utopia of Eternity"` | **ไม่พบ** experience ชื่อเดียวกัน | ✅ ต่ำ |
| เกมที่มีคำใกล้เคียง | `1984 Utopia` (Orwell sim) · `ETERNITY` (asym horror) · `Eternal Towers of Hell` | ⚠️ ต่ำ–กลาง — คนละ genre แต่คำ "Utopia"/"Eternity" ซ้ำบางส่วน |
| โดเมน `utopiaofeternity.com` | ลงทะเบียนแล้ว (เรา) | ✅ |

**คำแนะนำ:** ใช้ชื่อเต็ม **Utopia of Eternity** ใน Roblox title + thumbnail (ไม่ย่อเป็นแค่ "Utopia" หรือ "Eternity" เพื่อลด confusion)

---

## 2. ชื่อเมือง / โซน (6 + Horror)

| ชื่อ | ความเสี่ยง IP | หมายเหตุ | แนะนำ |
|------|---------------|----------|--------|
| **Utopia Plaza Hub** | ✅ ต่ำ | Generic + universe brand | เก็บ |
| **Solhaven** | ⚠️ ต่ำ–กลาง | มี fan project "Sol Haven" (Pokemon ARPG Discord) — คนละ platform/genre | เก็บได้ · หลีกเลี่ยง Pokemon visual |
| **Nocturne Alley** | ✅ ต่ำ | Generic gothic | เก็บ |
| **Utopia of Eternity** (flagship city) | ✅ ต่ำ | **เปลี่ยนแล้ว** จาก Neo Prism — ลด clash กับ Valve NEON PRIME TM | เก็บ (Place แยกจาก Hub) |
| **หุบเขามรณะ** | ✅ ต่ำ | **เปลี่ยนแล้ว** จาก Veilwood — ลด clash กับ Steam VeilWood | เก็บ · visual/lore original 100% |
| **Citadel Arcane** (Phase 8) | ✅ ต่ำ | Generic fantasy | เก็บ |
| **Verdant Depths** | ✅ ต่ำ | Generic | เก็บ |
| **Skyward Perch** | ✅ ต่ำ | Generic | เก็บ |

### ชื่อใน-world (ไม่ใช่เมือง)
| ชื่อ | ความเสี่ยง | หมายเหตุ |
|------|------------|----------|
| Luminlings | ✅ ต่ำ | Original creature |
| Prism Keys | ✅ ต่ำ | Original mechanic |
| Utopia Shield / Sentinel | ✅ ต่ำ | Internal brand |

---

## 3. ระบบ / เนื้อหาในแผน — ละเมิดลิขสิทธิ์หรือไม่?

| รายการ | สถานะ | หมายเหตุ |
|--------|--------|----------|
| 99 Nights co-op lessons | ✅ OK | เรียน **กลไก** (difficulty scale, friend-only) ไม่ copy asset/ชื่อ/ตัวละคร |
| MMORPG patterns (RO, Ragnarok, Lineage, Yulgang) | ✅ OK | ใช้ **design pattern** (reputation, seasonal, party buff) — ห้าม copy UI/icon/skill name |
| MOBA (AoV/ROV) | ✅ OK | ใช้ role clarity / honor system — ไม่ clone hero |
| ยานพาหนะ (sedan, dragon, unicorn ฯลฯ) | ✅ OK | **Generic archetypes** — model ต้อง original mesh 100% |
| Seasonal (Halloween, Songkran ฯลฯ) | ✅ OK | วันสำคัญสากล/ไทย — หลีกเลี่ยง Disney character |
| Roblox Party API | ✅ OK | Official platform feature |

### Red lines (ห้ามเด็ดขาด)
- ชื่อ/รูป/เสียงจาก franchise (Marvel, Disney, 99 Nights assets, Brainrot meme IP)
- คัดลอก map layout เกมดัง
- ใช้ชื่อ "Neon Prime" หรือ "VeilWood" เป็นชื่อ display หลัก

---

## 4. สรุปการตัดสินใจที่แนะนำ

| ลำดับ | Action |
|-------|--------|
| 1 | **เก็บ** ชื่อเกม Utopia of Eternity |
| 2 | **เสร็จแล้ว** Veilwood → **หุบเขามรณะ** (`Places.DeathValley`) |
| 3 | **เสร็จแล้ว** Neo Prism → **Utopia of Eternity** flagship (`Places.EternityCity`) |
| 4 | **Eternity Forge** fan license program — ดู `DESIGN-V03-FAN-LICENSE-PROGRAM.md` |
| 5 | ที่เหลือ **ผ่าน** ถ้า art/audio original |

---

## 5. Pre-publish checklist

- [ ] Roblox search ชื่อเกม + ชื่อเมืองอีกครั้งก่อน soft launch
- [ ] USPTO / TM search สำหรับชื่อที่เหลือ
- [ ] ทุก mesh/audio มี provenance document
- [ ] ลงทะเบียน IP ใน Roblox License Manager **หลัง Public Save** (~10 Jun 2026+)
- [ ] เปิด `GameConfig.Bridge.FAN_SCAN_URL` + Bridge cron สำหรับ Eternity Forge
- [x] Group ownership transfer → Community `791898614` (9 Jun 2026)
- [x] Community experience visibility enabled (9 Jun 2026)
- [ ] Configure Public audience Save (blocked: new-creator waiting period)

---

## 6. Post-transfer status (9 Jun 2026)

| Item | Value |
|------|-------|
| Universe | `10293115628` |
| Community / Owner | `791898614` Utopia of Eternity |
| Configure audience | Private (APIs enabled) |
| Public Save | Blocked until ~10 Jun 2026 |
| Bridge | `https://api.utopiaofeternity.com/health` → ok |
| Agent policy | No Roblox web/Studio automation until user triggers `Public Save แล้ว` |
