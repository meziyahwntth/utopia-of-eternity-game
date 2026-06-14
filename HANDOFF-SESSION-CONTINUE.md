# HANDOFF — ทำต่อ Utopia of Eternity (หน้าต่างใหม่)
**สร้าง:** 13 มิ.ย. 2026 · **อัปเดต:** 13 มิ.ย. 2026 · **git HEAD:** `37db9e0` (Neon Utopia Place live)

> เปิดหน้าต่าง Cowork ใหม่ในโปรเจกต์นี้แล้ววางพรอมป์ต์นี้ — ทำต่อได้ทันที

---

## 0. อ่านก่อน (Source of Truth)
1. **`docs/MASTER-BLUEPRINT.md`** = แผนรวม + roadmap + ค่าตกลง
2. เอกสารลูก: `BLUEPRINT-V2-WORLD-PROGRESSION.md`, `GDD-SOCIAL-VOICE.md`, `GDD-SHOP-RENTAL-COMMERCE.md`, `RESEARCH-CLASSIC-MMO-SYSTEMS.md`, `RESEARCH-ROBLOX-TOP-GAMES.md`
3. memory (auto): `project-v2-blueprint`, `project-utopia-overview`, `feedback-*`

## 1. กฎการทำงาน
- **Strict Truth Mode:** เช็คโค้ดเดิมก่อน · ห้ามเดา · verify ทุกอย่าง
- **sandbox ไม่มี rojo** → verify ผ่าน Cursor (เขียน `CURSOR-PROMPT-*.md`)
- **project.json** ServerScriptService = ราย-ไฟล์ · ReplicatedStorage+StarterPlayerScripts = glob
- commit บ่อย · fair/no-pay-to-win · server-authoritative · modular
- **MemPalace:** diary entry → `docs/mempalace/` ทุกงานเสร็จ

## 2. เสร็จแล้ว (verified + committed)

| Phase | สถานะ | Commit |
|-------|--------|--------|
| P0 Security | ✅ verified | — |
| P1 เมืองลอยฟ้า | ✅ runtime-verified | 4cdc325 |
| P2 ขนส่ง+ตั๋ว | ✅ | — |
| P3-A Social core | ✅ strict clean | f308016 |
| **P3-B Clan chunk1** | ✅ strict clean | 145ebc1 |
| **P3-B Clan chunk2** | ✅ strict clean | 2bb5128 |
| **P3-C Custom Chat + Interaction** | ✅ strict clean | de502e0 |
| **P3-C+ Combat Foundation** | ✅ strict clean | 905740e |
| **P3-C+ Radial Wheel** | ✅ strict clean | fbf8b50 |
| **P4 Economy Core** | ✅ strict clean | b0856c4 |
| **P5 Clan War** | ✅ strict clean | 4c73819 |
| **P5+ Mercenary/Bounty** | ✅ strict clean | c68c6da |
| **P6 Sky Treasure + CurrencyService** | ✅ strict clean | 3124399 |
| **P6 Integration** | ✅ strict clean | 94ac45e |
| **P7 Camera/UX + Visible Power** | ✅ strict clean | c3b34c2 |
| **P8 Live-ops (Calendar+Emote+Season)** | ✅ strict clean | 79e499e |
| **Backlog-A (Banner+Camera persist+PvP gate)** | ✅ strict clean | — |
| **Backlog-B Pet/Companion** | ✅ strict clean | 01a376b |
| **PlayerLevelService Full (XP+DataStore)** | ✅ strict clean | 1f1233a |
| **Daily Quest System** | ✅ strict clean | 01da4a0 |
| **NPC Item Drop System** | ✅ strict clean | 1538dba |
| **Crafting / Grandeur System** | ✅ strict clean | 3488b91 |
| **Bounty Post Escrow** | ✅ strict clean | 818edc8 |
| **visit_zone Quest Hook** | ✅ BUILD (luau-lsp warning เฉพาะ missing roblox.d.luau) | 99852be |
| **Pet Drop from NPC Kill** | ✅ BUILD · ⚠️ luau-lsp warning เดิม (roblox.d.luau) | aa0df7f |
| **Fusion System + Card/Rune Socket (P4)** | ✅ BUILD · ⚠️ luau-lsp warning เดิม | a729b4b |
| **MVP World Boss (P5)** | ✅ BUILD · ⚠️ luau-lsp warning เดิม | 516a50c |
| **Neon Utopia Place + AirTransport** | ✅ BUILD | e4ea48a |
| **Teen Trend Fashion Wave 2 (60 ชุด)** | ✅ BUILD · 90 ชุดรวม | 53f568a |
| **Garage: Vehicle (15) + Mount (7)** | ✅ BUILD · DataStore pcall ✅ | fe5804d |
| **Pet Wave 2 (15 ตัวใหม่)** | ✅ BUILD · 18 ตัวรวม | bb00d80 |
| **Weapon Wave 2 (20 cosmetic + Tier Visual)** | ✅ BUILD · 33 weapons รวม | 8264a66 |
| **Neon Utopia Place LIVE** | ✅ Place ID 119711258870458 · published v2 | 37db9e0 |

