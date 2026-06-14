# Mobile-First RPG Feature Matrix — Gap Analysis

> ทิศทาง: Next-Gen MMORPG มือถือ คุณภาพเทียบ Lineage W / Ragnarok Mobile (กำหนดโดย Praphan 15 มิ.ย. 2026)
> Art direction: **Next-Gen สมจริง** — custom mesh body + PBR (Color/Normal/Roughness/Metalness) + lighting/atmosphere · ไม่ใช่บล็อกคลาสสิก
> Mobile-First: ออกแบบเพื่อ "หน้าจอจำกัด + นิ้วโป้ง" · ทุก GUI ใช้ `Scale` + `UIAspectRatioConstraint` · collapsible/auto-hide ตอนสู้

## สถานะเทียบ Matrix (เช็กจาก src จริง 15 มิ.ย.)

| ระบบ | ต้นแบบ | สถานะ | ไฟล์ในโปรเจกต์ |
|---|---|---|---|
| Radial Interaction Wheel | Ragnarok | ✅ **มีแล้ว** | `RadialMenuConfig.luau` (8 actions: Trade/Whisper/Party/Clan/Follow/Carry/Block/Report) + `InteractionClient.client.luau` + `Social/InteractionService` |
| Auto-Battle / Auto-Skill | Lineage W | ✅ **มีแล้ว** | `Combat/AutoBattleService.luau` + `AutoBattleClient.client.luau` |
| Follow System | Ragnarok | ✅ มี action + server | `RadialMenuConfig` (Follow) + `Social/InteractionService` (ตรวจ MoveTo/Pathfinding เพิ่ม) |
| Custom Chat (tabs) + Voice toggle | Lineage W | ✅ **มีแล้ว** | `ChatClient.client.luau` + `ChatConfig` + `WhisperClient` + `AudioSettingsClient/Service` |
| Trade GUI 2-step lock/confirm | MMORPG | ✅ **มีแล้ว** (+credit UI เพิ่ง wire) | `TradingService.luau` + `TradingClient.client.luau` |
| Party EXP/Drop share | Ragnarok | ✅ มี | `Social/PartyService.luau` + `PartyClient.client.luau` |
| Clan/Alliance hierarchy | Lineage | ✅ มี | `ClanWar/*` + `GuildClient.client.luau` |
| Anti-Bot / Player Logs | Admin | ✅ มี (แข็งแรง) | `Security/*` (RemoteGuard, GriefingGuard, EvasionDetector, LogExportBridge...) |
| In-game Report | Admin | ✅ มี action | `RadialMenuConfig` (Report) + `Security/SupportDesk*` |
| Camera (1st person/effects) | Next-Gen | ✅ มี | `CameraModeController.client.luau` |

## ❌ ช่องว่างจริง (ต้องสร้าง/เติม)
1. **Auto-Lock Targeting System** (Lineage W) — *ยังไม่มี* ระบบล็อกเป้าเฉพาะ: แตะศัตรู/ผู้เล่น → วงแหวน/Highlight/BillboardGui บนหัวเป้า + ปุ่ม Lock/Unlock · ต้องป้อนเป้าให้ Auto-Battle ด้วย
2. **Skill Bar HUD (มือถือ)** — *ยังไม่มี* แถบสกิลปุ่มใหญ่มุมขวาล่าง + cooldown radial + ปุ่มโจมตี/Jump (มีแต่ AutoBattle toggle)
3. **Mobile-First UX audit** — ตรวจ/แก้ทุก HUD ให้ใช้ `Scale`+`UIAspectRatioConstraint`, touch zone ใหญ่พอนิ้วโป้ง, collapsible/auto-hide ตอนสู้
4. **Next-Gen Art track** (งานใหญ่แยก) — custom skinned mesh body + PBR (SurfaceAppearance) ทั้ง avatar/อาวุธ/ฉาก/skybox ตาม `docs/AI-ASSET-WORKFLOW.md`

## หลักการ implement (จาก Praphan)
- ปุ่ม radial/HUD ใหญ่พอสำหรับนิ้วโป้ง
- collapsible UI (auto-hide chat/menu ตอนสู้) เพื่อเห็นตัวละครชัด
- ทุก automation (Auto-Battle/Follow) มี client prediction + **server validation** กัน exploit
