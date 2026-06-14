# 2026-06-13 — PlayerLevelService Full (DataStore XP) ✅

## Commit: 1f1233a → origin/main

## สิ่งที่เปลี่ยน
- `LevelStore.luau` — DataStore `UtopiaLevel_v1`, get/save pcall, default {level=1, xp=0}
- `PlayerLevelService.luau` — replace stub: addExp(), XP table expNeeded=lv×100+lv²×5, level-up loop, LevelUp RemoteEvent, persist on PlayerRemoving, backward-compat addLevel()
- `CombatService.luau` — grantKillExp → addExp(25×mult), ลบ CombatExpAccum attribute
- `LevelHUDClient.client.luau` — Lv badge + XP bar tween + level-up flash banner
- `SocialRemoteSetup` — เพิ่ม LevelUp RemoteEvent

## XP Curve
- L1→2: 105 XP, L10→11: 1,500, L50→51: 17,500, L99→100: 59,000
- Base kill: 25 XP × multiplier (pet + event)
- Max level: 149

## สถานะ optional backlog
- ✅ PlayerLevelService Full
- ⬜ Quest/Daily Mission system (ต่อไป)
- ⬜ NPC item drop system (PetPickupRadius attribute พร้อม)
- ⬜ Custom 3D pet models
- ⬜ TradingClient credit UI
- ⬜ Bounty post escrow
