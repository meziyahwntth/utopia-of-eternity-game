# MemPalace Diary — P7 Camera/UX + Visible Power Done
**วันที่:** 13 มิ.ย. 2026 · **Commit:** c3b34c2

## สิ่งสำคัญ
- `PlayerLevelService.luau` เป็น stub — ตั้ง `player:SetAttribute("PlayerLevel", n)` เพื่อทดสอบ tier
- `PlayerLevelService.setLevel(player, n)` เรียกจาก server ได้
- Remotes `TierChanged` + `PlayerTierBroadcast` อยู่ใน SocialRemoteSetup แล้ว
- Aura เริ่มที่ tier 4 (Lv41+) เท่านั้น — tier 1–3 ไม่มีออร่าเพื่อ performance
- TopDown camera Y offset = 60 studs + มุม -75°

## Out of scope (ทำทีหลัง)
- Persist camera mode ข้าม session (DataStore)
- PvP zone gating (Eternal Colosseum)
- XP/quest system เต็มรูปแบบ

## ถัดไป: P8 Live-ops
- Event Calendar (seasonal events, double XP)
- Pet/Companion (ต่อยอด Mount)
- Emote system
- Season cosmetic (limited time)
