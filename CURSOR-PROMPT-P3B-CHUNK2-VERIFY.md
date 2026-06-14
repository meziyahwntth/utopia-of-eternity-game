# CURSOR PROMPT — P3-B chunk2 verify: rojo build + luau-lsp

> สร้าง: 13 มิ.ย. 2026 · commit `2bb5128` (ต่อจาก `145ebc1`)

## ไฟล์ที่แก้ไขใน chunk2

| ไฟล์ | การเปลี่ยนแปลง |
|------|----------------|
| `Social/GuildService.luau` | +chat() +allianceInvite/Accept/Decline/Leave() + cross-server chat handler + PlayerAdded notify |
| `Social/SocialHandlers.server.luau` | wire GuildChatSend + Alliance remotes x4 |
| `Social/SocialRemoteSetup.server.luau` | +GuildChatSend/Received +GuildMemberJoined +AllianceCreate/Accept/Decline/Leave/InviteReceived/StateChanged |
| `StarterPlayerScripts/GuildClient.client.luau` | +/g +/allianceinvite +/allianceleave + alliance popup + listeners |

## สิ่งที่ต้องทำ

### 1. rojo build

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-p3b-chunk2.rbxlx
```

### 2. luau-lsp analyze

```bash
luau-lsp analyze \
  --definitions=roblox.d.luau \
  src/ServerScriptService/Social/GuildService.luau \
  src/ServerScriptService/Social/SocialHandlers.server.luau \
  src/ServerScriptService/Social/SocialRemoteSetup.server.luau \
  src/StarterPlayer/StarterPlayerScripts/GuildClient.client.luau
```

### 3. git commit (ถ้า clean)

ไม่จำเป็นต้อง commit ใหม่ — commit `2bb5128` ทำไว้แล้ว
ถ้าแก้ error ให้ commit เพิ่มด้วย message: `fix(P3-B-c2): <สรุปที่แก้>`

### 4. รายงานกลับ

- ✅/❌ BUILD
- ✅/❌ STRICT CLEAN (ระบุ error+line ถ้ามี)
- commit hash ถ้ามีการแก้ไขเพิ่ม
