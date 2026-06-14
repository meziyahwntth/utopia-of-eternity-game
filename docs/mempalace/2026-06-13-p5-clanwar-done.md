# MemPalace Diary — P5 Clan War Done
**วันที่:** 13 มิ.ย. 2026 · **Commit:** 4c73819

## commits สะสม
| Phase | Commit |
|-------|--------|
| P3-C Custom Chat + Interaction | de502e0 |
| P3-C+ Combat Foundation | 905740e |
| P3-C+ Radial Wheel | fbf8b50 |
| P4 Economy Core | b0856c4 |
| **P5 Clan War** | **4c73819** |

## สิ่งสำคัญ P5
- Remotes อยู่ใน `SocialRemotes` (ไม่ใช่ `Remotes`) — สอดคล้อง Social system เดิม
- War scheduler: เสาร์ 13:00 UTC = 20:00 ไทย, 45 นาที, 3 zones (Marina/Aurora/Canal)
- GuildService เพิ่ม `getById()` / `getByPlayer()` (alias getPlayerGuild)
- TaxDistribution: 50% ClanVault / 30% Veteran+ / 20% ServerBuff
- DefensiveFatigue: task.delay loop 7 วัน (ไม่ใช่ while true)

## ถัดไป: P5+ Mercenary/Bounty → P6 Sky Treasure
