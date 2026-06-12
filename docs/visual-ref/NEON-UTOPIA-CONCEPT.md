# Neon Utopia — Visual Concept (จาก ref Praphan 12 มิ.ย. 2026)

> ภาพอ้างอิงถูก paste ในแชต (ยังไม่ได้เซฟเป็นไฟล์) — ถ้าจะ generate hero mesh แบบ Aurora/SkyRail
> ให้ลากไฟล์ภาพจริงเข้า `docs/visual-ref/city-concept/NeonUtopia-1.png` และ `NeonUtopia-2.png`

## โทน / Aesthetic
**ไม่ใช่ cyberpunk มืด** — เป็น **มหานครอนาคตหรูหรา กลางวันสว่าง** ("neon" = ไฟ accent ฟ้าเรืองแสง ไม่ใช่ความมืด)

- **วัสดุ:** ตึกโค้งลื่นไหลสีขาว + ขอบทอง + กระจกสะท้อน (organic flowing, ฐานบานออกเหมือนหยดน้ำคว่ำ)
- **น้ำ:** คลอง/ทะเลสาบสีเทอร์ควอยซ์ใสไหลผ่านเมือง, ขอบริมน้ำมีแถบไฟ cyan เรืองแสง
- **ธรรมชาติ:** หาดทรายขาว, ต้นปาล์ม, สวนเขียว, สะพานโค้ง
- **ลานกลางเมือง:** วงกลมพิธีกรรม มี **พอร์ทัล/ตาเรืองแสงสีฟ้า** สมมาตรรัศมี → ใช้เป็น **จุดขึ้นยานขนส่ง / ประตูข้ามมิติ** (P2)
- **บรรยากาศ:** ภาพ 1 = กลางวันฟ้าใส, ภาพ 2 = aerial sunset ทอง

## ใช้ใน builder ปัจจุบัน (greybox — `NeonUtopiaWorldBuilder.luau`)
- Lighting กลางวันสว่าง (ClockTime 14, Brightness 2.2)
- พื้นหินอ่อน Pearl + คลองน้ำเทอร์ควอยซ์กลางเมือง
- ตึกขาว-กระจก + ขอบทอง + แถบ neon cyan
- ลานพอร์ทัล: แท่นกลมหินอ่อน + ดิสก์พอร์ทัลเรืองแสงฟ้า (`TransitPortalDisc`) + `AirTransportDeparturePad` (P2 hook)

## งานต่อยอด (future)
- Hero mesh ตึกโค้งหยดน้ำ (Meshy pipeline เหมือน Aurora/SkyRail) เมื่อมีไฟล์ภาพจริง
- น้ำจริงด้วย Terrain water แทน greybox part
- สะพานโค้งเชื่อมตึก
