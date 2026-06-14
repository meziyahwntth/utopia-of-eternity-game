# Diary — Next-Gen Direction + 2-Day Session Consolidation (15 มิ.ย. 2026)

> wing: utopia_of_eternity · สำหรับ MemPalace `knowledge_ingest` + คัดลอกเข้า Obsidian `~/Obsidian/knowledge_base/`

## ทิศทางใหม่ (Praphan ยืนยัน 15 มิ.ย.)
ยกระดับเป็น **Next-Gen mobile MMORPG** เทียบ Lineage W / Ragnarok Mobile — "แมพดีที่สุด ไม่เร่ง ทุกดีเทลดีที่สุด".
เป้าหมาย: กราฟิกสมจริงอลังการ, เนื้อเรื่องน่าตื่นเต้น, live-ops ของใหม่เรื่อย ๆ, กิจกรรมไม่รู้จบ, สังคมดี, แอดมินจริยธรรม (แบนบอท/ฟาร์มเข้ม).
**Art:** custom skinned mesh body + PBR (SurfaceAppearance) + lighting/atmosphere/animation/camera สมจริง. avatar = Roblox mesh เสมอ → ภาพ realistic-human = marketing/concept, wearable จริงทำบนทรง mesh.

## AI Asset Pipeline มาตรฐาน (doc: docs/AI-ASSET-WORKFLOW.md)
- 2D: ChatGPT DALL·E3 (ร่าง) → **Cursor**/Leonardo/Midjourney v6 (asset) → Krea.ai upscale 4K-8K → Asset Manager Decal/Image → StarterGui
- Env: Blockade Skybox AI · texture→NormalMap-Online→SurfaceAppearance · Roblox Material Generator
- 3D: ChatGPT→Meshy/Tripo→Blender(ลด poly)→Roblox 3D Importer→MeshPart
- Cowork ทำเอง: Cursor batch prompt, อัปโหลด/ดึง ID/wire, import mesh, publish, verify · ทำไม่ได้: เจนภาพ/mesh

## ✅ เสร็จแล้ว (14-15 มิ.ย., verified)
- Weapon icons 34/34 wired (group 791898614, Green)
- Vehicle/Mount/Pet: อัปโหลด 46 → PetConfig.icon emoji→rbxassetid ×18, VehicleMountCatalog.iconAssetId ×29 (doc: ASSET-IDS-VEHICLE-MOUNT-PET.md)
- Publish EternityCity v5→v6→v7 (Rojo live-sync + Publish, terrain-safe; default.project.json ไม่ map Workspace)
- MVP boss void_imp drop (eternal_warden MVP rank1 10%) + TradingClient credit offer UI (commit 976bbc3)
- **Auto-Lock Targeting System** (commit 75c955a): TargetingController(shared) + TargetingClient + AutoBattle refactor — tap-lock, ring+name/HP, Lock/Unlock mobile button (Scale+AspectRatio), server-auth คงเดิม
- Fashion: teen-trend 90/90 (Cursor wave2 ครบ), national 20, concepts 8
- Git: pushed ถึง 75c955a (origin/main); EternityCity live v7

## ⚠️ ต้องแก้ให้ตรงเป้า Next-Gen
- Avatar → custom mesh body (chibi-curvy/Next-Gen) + สูงขึ้น (ยังบล็อก default)
- teen-trend 90 รูป human-realistic → ตัดสิน: ปรับตรงทรง avatar หรือใช้ marketing + ทำ wearable บน mesh
- PBR pass อาวุธ/ฉาก/พื้นผิว (เพิ่ม SurfaceAppearance)
- Skybox/Lighting Next-Gen ต่อมิติ (Blockade)

## ▶️ Roadmap ถัดไป (Mobile-First — Matrix 80% มีแล้ว, doc MOBILE-FIRST-RPG-MATRIX.md)
1. Auto-Lock Targeting ✅ (รอ playtest/publish)
2. Skill Bar HUD มือถือ ⏳ ถัดไป
3. Mobile-UX audit (Scale+UIAspectRatioConstraint, collapsible/auto-hide) ⏳
4. Next-Gen Art track (mesh+PBR+skybox) ⏳ ขนาน

## เกร็ดเทคนิคที่ได้
- Rojo connection ค้างไว้ได้ → แก้ไฟล์แล้ว live-sync เข้า place อัตโนมัติ ไม่ต้อง Connect ใหม่; verify ด้วย require/script.Source ใน command bar ก่อน Publish
- แยก place ซ้ำชื่อ "Utopia of Eternity" ด้วย right-click→Copy ID (EternityCity=94486544638073, Hub start=119887759427070)
- git push ผ่าน .command (keychain เก็บ PAT — push เงียบสำเร็จ)

## Blueprint ที่อัปเดต
MASTER-BLUEPRINT.md §12 (Next-Gen + 2-day progress) · AI-ASSET-WORKFLOW.md (Cursor primary) · MOBILE-FIRST-RPG-MATRIX.md · ASSET-IDS-VEHICLE-MOUNT-PET.md
