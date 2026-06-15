# ทบทวนแผน 5 เมือง — เนื้อเรื่อง · ระบบ · การเดินเกม · เมืองแข่งรถ

> 15 มิ.ย. 2026 · อิง GameConfig.Places จริง + [[feedback-graphics-benchmark]] + horror research
> เป้า: ทุกเมือง/รถ/ไอเทม ต้อง **ดีกว่าหรือเทียบเท่าเกมยอดฮิตปัจจุบัน** ก่อน deploy (Praphan)
> โค้ด → Cursor · ภาพ → ChatGPT Pro · Cowork → import/playtest/publish

## เส้นทางเดินเกม (จริงใน GameConfig)
`Hub → Solhaven → Nocturne → EternityCity → DeathValley(ดาว Hellbound)` + **NeonUtopia = จุดเกิดแรกของผู้เล่นใหม่**

## ภาพรวมบทบาทแต่ละเมือง (ปรับให้ไม่ทับกัน — แต่ละเมือง "เด่นคนละเรื่อง")
> 🆕 ผูกเผ่าแล้ว (15 มิ.ย.) — ดู `RACES-AND-HELLBOUND-LORE-2026-06.md`
| เมือง | เผ่า | dayMode | บทบาทหลัก (proposed) | benchmark ที่ต้องชน |
|---|---|---|---|---|
| **NeonUtopia** | Human | radiant_day | **เมืองมนุษย์ + ONBOARDING + เมืองแข่งรถ** ⭐ | Velocity Outlast (รถ), Brookhaven (social) |
| **Solhaven** | Elf | permanent_day | Sanctuary / cozy hub + crafting + ตลาด/ร้านเช่า + ศูนย์กลาง solo | Grow a Garden, Adopt Me (cozy/economy) |
| **Nocturne** | Dark Elf | permanent_twilight | Social/nightlife + PvP arena + street-race track รอง | BloxFruits (combat), club games |
| **EternityCity** | Alien | permanent_day | เมืองลอยฟ้า flagship — endgame social, landmark, clan/territory | (เมือง flagship — ชน Nexus เรื่องกราฟิก) |
| **DeathValley** | Orc (สูญพันธุ์) | eternal_night | Horror survival co-op (ดาว Hellbound) | DOORS, The Mimic, 99 Nights, Pressure |

---

## 1) NeonUtopia — เมืองมนุษย์ / Onboarding / **เมืองแข่งรถ** ⭐ (แนะนำ)
**เนื้อเรื่อง:** มหานครมนุษย์ neon-cyberpunk จุดเริ่มต้นก่อนค้นพบประตูสู่ Utopia ลอยฟ้า — โลกเทคโนโลยีที่ "รถ/ยานยนต์" มี lore สมเหตุผลที่สุด (เมืองอื่นเป็นสวรรค์ลอยฟ้า/สถานศักดิ์สิทธิ์/นรก จึงไม่เหมาะรถ)
**ทำไมควรเป็นเมืองแข่งรถ:** (1) ธีม neon = สุนทรียะการแข่งรถโดยแท้ (2) radiant_day → แข่งได้ทั้งกลางวันโชว์ดีเทลรถแบบ Velocity Outlast และโหมดกลางคืน neon (3) เป็นเมือง traffic สูงสุด (ผู้เล่นใหม่เกิดที่นี่) → โชว์รถได้กว้าง (4) lore รถลงตัว
**ระบบ:**
- Onboarding 5 นาที (สอนเล่น → เจอ Air Transport ไป EternityCity)
- **Racing system**: สนาม/เส้นทางในเมือง, time-trial + เวฟแข่งหลายคน, leaderboard, รางวัลเป็นกุญแจ/เครดิต/cosmetic รถ (Grandeur Rank)
- โชว์รูม/อู่แต่งรถ (เชื่อม catalog ไอเทม Grandeur + VehicleMount ที่มีอยู่)
**Loop:** เกิด → เรียนรู้ → แข่ง/แต่งรถ → ขึ้นยานไป Utopia
**ภาพ (ChatGPT):** เมือง neon-cyberpunk กลางวันสว่าง + กลางคืน neon, ถนน/สนามแข่ง, ซูเปอร์คาร์ PBR สมจริง (อ้างอิงคุณภาพ Velocity Outlast)

## 2) Solhaven — Sanctuary / Cozy / เศรษฐกิจ
**เนื้อเรื่อง:** ดินแดนแสงอาทิตย์นิรันดร์ "Sunhaven Sanctuary" — เมืองพักใจ สงบ ปลอดภัย
**ระบบ:** crafting (ItemCraftingConfig), ตลาด/ร้านเช่า (Shop Rental ที่ทำแล้ว), สวน/เก็บเล็กผสมน้อย cozy, daily quest/streak
**Loop:** พัก → คราฟต์/ค้าขาย → เตรียมของก่อนไปโซนยาก
**benchmark:** Grow a Garden / Adopt Me (cozy + player economy)
**ภาพ:** เมืองแสงทองอบอุ่น สถาปัตยกรรม sanctuary, สวน, ตลาด

