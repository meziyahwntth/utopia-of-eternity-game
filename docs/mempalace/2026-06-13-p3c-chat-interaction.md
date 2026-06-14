# MemPalace Diary — P3-C: Custom Chat + Player Interaction
**วันที่:** 13 มิ.ย. 2026 · **Session:** Cowork (หน้าต่างใหม่ ต่อจาก P3-B)

---

## งานที่ทำ

### Task 11 — ChatConfig + GuildStore/GuildService schema update
- **ChatConfig.luau** (ใหม่ใน `ReplicatedStorage/Modules/`) — ค่ากลางระบบแชท P3-C: channel 5 ช่อง, สีแยก, UI geometry, admin list, rate limit, voice flag
- **GuildStore.luau** — เพิ่ม `allianceSpeakers: { [string]: boolean }?` ใน `GuildData` type, bump DataStore จาก v1 → v2 (`UtopiaGuilds_v2`, `UtopiaGuildMembers_v2`)
- **GuildService.luau** — เพิ่ม `allianceSpeakers = {}` ใน `create()`, เพิ่ม `isAllianceSpeaker()`, `setAlliancePermission()`, `allianceChat()` + handler cross-server `"alliancechat"` ใน MessagingService

### Task 12 — SocialRemoteSetup + ChatService (server)
- **SocialRemoteSetup** — เพิ่ม 14 remotes: AllianceChatSend/Received, AlliancePermSetReq, ChatSend/Receive, AdminCmd, VoiceToggleMute/StateChanged/CallRequest, Interaction remotes (DuelSend/DuelAccept/DuelReceived/DuelStart, TradeSend/TradeReceived, CarryRequest, UncarryRequest, CarryStarted/Ended, BlockPlayer, UnblockPlayer, InteractionPartyInvite, InteractionClanInvite)
- **PartyService.luau** — เพิ่ม `PartyService.getPartyMembers(player: Player): {Player}` (export สำหรับ ChatService)
- **ChatService.server.luau** (ใหม่) — server-authoritative chat router: TextService filter, rate-limit (20/min), route General/Party/Clan/Alliance/Whisper, admin `:cmd` executor (kick/heal/tp/speed)
- **SocialHandlers** — เพิ่ม wire AllianceChatSend + AlliancePermSetReq
- **default.project.json** — เพิ่ม ChatService, InteractionService, InteractionHandlers

### Task 13 — ChatClient.client.luau
- ปิด Roblox default chat (`StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)`)
- GUI Lineage II-style: tab bar 5 ช่อง (General/Party/Clan/Alliance/Whisper), history ScrollingFrame สี per-channel, input TextBox + Send button + 🎤 voice toggle button
- Whisper mode: แสดง target TextBox เพิ่มขึ้น
- Slash command parser: `/invite /p /leave /clancreate /claninvite /clanleave /g /a /w /allianceinvite /allianceleave /friendinvite /loc /time /sit /stand /unstuck /trade /target`
- Admin `:cmd` parser → `AdminCmd` RF → server validate
- Listeners: `ChatReceive`, `GuildChatReceived`, `AllianceChatReceived`, `PartyChatReceived`, `WhisperReceive`, `GuildMemberJoined`
- **GuildClient + PartyClient**: ลบ `TextChatService`, `TextChatCommand`, slash commands ออกทั้งหมด; `systemMsg()` เปลี่ยนเป็น `warn()` (ChatClient แสดงผลแทน)

### Task 14 — InteractionService + InteractionClient
- **InteractionService.luau** (server module): block list (in-memory), duelRequest/duelAccept, tradeRequest, carry (WeldConstraint), uncarry, partyInvite/clanInvite shortcuts
- **InteractionHandlers.server.luau**: wire DuelSend/DuelAccept/TradeSend/CarryRequest/UncarryRequest/BlockPlayer/UnblockPlayer/InteractionPartyInvite/InteractionClanInvite
- **InteractionClient.client.luau**: คลิกตัวละครผู้เล่น → context menu 9 ปุ่ม (Duel/Trade/Whisper/Friend/Party/Clan/Carry/Block/Report), confirmation popup (Duel/Trade received), Follow mode (Heartbeat loop + MoveTo), Uncarry button (แสดงเมื่ออุ้มอยู่), BindableEvent `ChatClientWhisperTo` ใน ReplicatedStorage

---

## การตัดสินใจสำคัญ

| ประเด็น | ตัดสินใจ |
|--------|---------|
| DataStore v1 → v2 | ยอมรับข้อมูลเก่าหาย (เพิ่ม allianceSpeakers field) |
| Alliance chat perm | Leader อัตโนมัติ; Officer/Veteran/Member ต้องได้รับจาก Leader |
| TextChatService | ยกเลิก 100% — ใช้ custom ScreenGui แทน |
| Follow mode | client-side เท่านั้น (Humanoid:MoveTo) ไม่ต้อง server |
| systemMsg (GuildClient/PartyClient) | เปลี่ยนเป็น `warn()` — ChatClient รับผิดชอบ display |

---

## สถานะ

- ✅ Static check clean (brace/paren balance)
- ⏳ รอ Cursor verify: rojo build + luau-lsp analyze → commit
- ⏳ P3-C Voice (defer ไปพิจารณาหลัง commit)

---

## ไฟล์ที่เกี่ยวข้อง
- `CURSOR-PROMPT-P3C-VERIFY.md` — prompt สำหรับ Cursor
- `HANDOFF-SESSION-CONTINUE.md` — อัปเดตแล้ว
