# 2026-06-15 — EternityCity v11 re-publish (fix stale v10)

## สรุป
แก้เหตุ accidental publish **v10** แล้ว re-publish โค้ดที่ถูกต้องเป็น **v11**

## Incident
- มี `.command` ถูกรันโดยไม่ตั้งใจ (Finder multi-select) → `utopia-publish-eternitycity.command` publish EternityCity เป็น **v10 จากไฟล์ `utopia-playtest.rbxlx` ที่ stale** → อาจทับโค้ด v9 ที่ถูกต้องที่ live อยู่
- โค้ดล่าสุดที่ถูกต้องอยู่ใน git: `origin/main = da7ef00` (Auto-Lock Targeting 75c955a + Skill Bar HUD dd20466 + Support fix da7ef00)

## วิธีแก้ (ทำใน Cowork)
1. Studio เปิด EternityCity อยู่แล้ว — ยืนยัน `PlaceId=94486544638073` ผ่าน command bar
2. Rojo (7.6.1) connected `localhost:34872` (utopia-of-eternity) — live-sync git ล่าสุดเข้า place แล้ว (terrain ปลอดภัย, Workspace ไม่ถูก map)
3. Verify ใน command bar ผ่านครบ:
   - `targetingOK=true terrain=true`
   - `skillbar=true targetingClient=true`
   - `supportFix=true` (SupportDeskUI มี "-240")
4. Playtest: โลก build สำเร็จ (aurora · marina · canal · gates · Sky Lounge 50 · loadout plaza), Skill Bar HUD 4 ปุ่ม ⚔💥🌀⤴ มุมขวาล่าง, Support ย้ายขึ้นด้านบน, ไม่มี error (มีแค่ warning FashionShow "cancelled 0/1 players" ตามปกติของ solo test)
5. File → Publish to Roblox → **"Place published... Add publish notes to v11"** ✅

## บทเรียน / กฎกันพลาด
- **เลี่ยง** `utopia-publish-eternitycity.command` (POST จาก `.rbxlx` ที่อาจ stale) — ใช้ **Rojo-sync + Studio Publish** แทน (ตรงกับ git เสมอ)
- **ห้าม** Finder multi-select + double-click/Cmd+O (ทำให้รัน .command โดยไม่ตั้งใจ)

## งานค้าง (ฝั่ง Praphan)
- `git push origin main` (Praphan รันเอง — keychain มี PAT)
- commit รูป teen-trend wave2 (~60 ไฟล์ untracked)
- ingest diary entries ฝั่ง Mac (MemPalace/Obsidian)
- ถัดไป: Mobile-UX audit → Next-Gen Art track (mesh+PBR+skybox)
