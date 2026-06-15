# HANDOFF — Fix EternityCity v10 → re-publish correct code as v11

## บริบท (อ่านก่อน)
EternityCity (Roblox MMORPG) — โค้ดล่าสุดที่ถูกต้องอยู่ใน git แล้ว (origin/main = commit `da7ef00`, pushed).
**ปัญหา:** มี `.command` รันโดยไม่ตั้งใจ → `utopia-publish-eternitycity.command` publish **EternityCity เป็น v10 จากไฟล์ `utopia-playtest.rbxlx` (เก่า/อาจ stale)** อาจทับโค้ด v9 ที่ถูกต้องที่ live อยู่
**เป้าหมาย:** publish ใหม่เป็น **v11** จาก Studio ที่ Rojo-sync โค้ดล่าสุด เพื่อให้ live = ถูกต้อง

## โค้ดที่ต้อง live (อยู่ใน src แล้ว, committed)
- **Auto-Lock Targeting:** `ReplicatedStorage/Modules/TargetingController.luau`, `StarterPlayer/StarterPlayerScripts/TargetingClient.client.luau`, refactor `AutoBattleClient.client.luau` (commit 75c955a)
- **Skill Bar HUD:** `SkillBarClient.client.luau`, `CombatConfig.luau` (Skills + SkillCooldown), `CombatService.luau` (server per-skill cooldown) (commit dd20466)
- **Support button fix:** `SupportDeskUI.client.luau` ย้ายขึ้น -240 พ้น combat cluster (commit da7ef00)

## ขั้นตอน (ทำใน Cowork หน้าต่างใหม่)
1. **เปิด Rojo serve:** double-click `~/Desktop/Utopia of Eternity/utopia-rojo-serve.command` (รัน `rojo serve` :34872) — เปิดทีละไฟล์เท่านั้น **อย่า** เลือกหลายไฟล์ใน Finder
2. **เปิด EternityCity ใน Studio:** Studio start page → Experiences → Group Experiences → "Utopia of Eternity" (universe 10293115628) → double-click → ได้ start place = Hub → Asset Manager → Places → **right-click place → Copy ID to Clipboard → ต้องได้ `94486544638073`** (มี "Utopia of Eternity" ซ้ำ 2 แถว; แถวที่ไม่มี gear = EternityCity; gear = Hub) → double-click เปิด (grid-view double-click เวิร์ค, list-view บางทีไม่) → ยืนยัน Output `DataModel Loading ...id=94486544638073`
3. **Rojo Connect:** popup "serving at localhost:34872" → Connect → review diff (ควรเป็น additive/modify โค้ด ไม่มี deletion แปลก ๆ) → Accept. **terrain ปลอดภัย** เพราะ `default.project.json` ไม่ map Workspace
4. **Verify ใน Studio command bar** (พิมพ์แล้ว**กดปุ่ม Run** ไม่ใช่ Enter — Enter = ขึ้นบรรทัดใหม่):
   ```lua
   local rs=game.ReplicatedStorage.Modules local sp=game.StarterPlayer.StarterPlayerScripts
   local okT=pcall(function() return require(rs.TargetingController) end)
   local t=workspace:FindFirstChildOfClass("Terrain")
   print("VERIFY targetingOK="..tostring(okT).." terrain="..tostring(t~=nil))
   print("VERIFY skillbar="..tostring(sp:FindFirstChild("SkillBarClient")~=nil).." targetingClient="..tostring(sp:FindFirstChild("TargetingClient")~=nil))
   print("VERIFY supportFix="..tostring(string.find(sp.SupportDeskUI.Source,"-240")~=nil))
   ```
   (ถ้า require cache ค้าง ให้ clone module แล้ว require: `local c=rs.CombatConfig:Clone() c.Parent=workspace print(#require(c).Skills) c:Destroy()`)
5. **(แนะนำ) Playtest:** กด Play → เช็ก skill bar (⚔💥🌀 + ⤴ Jump) มุมขวาล่าง, Support ขึ้นไปอยู่บน, ไม่มี error ใน Output → Stop
6. **Publish:** File → Publish to Roblox (⌥P) → ควรได้ **v11** "Place published" → ยืนยัน Output "Add publish notes to v11"
7. **Update memory:** MEMORY.md + project-cloud-workflow.md (EternityCity v11), บันทึก incident (v10 accidental publish จาก stale rbxlx → แก้ด้วย re-publish v11)

## ⚠️ กฎกันพลาดซ้ำ
- **ห้าม** ใช้ Finder เลือกหลายไฟล์ + double-click/Cmd+O (รอบก่อนเปิด ~100 หน้าต่าง + รัน publish/meshy โดยไม่ตั้งใจ)
- **ห้าม** ใช้ `utopia-publish-eternitycity.command` (publish จาก utopia-playtest.rbxlx ที่ stale) — publish ผ่าน Studio Rojo-sync เท่านั้น
- **git push:** ให้ Praphan รันเอง (keychain มี PAT): `cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game && git push origin main`
- งานค้างอื่น: commit รูป teen-trend wave2 60 ไฟล์ (ยัง untracked); MemPalace/Obsidian ingest `docs/mempalace/2026-06-15-*.md` ฝั่ง Mac

## Key IDs / paths
- EternityCity place `94486544638073` · universe `10293115628` · Hub start `119887759427070` · group `791898614`
- repo: `~/Desktop/Utopia of Eternity/utopia-of-eternity-game` · origin/main = `da7ef00`
- docs: `MASTER-BLUEPRINT.md` §12, `MOBILE-FIRST-RPG-MATRIX.md`, `AI-ASSET-WORKFLOW.md`
- roadmap ถัดไปหลังแก้: Mobile-UX audit → Next-Gen Art track (mesh+PBR+skybox)
