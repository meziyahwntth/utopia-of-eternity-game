# Diary — Vehicle/Mount/Pet asset IDs wired (15 มิ.ย. 2026)

## งานที่ทำ
อัปโหลดภาพ 46 รูป (13 vehicle + 15 mount + 18 pet) เข้า group **Utopia of Eternity** (791898614)
ผ่าน Studio Asset Manager bulk import (place "Utopia Weapon Assets") แล้ว wire เข้า catalog:

- **PetConfig.luau** — เปลี่ยนฟิลด์ `icon` จาก emoji → `rbxassetid://...` ครบ 18 ตัว
- **VehicleMountCatalog.luau** — เพิ่ม type field `iconAssetId: string?`, ตาราง local `ICONS[id]`,
  และ `iconAssetId = ICONS[id]` ใน entry() ครบ 29 entry. **refImage คงเดิม** (ไว้ทำโมเดล 3D ตามที่ user สั่ง)

## ผลตรวจสอบ
- pets: 18/18 wired, asset id ไม่ซ้ำ, ไม่เหลือ emoji
- vehicle/mount: 29/29 entry มี icon key ครบ, dup เดียว = bus/shuttle ใช้รูปเดียวกัน (ตั้งใจ)
- ตาราง ID เต็ม: `docs/visual-ref/ASSET-IDS-VEHICLE-MOUNT-PET.md`

## บทเรียน / เทคนิค
- **Asset Manager multi-select ผ่าน automation ไม่ทำงาน** — Shift+click, Cmd+A ไม่ขยาย selection
  (context menu มีแค่ Insert / Copy ID to Clipboard ไม่มี Select All)
- วิธีที่ได้ผล: **ให้ user เลือกทั้งหมดเอง + Insert เป็น Decal** → command bar รัน
  `MarketplaceService:GetProductInfo(tonumber(id)).Name` เพื่อ print `Images/<basename>=id`
  → ได้ name→id mapping เป๊ะ ไม่ต้องอ่านเลขดิบจาก screenshot (เสี่ยง OCR ผิด)
- ทางเลือก: Copy ID to Clipboard ทีละไฟล์ + read_clipboard (เชื่อถือได้แต่ช้า 46 รอบ)
- ล้าง decal ชั่วคราวออกจาก workspace หลังดึง ID เสร็จ

## Deploy (15 มิ.ย. 2026)
- **git commit `d16c2ff`** (รวม catalog + art 46 รูป + prompt guides) — push ยังค้าง (ต้องใช้ PAT ของ Praphan: `git push origin main`, มี 6 commits)
- **EternityCity 94486544638073 published v5→v6** ผ่าน Rojo serve + sync ใน Studio + File→Publish to Roblox
  - terrain-safe (default.project.json ไม่ map Workspace) — sync เป็น additive ใหญ่เพราะ place เดิม (v5) เก่ามาก ขาดหลายระบบ
  - verify ใน Studio: pets=18 icon1=rbxassetid://138487953541573, vm=29 icon1=rbxassetid://131937012876652, terrain=true
  - place อื่น (Hub/Solhaven/Nocturne/DeathValley/NeonUtopia) ยังไม่ได้ deploy รอบนี้

## งานถัดไป (ค้าง)
- `git push` (Praphan ใส่ PAT)
- โมเดล 3D vehicle/mount จาก refImage
- pet modelId ยัง = rbxassetid://0 (ยังไม่มีโมเดล 3D)
- (ถ้าต้องการ) deploy โค้ดล่าสุดไป place อื่นด้วยวิธีเดียวกัน
