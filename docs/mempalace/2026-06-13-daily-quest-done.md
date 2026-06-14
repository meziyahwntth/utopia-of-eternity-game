# 2026-06-13 — Daily Quest System ✅

## Commit: 01da4a0 → origin/main

## สิ่งที่สร้าง
- `QuestConfig.luau` — 8 templates (kill/emote/chat/visit/pet/trade), 3 ข้อ/วัน, reset UTC+7
- `QuestStore.luau` — DataStore `UtopiaQuest_v1`, date-keyed reset
- `QuestService.luau` — roll Fisher-Yates, recordProgress(), claimReward()
- `QuestHandlers.server.luau` — wire RF + NpcKillEvent / TradeCompleteEvent BindableEvents
- `QuestHUDClient.client.luau` — 📋 panel มุมขวาบน, claim button, notification banner

## Progress hooks wired
- kill_npc → NpcKillEvent BindableEvent (CombatService → QuestHandlers)
- use_emote → EmoteService.playEmote
- send_chat → ChatService
- equip_pet → PetHandlers
- trade_complete → TradeCompleteEvent BindableEvent
- visit_zone → ยังไม่มี hook (progress=0 safe)

## หมายเหตุสำคัญ
- มี `DailyQuestService` เก่า (Festival Phase 2) อยู่ด้วย — ระบบใหม่ใช้ remotes/HUD แยกกัน ไม่ conflict
- itemId `stone_fragment` ใน QuestConfig → ใช้ `StoneFragment` (ตาม ItemCraftingConfig)

## ต่อไป
- NPC Item Drop system (StoneFragment/IronOre/MagicCrystal หลังฆ่า NPC)
