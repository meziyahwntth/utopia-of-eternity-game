# Diary — Weapon Icons Wave 2 integrated (14 มิ.ย. 2026)

- ตรวจภาพอาวุธใน docs/visual-ref/weapons/: เดิม 13 ไฟล์ ซ้ำ 1 คู่ (Celestial Longbow byte-identical #9=#10) → user ลบเอง
- user gen เพิ่ม 4 ตัวที่ขาด → ครบ 15 (Hammer, Twin Daggers, Cathedral/Blood-Moon Greatsword, Blue-Gold Longsword)
- copy 15 ภาพ → assets/weapons/generated/ ด้วยชื่อตาม catalog conceptArtFile
- AK47/M16/M4A1: แทนที่ของเดิม Wave 1 ด้วยภาพไอคอนใหม่ (ตาม user เลือก "แทนที่")
- Blue-Gold Longsword: เพิ่ม entry ใหม่ royal_longsword (royal-longsword.png) ใน catalog + manifest
- manifest.json: 13 → 25 weapons | catalog: +royal_longsword
- สถานะ: 25/34 อาวุธมี concept art | เหลือ 9 (prompts เขียนไว้ใน docs/WEAPON-ICON-PROMPT-GUIDE-WAVE2B.md)
- ค้าง (external): upscale 4x Krea.ai + upload Roblox → rbxassetid (โค้ดยังใช้ conceptArtFile string, ยังไม่มี rbxassetid path)

## อัปเดต (รอบ 2) — Wave 2B ครบ 34/34
- เจน 9 ตัวสุดท้ายผ่าน Claude in Chrome คุม ChatGPT image mode (Praphan Plus account)
- ดาวน์โหลด blob อัตโนมัติติด Chrome multiple-download block → user กดโหลดเองลง docs/visual-ref/weapons/
- จับคู่ชื่อด้วยขนาด byte (8/9 ตรงเป๊ะ, thunder-repeater โหลด A/B อีก variant ขนาดต่าง) + verify montage ภาพตรงทุกตัว
- copy เข้า assets/weapons/generated/ + manifest 25→34
- ผล: catalog 34/34 มีภาพ, ไม่มี md5 ซ้ำ, ไม่มีไฟล์เสีย
- ค้าง: upscale + upload Roblox → rbxassetid (ยังไม่มี field ในโค้ด)

## อัปเดต (รอบ 3) — อัปโหลด Roblox + wire iconAssetId ครบ 34
- bulk import 34 รูปเข้า Asset Manager ของ place "Utopia Weapon Assets" (สร้างใหม่ใต้ group Utopia of Eternity, groupId 791898614) — moderation Green ทุกตัว
- ดึง asset ID: Insert เป็น Decal → Lua print Texture → query ชื่อจาก develop.roblox.com/v1/assets?assetIds=... (navigate ใน Chrome)
- เขียน iconAssetId = "rbxassetid://..." ครบ 34/34 ใน PrismLegendaryWeaponsCatalog.luau + เพิ่ม field ใน type
- งานไอคอนอาวุธ = เสร็จสมบูรณ์

## อัปเดต (รอบ 4) — Vehicle/Mount/Pet concept art
- แก้ไอคอนอาวุธ 3 ตัว (prism-railgun/m16/m4a1) ที่ไม่ถูกใจ: เจนใหม่+อัปโหลด group+แก้ iconAssetId (railgun 70780110549894, m16 111095151841177, m4a1 103993968868095) moderation Green
- Vehicles 13 รูป (user เจน) จัดเข้า docs/visual-ref/eternity-city/vehicles/{tri,land,air,water}/ ตรง catalog refImage 14/14 entry
- Mounts 15 รูป (Cursor batch) → eternity-city/mounts/ ตรง catalog 15/15, ลบ orphan เก่า 4 ไฟล์ + normalize case
- Pets 18 รูป (Cursor batch) → docs/visual-ref/pets/pet-<id>.png ครบ 18 ตาม PetConfig
- เทคนิคใหม่: ให้ user สั่ง Cursor batch-gen (เร็วมาก ~52รูป/5นาที) — ผมทำไฟล์ *-CURSOR-BATCH.md (PATH+PROMPT ต่อรูป) ให้ก๊อปไปวาง
- ค้าง: อัปโหลด vehicle/mount/pet เข้า Roblox + wire (mount=refImage ทำโมเดล, pet icon=rbxassetid)
