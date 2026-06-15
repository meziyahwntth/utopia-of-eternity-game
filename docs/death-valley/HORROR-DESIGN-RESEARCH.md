# Death Valley (ดาว Hellbound) — Horror Design Research & คำแนะนำ

> 15 มิ.ย. 2026 · คำถาม Praphan: เอาแนว FNAF 2: Reimagined (jumpscare โหด) มาใช้กับหุบเขามรณะไหม อย่างไร
> วิจัยจากเกม horror ยอดนิยมปัจจุบันบน Roblox (มิ.ย. 2026)

## TL;DR คำแนะนำ
**ใช้ — แต่ "ไม่ลอกทั้งดุ้น"** FNAF เป็นลูปเดี่ยว/สถานที่ตายตัว/jumpscare เป็นแกนหลัก ซึ่งไม่เข้ากับ MMORPG survival zone
ให้ยืม **หลักการ atmosphere + sound design + entity-AI** จาก DOORS/Pressure/The Mimic เป็นแกน แล้วใช้ **jumpscare แบบ FNAF เป็น "เครื่องหมายวรรคตอน"** (นาน ๆ ครั้ง, จังหวะพีค) ผูกกับระบบ Wraith/HollowLakeScare ที่มีอยู่แล้ว
หุบเขามรณะ**มีโครงพร้อมแล้ว** (HorrorFX, WraithFactory, NightService, Spirit Chamber, Weekly Boss, Hellbound travel) → งานคือ **"ทำให้ลึกขึ้น" ไม่ใช่แปะ FNAF ทับ**

## เกม benchmark ปัจจุบัน + บทเรียนที่ใช้ได้
| เกม | จุดแข็ง | บทเรียนสำหรับหุบเขามรณะ |
|---|---|---|
| **DOORS** (5B+ visits) | ห้อง procedural + entity เสียงเฉพาะตัว → Pavlovian (กลัวเสียงก่อนสมองคิดทัน) | ผีแต่ละตัวต้องมี **เสียง cue เฉพาะ + พฤติกรรมต่างกันที่เรียนรู้ได้** (เช่น Rush มาเร็ว ต้องหลบในล็อกเกอร์) → ออกแบบ Wraith ให้มี "ภาษา" เสียงของมันเอง |
| **Pressure** | ใต้น้ำ จำกัดวิสัยทัศน์+กลบเสียง → อึดอัด + ต้องพึ่งการสื่อสาร | **environmental constriction**: หมอก/มืด/พายุทราย/เสียงอู้ในหุบเขา ทำให้กลัวได้พอ ๆ กับตัวผี + บังคับเล่นเป็นทีม |
| **The Mimic** (เรตติ้งสูงสุด solo) | psychological horror, เนื้อเรื่องแบ่ง "Books/Chapters" ยาว | ใส่ **lore + chapter** ให้หุบเขา (ทำไมมันร้าง ใครคือ Wraith) → horror ที่มีเรื่องเล่าติดทนกว่า jumpscare ล้วน |
| **Flee the Facility / Piggy** | asymmetric multiplayer chase (ล่า/หนี) | โหมด event: ผู้เล่นบางคน/บอสไล่ล่า ที่เหลือหนี → ใช้ต่อยอด Weekly Boss/Spirit Chamber |
| **Specter / Phasmophobia-like** | investigation ใช้เครื่องมือหาผี | กิจกรรมสาย "สืบ" ในหุบเขา (เก็บหลักฐาน/ระบุชนิดผี) เป็น loop เสริมนอกจากสู้ |
| **FNAF 2: Reimagined** | jumpscare + animatronic AI + lighting/atmosphere ระดับ AAA | เอา **คุณภาพ lighting/atmosphere + จังหวะ jumpscare** มาเป็นแรงบันดาลใจ (ตรงกับ [[feedback-graphics-benchmark]]) |

## หลักออกแบบความกลัว (Roblox-specific)
- Roblox ห้าม gore/ความรุนแรงกราฟิก → เกมดังเลยชนะด้วย **atmosphere + เสียง + จิตวิทยา** ไม่ใช่เลือด (ข้อจำกัดนี้บังคับให้สร้างสรรค์)
- **Sound design = อาวุธหลัก**: ambient อึดอัดต่อเนื่อง + cue เฉพาะตัวผี (DOORS พิสูจน์ว่า conditioned reflex สร้าง anxiety จริง)
- **ความมืด/วิสัยทัศน์จำกัด** > ตัวผีโผล่ตรง ๆ (creeping dread)
- jumpscare ดีต่อเมื่อ **หายาก + คาดเดายาก**; ถ้าบ่อย = ชา

## วิธีประยุกต์กับหุบเขามรณะ (map กับไฟล์ที่มีอยู่จริง)
1. **Entity "ภาษา" เสียง+พฤติกรรม** → ต่อยอด `DeathValleyWraithFactory.luau` + `WraithAlert`: ให้ Wraith มีหลายชนิด แต่ละชนิดมี audio cue + pattern หลบเฉพาะ (เลียน DOORS)
2. **Atmosphere ลึกขึ้น** → `DeathValleyNightService` + `DeathValleyHorrorFX` (vignette มีแล้ว): เพิ่ม dynamic fog/lighting/พายุทราย ตามรอบกลางวัน-คืน, ค่อย ๆ บีบวิสัยทัศน์ตอนคืนลึก (เลียน Pressure) — คุณภาพต้องชน [[feedback-graphics-benchmark]]
3. **Lore/Chapter** → ใส่เรื่องเล่าหุบเขา/Hellbound ใน `HELLBOUND-TRAVEL-AND-DEATH-VALLEY.md` + POI (`DeathValleyPOIService`): collectible lore, ปริศนาเปิดเรื่อง (เลียน The Mimic)
4. **jumpscare แบบ FNAF เป็นพีค** → `HollowLakeScare` ที่มีอยู่: ใช้เฉพาะจุด/เงื่อนไขพิเศษ (เข้า Spirit Chamber, บอสปรากฏ) ไม่สุ่มบ่อย
5. **โหมด chase/investigation** → ต่อยอด `DeathValleyWeeklyBossService` + `DeathValleySpiritChamberService`: event ไล่ล่า หรือ loop สืบหาผี

## ข้อควรระวัง (สำคัญ)
- **horror ต้อง zone-gated + opt-in**: เกมรวมเป็น MMORPG สังคม (Eternity City = cozy) อาจมีผู้เล่นอายุน้อย → ความสยองต้องอยู่เฉพาะดาว Hellbound/หุบเขามรณะ ซึ่ง**มีกำแพงอยู่แล้ว**: ต้องเดินทางผ่าน `HellboundTravelService` + `DeathValleyHorrorFX` มีปุ่ม **opt-out (`DV_HorrorFxOptOut`)** อยู่แล้ว → คงไว้/ทำให้เด่น
- **Mobile-first**: jumpscare/เสียงทำงานบนมือถือได้ แต่ระวัง performance (particle/lighting) + เคารพ opt-out + ไม่บัง HUD combat (ผูกกับงาน Mobile-UX audit ที่กำลังจะทำ)
- **โค้ดทั้งหมด → ส่ง Cursor** ([[feedback-delegate-to-cursor]]); Cowork ทำ asset import/playtest/publish

## ถัดไป
ถ้าอนุมัติทิศทางนี้ → ทำ **Blueprint แยกระบบ horror** (entity types + audio map + atmosphere phases + lore) แล้วแตกเป็น Cursor prompt-pack (ทำหลัง/คู่ขนานกับ Mobile-UX audit)
