# Death Valley Phase H — Friends, Titles & Season Rollover

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-G-SOCIAL-REWARDS.md`

---

## Phase H Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| H1 | **Friends-list Invite** | `GetFriendsAsync` · invite เฉพาะเพื่อน · แสดง online/in-server |
| H2 | **Titles + Cosmetics** | ทุก tier ได้ display title + cosmetic ID · grant ผ่าน `OwnedCosmetics` |
| H3 | **Top-25 Auto Rollover** | เมื่อ season เปลี่ยน → queue auto-reward top 25 · deliver ตอน join |

---

## H1 — Friend Invite

| Remote | หน้าที่ |
|--------|--------|
| `GetLfgFriendsList` | รายชื่อเพื่อน (max 50) |
| `SendLfgFriendInvite` | ส่ง invite (validate `IsFriendsWith`) |

LFG UI: ปุ่ม **Friends** แยกจาก Invite ทุกคนใน server

---

## H2 — Season Reward Grants

| Tier | Title | Cosmetic ID |
|------|-------|-------------|
| Champion | Echo Champion | `dv_aura_echo_champion` |
| Elite | Hellbound Elite | `dv_aura_hellbound_elite` |
| Veteran | Night Veteran | `dv_trail_night_veteran` |
| Survivor | Valley Survivor | `dv_badge_valley_survivor` |
| Participant | Echo Participant | `dv_badge_echo_participant` |

Attributes: `DV_EquippedTitle`, `DV_SeasonTitle_{seasonId}`, `OwnedCosmetics`

---

## H3 — Rollover Auto-Distribute

- Global state: `UtopiaDV_RolloverState_v1` → `activeSeasonId`
- Queue: `UtopiaDV_AutoReward_v1` → `{userId}:{seasonId}`
- **Top 25 only** ได้ auto-deliver ตอน login หลัง rollover
- Rank 26+ ยัง claim manual ผ่าน Phase G

---

## Validation

```bash
rg "LfgFriends|SeasonRollover|displayTitle|AutoReward" utopia-of-eternity-game/src/
```