## 3. สถานะ Backlog ทั้งหมด ✅ COMPLETE

| รายการ | สถานะ |
|--------|--------|
| Event banner HUD | ✅ Backlog-A |
| Camera persist (DataStore) | ✅ Backlog-A |
| PvP zone gate | ✅ Backlog-A |
| Pet/Companion | ✅ Backlog-B (01a376b) |

**งานค้าง gameplay-blocking = 0** — ทุก phase จาก P3-C ถึง Backlog-B เสร็จสมบูรณ์

### ต่อไป (optional / nice-to-have)
- Custom 3D pet models (ใส่ `modelId` จริงใน PetConfig)
- Pet drop จาก NPC kill / quest reward
- TradingClient: credit offer input field
- XP/quest system full (PlayerLevelService ยังเป็น stub)
- Bounty post escrow (deduct credits ตอน post)

## 4. รอ Cursor verify — P3-C Chat + Interaction (historical)

**อ่าน `CURSOR-PROMPT-P3C-VERIFY.md`** แล้วส่งให้ Cursor รัน

### ไฟล์ที่สร้าง/แก้ใน P3-C (รอ commit)

| ไฟล์ | บทบาท |
|------|-------|
| `Modules/ChatConfig.luau` | ค่ากลาง channel/UI |
| `Social/GuildStore.luau` | +allianceSpeakers, DataStore v2 |
| `Social/GuildService.luau` | +allianceChat + permission |
| `Social/PartyService.luau` | +getPartyMembers export |
| `Social/SocialRemoteSetup.server.luau` | +14 remotes ใหม่ |
| `Social/SocialHandlers.server.luau` | +alliance chat/perm handlers |
| `Social/ChatService.server.luau` | ✨ router ใหม่ General/Party/Clan/Alliance/Whisper |
| `Social/InteractionService.luau` | ✨ duel/trade/carry/block |
| `Social/InteractionHandlers.server.luau` | ✨ wire interaction remotes |
| `StarterPlayerScripts/ChatClient.client.luau` | ✨ Lineage II-style chat GUI |
| `StarterPlayerScripts/GuildClient.client.luau` | ลบ TextChatService/Command |
| `StarterPlayerScripts/PartyClient.client.luau` | ลบ TextChatService/Command |
| `StarterPlayerScripts/InteractionClient.client.luau` | ✨ context menu คลิกตัวละคร |
| `default.project.json` | +3 entries |

### สิ่งสำคัญที่รู้ล่วงหน้า
- `GuildStore` DataStore v2 — ข้อมูล v1 (แคลนเก่า) จะหาย ✅ ยอมรับแล้ว
- `ChatClient` ปิด default chat (`SetCoreGuiEnabled(Chat,false)`) — ต้องทดสอบใน Studio
- `InteractionClient` สร้าง `BindableEvent "ChatClientWhisperTo"` ใน ReplicatedStorage
- Follow mode = client-side `Humanoid:MoveTo` loop (server-safe)

## 4. Roadmap ถัดไป (หลัง P3-C commit)

**P3-C Voice** (อาจ defer ไป P4 ถ้า scope ใหญ่เกิน)
- VoiceService.luau: SpatialVoice age-check, mute toggle
- VoiceClient.client.luau: 🎤 button + call button
- ทบทวน GDD-SOCIAL-VOICE.md ก่อน

**P4 Economy**
- Item tier + grandeur system
- Trading P2P
- Fusion
- Card/Rune system

**P5 Endgame**
- Eternal Colosseum
- Clan War (ชิงเขต เก็บภาษีร้าน)
- MVP Boss

## 5. ค้าง (ไม่บล็อก P3-C)
- Neon Utopia Place ID จริง + SpawnRouter
- dependency chain errors (PrismKey*, FriendPresence)
- MemPalace diary entry P3-C (เขียนหลัง Cursor verify)

## 6. git log ล่าสุด
```
2bb5128 P3-B Clan chunk2: clan chat /g + alliance(<=3) + member-online notify
145ebc1 fix(verify): prefix unused GuildClient currentGuild for strict lint
4ca38ac P3-B Clan core: wire SocialHandlers + GuildClient + project.json
addd02d P3-B WIP: GuildStore + GuildService + guild remotes
f308016 fix PlaceKey cast · 4cdc325 V2 P1+P2
```

---
*🎉 ROADMAP P3-C→P8 ครบแล้ว! ค้าง: Event banner HUD, Pet/Companion (P8+), PvP zone gate, Camera persist*
