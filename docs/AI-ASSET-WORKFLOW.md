# AI Asset Pipeline — มาตรฐานการสร้าง Asset (Utopia of Eternity)

> Workflow มาตรฐานสำหรับสร้างภาพ/โมเดล Next-Gen แล้ว import เข้า Roblox Studio ได้จริง
> (กำหนดโดย Praphan · 15 มิ.ย. 2026)

## 1. UI & 2D Assets Pipeline
- **ร่าง/Concept:** ChatGPT (DALL·E 3) ทำ Orthographic Reference / concept art เบื้องต้น
- **ผลิตจริง:** Leonardo.ai + Midjourney v6 **หรือ Cursor** สร้าง game assets (skill icon, Card/Rune, Radial Menu button) — เน้นคมชัด + สไตล์เป็นเอกภาพ
- **Upscale:** Krea.ai อัป 4K–8K กันภาพแตกบนมือถือ (Mobile-First UX)
- **Import:** อัปโหลดเข้า **Asset Manager** เป็น Decal/Image → ใช้ใน StarterGui

## 2. Environment & World Building
- **ท้องฟ้า:** Blockade Labs (Skybox AI) สร้าง 360° skybox ต่อมิติ
- **พื้นผิว PBR:** Leonardo.ai/ChatGPT เจน flat texture → เว็บ **NormalMap-Online** ทำ normal/roughness → ใส่ใน `SurfaceAppearance`
- **ทางลัด:** Roblox Built-in Material Generator สำหรับพื้นผิวธรรมชาติเร็ว ๆ

## 3. 3D Meshes & Weapons
- **Props/อาวุธ:** ภาพร่างจาก ChatGPT → **Meshy.ai** หรือ **Tripo3D** แปลงเป็น 3D + PBR maps ครบ
- **Import:** โหลด .FBX/.OBJ → ลด poly ใน Blender (optimize mobile) → 3D Importer ใน Roblox Studio → MeshPart

---

## บทบาทในการทำงานร่วม (ใครทำส่วนไหน)
| ขั้นตอน | ใครทำ |
|---|---|
| เจนภาพ 2D/texture/skybox (DALL·E/Leonardo/MJ/Krea/Blockade) | **Praphan หรือ Cursor** (Cowork ไม่มีเครื่องมือเจนภาพในตัว) |
| สร้าง Cursor batch prompt จาก *IMAGE-PROMPTS*.md | **Cowork** |
| 3D (Meshy/Tripo/Blender) | **Praphan** (เครื่องมือนอก) |
| NormalMap-Online (เว็บ) | Cowork ขับผ่าน Chrome ได้ (ทีละภาพ ช้า) / หรือ Praphan |
| **อัปโหลด Asset Manager + ดึง asset ID + wire เข้า catalog/StarterGui** | **Cowork** (จุดแข็ง) |
| **3D Importer → MeshPart + จัดวางใน Studio** | **Cowork** (computer-use) |
| Publish ขึ้น Roblox (Rojo sync + Publish) | **Cowork** |
| Verify (montage, require, playtest) | **Cowork** |

## ข้อตกลงชื่อไฟล์
- บันทึกตาม path/field ใน catalog เสมอ (`conceptArtFile`/`refImage`/`icon`/`iconAssetId`)
- ตัวอย่างชุดงาน + batch: `docs/visual-ref/**/IMAGE-PROMPTS*.md` + `*-CURSOR-BATCH.md`
