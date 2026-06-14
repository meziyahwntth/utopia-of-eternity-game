# CURSOR PROMPT — P3-C verify: rojo build + luau-lsp

> สร้าง: 13 มิ.ย. 2026 · ต่อจาก commit `2bb5128` (P3-B done)

## ไฟล์ที่สร้าง/แก้ไขใน P3-C

| ไฟล์ | สถานะ | หมายเหตุ |
|------|--------|---------|
| `ReplicatedStorage/Modules/ChatConfig.luau` | ใหม่ | ค่ากลาง channel/สี/UI/admin |
| `Social/GuildStore.luau` | แก้ | +`allianceSpeakers` field, DataStore v1→v2 |
| `Social/GuildService.luau` | แก้ | +`isAllianceSpeaker` +`setAlliancePermission` +`allianceChat` +cross-server handler |
| `Social/PartyService.luau` | แก้ | +`PartyService.getPartyMembers(player)` export |
| `Social/SocialRemoteSetup.server.luau` | แก้ | +P3-C remotes (AllianceChat/ChatSend/Voice/Interaction) |
| `Social/SocialHandlers.server.luau` | แก้ | +AllianceChatSend/AlliancePermSetReq handlers |
| `Social/ChatService.server.luau` | ใหม่ | router: General/Party/Clan/Alliance/Whisper + admin |
| `Social/InteractionService.luau` | ใหม่ | duel/trade/carry/block/party/clan invite |
| `Social/InteractionHandlers.server.luau` | ใหม่ | wire interaction remotes |
| `StarterPlayerScripts/ChatClient.client.luau` | ใหม่ | Lineage II-style chat GUI (5 channels) |
| `StarterPlayerScripts/GuildClient.client.luau` | แก้ | ลบ TextChatCommand/TextChatService |
| `StarterPlayerScripts/PartyClient.client.luau` | แก้ | ลบ TextChatCommand/TextChatService |
| `StarterPlayerScripts/InteractionClient.client.luau` | ใหม่ | context menu คลิกตัวละคร |
| `default.project.json` | แก้ | +ChatService +InteractionService +InteractionHandlers |

## สิ่งที่ต้องทำ

### 1. rojo build

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-p3c.rbxlx
```

### 2. luau-lsp analyze (ไฟล์ใหม่/แก้ทั้งหมด)

```bash
luau-lsp analyze \
  --definitions=roblox.d.luau \
  src/ReplicatedStorage/Modules/ChatConfig.luau \
  src/ServerScriptService/Social/GuildStore.luau \
  src/ServerScriptService/Social/GuildService.luau \
  src/ServerScriptService/Social/PartyService.luau \
  src/ServerScriptService/Social/SocialRemoteSetup.server.luau \
  src/ServerScriptService/Social/SocialHandlers.server.luau \
  src/ServerScriptService/Social/ChatService.server.luau \
  src/ServerScriptService/Social/InteractionService.luau \
  src/ServerScriptService/Social/InteractionHandlers.server.luau \
  src/StarterPlayer/StarterPlayerScripts/ChatClient.client.luau \
  src/StarterPlayer/StarterPlayerScripts/GuildClient.client.luau \
  src/StarterPlayer/StarterPlayerScripts/PartyClient.client.luau \
  src/StarterPlayer/StarterPlayerScripts/InteractionClient.client.luau
```

### 3. สิ่งที่ luau-lsp อาจ flag (รู้ล่วงหน้า)

| ประเด็น | ไฟล์ | วิธีแก้ |
|---------|------|---------|
| `GuildData.allianceSpeakers` อาจเป็น `nil` | GuildService | ใช้ `if g.allianceSpeakers == nil then` guard แล้ว |
| `PartyService.getPartyMembers` อาจไม่มีใน type ที่ import | ChatService | เพิ่ม function export ไว้แล้ว |
| `buildMenu` reassign | InteractionClient | `local function` → reassign ได้ใน Luau |
| `RBXScriptConnection` type | InteractionClient | ใช้ built-in type แล้ว |

### 4. git commit (ถ้า clean)

```bash
git add -A
git commit -m "feat(P3-C): custom chat GUI + player interaction context menu

- ChatConfig.luau: channel config (General/Party/Clan/Alliance/Whisper)
- GuildService: allianceSpeakers v2 + allianceChat + permission
- ChatService: server chat router + admin commands + rate-limit
- ChatClient: Lineage II-style GUI, 5 channels, voice toggle
- InteractionService/Client: duel/trade/carry/block/party/clan context menu
- Strip TextChatService from GuildClient + PartyClient
- SocialRemoteSetup: +14 new remotes"
```

### 5. รายงานกลับ

- ✅/❌ BUILD
- ✅/❌ STRICT CLEAN (ระบุ error+line ถ้ามี)
- commit hash

---

## หมายเหตุ

- `GuildStore` เปลี่ยนเป็น DataStore **v2** — ข้อมูลแคลนเก่า (v1) จะหาย (ยอมรับแล้ว)
- `ChatClient` ปิด Roblox default chat ด้วย `SetCoreGuiEnabled(Chat, false)` → ทดสอบใน Studio ต้อง enable VoiceChatService.UseAudioApi = Enabled ด้วย
- `InteractionClient` สร้าง `BindableEvent "ChatClientWhisperTo"` ใน ReplicatedStorage — ถ้า ChatClient จะรับ whisper shortcut ให้ listen: `ReplicatedStorage.ChatClientWhisperTo.Event:Connect(function(name) ... end)`
- Follow mode ใช้ `Humanoid:MoveTo` loop — server ไม่รู้ (client-side เท่านั้น) ปลอดภัยดี
