# CURSOR PROMPT — Verify P1/P2/P3-A (build + Luau type-check)

> Cowork (Claude) เขียนโค้ดชุดนี้ไว้ (เมืองลอยฟ้า, ขนส่ง, ระบบสังคม) ผ่าน static check แล้ว แต่ **sandbox ไม่มี rojo** เลย verify build/type ไม่ได้ ฝาก Cursor รัน verify บน Mac ให้หน่อยครับ

## งานที่ขอ (ตามลำดับ)

### 1. rojo build
```bash
cd "$HOME/Desktop/Utopia of Eternity/utopia-of-eternity-game"
export PATH="$HOME/.aftman/bin:$HOME/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
rojo build default.project.json -o /tmp/utopia-verify.rbxlx && echo "BUILD OK"
```
→ รายงานว่า **BUILD OK** หรือ error (ไฟล์ + บรรทัด)

### 2. Luau type-check (--!strict) — ถ้ามี luau-lsp/luau-analyze
```bash
# ถ้ามี luau-lsp:
luau-lsp analyze --settings='{"luau-lsp.require.mode":"relativeToFile"}' src/ 2>&1 | head -60
# หรือถ้ามี luau (binary):
# luau-analyze src/ServerScriptService/Social/*.luau
```
→ รายงาน type error/warning (โดยเฉพาะไฟล์ใหม่ด้านล่าง) — ถ้าไม่มีเครื่องมือ ข้ามได้

## ไฟล์ใหม่/แก้ไขที่อยากให้เน้น (P3-A Social = ใหม่สุด ยังไม่เคย build)
**ใหม่ (Social — เน้นสุด):**
- `src/ReplicatedStorage/Modules/SocialConfig.luau`
- `src/ServerScriptService/Social/SocialRemoteSetup.server.luau`
- `src/ServerScriptService/Social/WhisperService.luau`
- `src/ServerScriptService/Social/AudioSettingsService.luau`
- `src/ServerScriptService/Social/PartyService.luau`
- `src/ServerScriptService/Social/SocialHandlers.server.luau`
- `src/StarterPlayer/StarterPlayerScripts/WhisperClient.client.luau`
- `src/StarterPlayer/StarterPlayerScripts/AudioSettingsClient.client.luau`
- `src/StarterPlayer/StarterPlayerScripts/PartyClient.client.luau`

**ใหม่ (P1/P2 — build ผ่านแล้วรอบก่อน แต่เช็คซ้ำได้):**
- `src/ServerScriptService/World/SkyCityLift.luau`, `NeonUtopiaWorldBuilder.luau`, `AirTransportService.luau`
- `src/ServerScriptService/AirTransportBootstrap.server.luau`
- `src/ServerScriptService/Progression/TravelTicketWallet.luau`
- `src/ReplicatedStorage/Modules/AirTransportConfig.luau`

**แก้ไข:** `Hellbound/HellboundTerminalService.luau` (+fare), `Commerce/CommerceShopService.server.luau` (+AirTransport receipt), `World/WorldBuildConfig/WorldPlaceGuard/WorldBootstrap/EternityCityWorldBuilder/VoidRecovery`, `Modules/GameConfig/PlaceTeleport`, `default.project.json`

## กฎสำคัญ
- **แก้เฉพาะ error compile/type เล็กน้อย** (เช่น cast `:: any`, nil-guard, type annotation) — **ห้ามเปลี่ยน logic/ดีไซน์เกม หรือ refactor**
- ถ้าเจอ error ที่ต้องเปลี่ยน logic → **อย่าแก้ ให้รายงานกลับมา** (Cowork จะแก้เอง)
- ถ้าแก้อะไร: commit แยก message ชัดเจน `fix(verify): ...` และบอกรายการที่แก้

## รายงานกลับ
1. ผล rojo build (OK / error อะไร)
2. type errors ที่เจอ (ไฟล์+บรรทัด+ข้อความ)
3. อะไรที่แก้ให้ (ถ้ามี) + อะไรที่ต้องให้ Cowork แก้เอง