## 3) Nocturne Alley — Nightlife / PvP / Street-race รอง
**เนื้อเรื่อง:** ตรอกสนธยานิรันดร์ — ย่านราตรี คึกคัก ลึกลับ
**ระบบ:** social/club, **PvP arena** (combat ที่มี Auto-Lock/Skill Bar แล้ว), ภารกิจกลางคืน, **night street-race/drift track** (ธีม alley+twilight เหมาะมาก — เป็นแทร็กรองของ NeonUtopia)
**Loop:** สังคม → PvP/แข่งกลางคืน → ล่ารางวัล
**benchmark:** BloxFruits (combat depth), club/nightlife games
**ภาพ:** ตรอก neon twilight, ป้ายไฟ, แทร็กดริฟต์กลางคืน

## 4) EternityCity — เมืองลอยฟ้า flagship (endgame social)
**เนื้อเรื่อง:** "The Eternal City" นครสรวงสวรรค์ลอยเหนือเมฆ — ปลายทางความใฝ่ฝัน
**ระบบ:** endgame social hub, landmark (Marina/Aurora/Canal/SkyRail), **Clan War/territory + ภาษีร้าน** (มี ClanWar แล้ว), guild, live-ops/season, จุดขึ้น Hyper Space ไป Hellbound
**Loop:** อวดสถานะ/ฉายา tier → clan war ชิงเขต → live-ops
**benchmark:** ชน Nexus เรื่อง lighting/atmosphere/PBR (เมืองนี้คือหน้าตาเกม)
**ภาพ:** เมืองลอยฟ้าเหนือเมฆ แสงทอง คุณภาพระดับ AAA (สำคัญสุดเพราะเป็น flagship)

## 5) DeathValley (ดาว Hellbound) — Horror Survival Co-op
**เนื้อเรื่อง:** หุบเขามรณะ ราตรีนิรันดร์บนดาวต่างมิติ Hellbound — เอาตัวรอด + ปลดปริศนา/lore ว่าทำไมร้าง
**ระบบ (ต่อยอด horror research → [[../death-valley/HORROR-DESIGN-RESEARCH.md]]):**
- Entity เสียง+พฤติกรรมหลายชนิด (DOORS), atmosphere บีบวิสัยทัศน์กลางคืน (Pressure), lore/chapter (The Mimic), วัฏจักรกลางวัน-คืน + escalation + co-op (99 Nights), jumpscare เป็นพีคนาน ๆ ครั้ง (FNAF) ผ่าน HollowLakeScare ที่มีอยู่
- คงไว้: opt-out horror (`DV_HorrorFxOptOut`), zone-gated (ต้อง travel เข้า) — กันผู้เล่นอายุน้อย
**Loop:** เดินทางเข้า → กลางวันเตรียม/กลางคืนเอาตัวรอด → แลกวิญญาณวีรชน → escalation
**benchmark:** DOORS, The Mimic, 99 Nights, Pressure, Specter
**ภาพ:** หุบเข้ามืดต่างมิติ, หมอก/พายุทราย, สิ่งมีชีวิตน่าขนลุก (ไม่เน้น gore — เน้น atmosphere)

---

## เมืองแข่งรถ: สรุปคำแนะนำ
**แนะนำ NeonUtopia เป็นเมืองแข่งรถหลัก** (เหตุผลด้านบน) + **Nocturne Alley = แทร็กดริฟต์กลางคืนรอง**
*ทางเลือก:* ถ้าต้องการแยก "เมืองแข่งรถเฉพาะทาง" ออกจาก onboarding → ยก Nocturne เป็นเมืองแข่งรถหลักแทน (ธีม street-race จัดกว่า แต่ traffic น้อยกว่า)

## หลักที่ต้องคุมทุกเมือง
- **กราฟิก:** ทุก asset ต้องชน benchmark ([[feedback-graphics-benchmark]]) — ChatGPT Pro เจน concept/ortho ref → pipeline mesh+PBR ([[../AI-ASSET-WORKFLOW.md]])
- **Mobile-first:** ทุก UI/ระบบผ่าน Mobile-UX audit ที่กำลังทำ
- **ความต่อเนื่อง lore:** รถ/ยานยนต์อยู่ฝั่งเมืองมนุษย์ (NeonUtopia/Nocturne); เมืองลอยฟ้า/sanctuary/horror ใช้ขนส่งคนละแบบ (Air Transport/Hyper Space/เดินเท้า)

## ถัดไป
เลือกเมืองแข่งรถ → ผมทำ Blueprint เมืองนั้น (เส้นทาง/ระบบแข่ง/รางวัล) + ชุด ChatGPT prompt เจนภาพเมือง+รถ แล้วแตก Cursor prompt-pack สำหรับโค้ด
