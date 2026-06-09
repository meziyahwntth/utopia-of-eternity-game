# Death Valley Phase G — Social Party & Season Rewards

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-F-GLOBAL-MATCHMAKING.md`

---

## Phase G Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| G1 | **Direct Party Invite** | Owner ส่ง invite ตรง · same-server + MessagingService cross-server |
| G2 | **Historical Leaderboard** | เลือกดูย้อนหลัง 12 seasons · `GetLeaderboard(seasonId)` |
| G3 | **Season Rank Rewards** | Claim รางวัลปลาย season ตาม rank · Luminite shards |

---

## G1 — Party Invite

| Remote | หน้าที่ |
|--------|--------|
| `SendLfgInvite` | ส่ง invite (targetUserId) |
| `AcceptLfgInvite` | ยอมรับ → join party |
| `DeclineLfgInvite` | ปฏิเสธ |
| `GetPendingLfgInvites` | รายการรอตอบ |
| `LfgInviteReceived` | Event แจ้ง client |

Topic: `UtopiaDV_LFG_INVITE_v1`

---

## G2 — Season History

- `GetSeasonHistory` → 12 เดือนย้อนหลัง
- Global Leaderboard UI: **◀ ▶** เปลี่ยน season

---

## G3 — Rank Rewards (past seasons only)

| Tier | Rank | Shards |
|------|------|--------|
| Champion | #1 | 100 |
| Elite | #2–3 | 50 |
| Veteran | #4–10 | 25 |
| Survivor | #11–25 | 10 |
| Participant | 1+ nights | 5 |

Claim ที่ Checkpoint Terminal หรือ Global Leaderboard (past season view)

---

## Validation

```bash
rg "LfgInvite|SeasonReward|GetSeasonHistory|SeasonRankRewards" utopia-of-eternity-game/src/
```
