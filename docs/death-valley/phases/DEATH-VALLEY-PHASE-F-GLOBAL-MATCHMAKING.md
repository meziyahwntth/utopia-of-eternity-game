# Death Valley Phase F — Global Leaderboard & LFG Matchmaking

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-E-CROSSWORLD.md`

---

## Phase F Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| F1 | **Global ODS Leaderboard** | OrderedDataStore **ต่อ season** · key = `userId` · ชื่อจาก Meta DataStore · rank คำนวณจริง (paginate) |
| F2 | **LFG Queue Matchmaking** | Enqueue ตาม zone · MessagingService sync · auto-match → party listing หรือ teleport ไป anchor server |
| F3 | **Queue UI** | ปุ่ม **Find Match** · สถานะ queue · event `LfgQueueStateChanged` |
| F4 | **Leaderboard UI+** | แสดง `globalSource` · rank นอก top 25 · ป้าย cross-place |

---

## F1 — OrderedDataStore Architecture

| Store | Key | Value |
|-------|-----|-------|
| `UtopiaDV_LB_{seasonId}` | `userId` (string) | nights survived |
| `UtopiaDV_LBMeta_v1` | `n:{userId}` | `{ name, at }` |

- ทุก Death Valley place เขียน/อ่าน store เดียวกัน → **cross-place จริง**
- Legacy `UtopiaDV_NightsLeaderboard_v1` ยัง dual-write ชั่วคราว

---

## F2 — LFG Queue

- Topic: `UtopiaDV_LFG_QUEUE_v1`
- Flow: `EnqueueLfgQueue` → merge local + remote → เมื่อครบ `nominalTeamSize` → match
- Anchor = ผู้เล่นที่ enqueue ก่อนสุด (server ของเขา host listing)
- Teleport data: `{ dvLfgQueueMatch = { zoneId, matchId, members } }`

---

## Validation

```bash
rg "LeaderboardGlobal|LfgQueue|EnqueueLfgQueue|UtopiaDV_LB_" utopia-of-eternity-game/src/
python3 -m json.tool default.project.json
```
