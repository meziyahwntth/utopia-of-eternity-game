---
wing: utopia_of_eternity
date: 2026-06-13
session: P3-B Clan Core (chunk 1)
commit: 4ca38ac
---

# P3-B Clan Core — chunk 1 เสร็จแล้ว

## สิ่งที่ทำเสร็จวันนี้

### 1. default.project.json
เพิ่ม `Social/GuildStore` + `Social/GuildService` (ราย-ไฟล์) ใน ServerScriptService.Social
ก่อนหน้านี้ทั้งสองไฟล์เขียนแล้วแต่ไม่ได้อยู่ใน project.json = ไม่ถูก build

### 2. SocialHandlers.server.luau (P3-A → P3-B)
- require GuildService
- bind guild remotes ทั้งหมด:
  - GuildCreate.OnServerInvoke → GuildService.create
  - GuildDisband.OnServerEvent → GuildService.disband
  - GuildInviteSend.OnServerInvoke → GuildService.invite
  - GuildAccept.OnServerInvoke → GuildService.accept
  - GuildDecline.OnServerEvent → GuildService.decline
  - GuildLeave.OnServerEvent → GuildService.leave
  - GuildKick.OnServerEvent → GuildService.kick
  - GuildSetRank.OnServerInvoke → GuildService.setRank
  - GuildGet.OnServerInvoke → return publicState
- เรียก GuildService.init() (subscribe MessagingService cross-server invites)

### 3. GuildClient.client.luau (ใหม่)
ไฟล์: `src/StarterPlayer/StarterPlayerScripts/GuildClient.client.luau`
- `/clancreate <ชื่อ>` → GuildCreate:InvokeServer(name)
- `/claninvite <ชื่อ>` → GuildInviteSend:InvokeServer(name)
- `/clanleave` → GuildLeave:FireServer()
- `/clan` → toggle guild panel (โหลด state ใหม่จาก server)
- Invite popup: รับ/ปฏิเสธ (auto-expire 90 วิ client-side)
- Guild panel: ชื่อแคลน, Lv, REP, member list+rank (Leader/Officer/Veteran/Member) + สี+icon ต่างกัน
- GuildStateChanged listener: update panel + auto-hide ถ้าออกแคลน

## Static check
- brace/paren balanced (python sandbox)
- JSON valid
- remote names ตรงกับ SocialRemoteSetup ทุกตัว

## Pending
- Cursor verify: rojo build + luau-lsp strict (ดู CURSOR-PROMPT-P3B-VERIFY.md)
- P3-B chunk 2: alliance(≤3 clans) + clan chat /g + member-online notify

## Roadmap ถัดไป
P3-B chunk2 → P3-C Voice → P4 Economy (Trading P2P / Fusion / Card-Rune) → P5 Endgame (Clan War / MVP boss)

---

## chunk2 — 13 มิ.ย. 2026 (commit 2bb5128)

### เพิ่มเติม
- **GuildService**: `chat()` (clan chat cross-server ผ่าน MessagingService), `allianceInvite/Accept/Decline/Leave()`, `Players.PlayerAdded` notify, cross-server chat delivery ใน SubscribeAsync handler
- **SocialHandlers**: wire GuildChatSend + AllianceCreate/Accept/Decline/Leave
- **SocialRemoteSetup**: +6 remotes (GuildChatSend/Received, GuildMemberJoined, AllianceCreate/Accept/Decline/Leave/InviteReceived/StateChanged)
- **GuildClient**: `/g` clan chat, `/allianceinvite`, `/allianceleave`, Alliance invite popup (สีม่วง), listeners สำหรับ clan chat + online notify + alliance invite

### Static check
brace/paren balanced (all 4 files), 18 remote refs ตรงกับ SocialRemoteSetup ✅

### Pending
Cursor verify: rojo build + luau-lsp (ดู CURSOR-PROMPT-P3B-CHUNK2-VERIFY.md)
