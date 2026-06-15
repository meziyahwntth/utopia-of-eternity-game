---
topic: utopia-of-eternity-design-direction
date: 2026-06-15
tags: [utopia, blueprint, worldbuilding, races, lore, economy, pvp, class-job, mobile-ux, mempalace, obsidian]
ingest_targets: [mempalace, obsidian]
---

# 2026-06-15 — Consolidation: World Identity · Races · Lore · Policy · Class/Job

> สรุปการตัดสินใจทิศทางทั้งหมดของ session 15 มิ.ย. 2026 (ยืนยันโดย Praphan) เพื่อ ingest เข้า MemPalace + Obsidian
> Single source of truth = `docs/MASTER-BLUEPRINT.md §13`

## 0. งาน infra ที่ทำในวันนี้ด้วย
- **EternityCity re-publish v11** (แก้ incident v10 = accidental publish จาก stale `utopia-playtest.rbxlx`) ผ่าน Rojo-sync + Studio Publish; verify (targeting/terrain/skillbar/support) + playtest ผ่าน

## 1. บทบาท 5 เมือง + เผ่า (แต่ละเมืองเด่นคนละเรื่อง)
| เมือง | เผ่า | บทบาท | benchmark |
|---|---|---|---|
| NeonUtopia | Human | onboarding + เมืองแข่งรถหลัก | Velocity Outlast |
| Solhaven | Elf | cozy/crafting/เศรษฐกิจ + ศูนย์กลาง solo | Grow a Garden, Adopt Me |
| Nocturne | Dark Elf | nightlife + PvP arena + ดริฟต์กลางคืนรอง | Blox Fruits |
| EternityCity | Alien | flagship + Clan War/ภาษี + Hyper Space | Nexus (กราฟิก) |
| DeathValley (Hellbound) | Orc (สูญพันธุ์) | horror survival + ทุ่งล่า/raid boss | DOORS, The Mimic, 99 Nights, Pressure |

## 2. Lore แกน
- 4 เผ่าเล่นได้ (Human/Elf/Dark Elf/Alien) + **Orc = เผ่าสูญพันธุ์** ที่ Hellbound
- **ตำนาน Hellbound:** ออร์คมีอารยธรรมยิ่งใหญ่ แต่ผู้นำโลภแย่งชิงอำนาจทั้งดวงดาว → สงคราม → หายนะภูเขาไฟ → สูญพันธุ์ เหลือ Shadow Wraiths (วิญญาณออร์ค) = parable สะท้อนโลกจริง
- ให้ "ความหมาย" กับ horror (story horror แบบ The Mimic) · เผ่าที่ยังอยู่เดินทางไปค้นความจริง/ไม่ให้ซ้ำรอย
- เผ่า = affinity เบา ไม่ lock class, เลือกฟรี, แต่ละเผ่า = custom mesh+PBR

## 3. เมืองแข่งรถ
**NeonUtopia = หลัก** (lore รถฝั่งเมืองมนุษย์, radiant_day โชว์รถ, traffic สูง) + **Nocturne = แทร็กดริฟต์กลางคืนรอง**

## 4. Lineage II / FPS
- L2 = แกนทั้งเกม: EternityCity (เมืองหลวง/siege/economy) + DeathValley (ทุ่งล่า/raid boss). ชิ้นขาด = **Class/Job system**
- **FPS = เลื่อนไปก่อน (เลือก A)** จน core เสร็จ; ถ้าทำ = instanced place แยก entry NeonUtopia (ไม่ทำเมืองที่ 6)

## 5. Horror หุบเขามรณะ
ไม่ลอก FNAF ทั้งดุ้น → แกน atmosphere+sound+entity-AI (DOORS), บีบวิสัยทัศน์ (Pressure), lore/chapter (Mimic), day-night escalation+co-op (99 Nights), jumpscare เป็นพีคนาน ๆ ครั้ง (FNAF ผ่าน HollowLakeScare). คงไว้: opt-out `DV_HorrorFxOptOut` + zone-gated

## 6. Class/Job system (ชิ้นถัดไป)
3 base (Warrior/Mage/Hunter = Sword/Bow/Staff) → 9 sub-class · gate Lv10/40/100 (align 7 tier) · per-class skill set ต่อยอด CombatConfig · server-authoritative (skill-of-class check + statMods) · trainer NPC ที่ EternityCity · ไม่เลือกคลาส=default (ไม่พังเกมเดิม) · ทุก sub-class solo-viable

## 7. Solo-friendly
social = โบนัส ไม่บังคับ · difficulty scale ตามจำนวนผู้เล่น · NPC แทนปาร์ตี้ (Pet/Mercenary มีแล้ว) · solo instance (horror + dungeon scale 1 คน) · Solhaven = ศูนย์กลาง solo · ต้องเพิ่ม Party-Size Scaling

## 8. นโยบายถาวร — Economy + PvP/Anti-Grief
- **no-P2W time-vs-convenience:** solo ฟรีครบแค่ช้ากว่า, social เร็วกว่าฟรี, เงินซื้อแค่สะดวก+สวย ห้ามขายพลัง (ยกเลิก "solo ต้อง P2W")
- **PvP opt-in zone-gated:** นอกโซนตีไม่มีผล/ไม่มีเอฟเฟกต์ต่อคนไม่ยินยอม, ranged PvE-only
- **Anti-grief:** ยกเลิก "ตีรำคาญ", ตีกัน=duel consensual, block/mute + GriefingGuard/RemoteGuard

## 9. ลำดับงานถัดไป (ยืนยัน)
1. Mobile-UX audit (prompt-pack พร้อม)
2. Class/Job system (Blueprint+prompt-pack พร้อม)
3. Race system (หลัง Class/Job — prompt-pack จะเขียนเพิ่ม)
4. Party-Size Scaling + Next-Gen Art track (mesh+PBR ต่อเผ่า/เมือง; ChatGPT เจนภาพ ต้องชน benchmark ก่อน deploy)

## เอกสารอ้างอิง (ในโปรเจกต์)
`MASTER-BLUEPRINT.md §13` · `world/FIVE-CITIES-REVISIT-2026-06.md` · `world/RACES-AND-HELLBOUND-LORE-2026-06.md` · `world/MMORPG-FPS-CITY-MAPPING-2026-06.md` · `world/SOLO-PLAYER-SUPPORT-2026-06.md` · `death-valley/HORROR-DESIGN-RESEARCH.md` · `POLICY-ECONOMY-PVP-ANTIGRIEF.md` · `CLASS-JOB-SYSTEM-BLUEPRINT.md` · `CURSOR-PROMPTS-MOBILE-UX-AUDIT.md`

## ✅ Action ฝั่ง Mac (ที่ Cowork ทำตรงไม่ได้)
- ingest ไฟล์นี้เข้า **MemPalace** (topic `utopia-of-eternity-design-direction`)
- คัดลอกเข้า **Obsidian** `~/Obsidian/knowledge_base/utopia-of-eternity-design-direction-2026-06-15.md`
- `git add` docs ใหม่/แก้ทั้งหมด + commit + push (keychain มี PAT)
