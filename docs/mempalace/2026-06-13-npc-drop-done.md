# 2026-06-13 — NPC Item Drop System ✅

## Commit: 1538dba → origin/main

## สิ่งที่สร้าง
- `NpcDropConfig.luau` — 5 NPC profiles (id 1-5) + fallback, drop chance/qty range
- `NpcDropService.luau` — rollDrops(), grantDrops() → PlayerItemStore, getBaseXP()
- `CombatService.luau` — grantKillRewards(player, npcId): XP + drops + quest hook
- `DropNotifClient.client.luau` — stack notif มุมขวาล่าง (max 5, fade 3s)
- `SocialRemoteSetup` — +ItemDropped RemoteEvent

## Kill flow ครบแล้ว
Kill NPC → XP (baseXP×mult) → Item drops (rollDrops แยกทุก entry) → QuestProgress → Client notif

## ต่อไป
- Crafting System (ItemCraftingConfig มีอยู่แล้ว, วัตถุดิบได้จาก drop แล้ว)
