# Death Valley Phase E — Cross-World & Seasonal Depth

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-D-LIVEOPS.md`

---

## Phase E Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| E1 | **Commerce → Depart** | ซื้อ ticket ที่ Hellbound Terminal → auto hyperspace + teleport |
| E2 | **Spirit Co-op** | Chamber combat ร่วมกัน — shared robots · shared kill count |
| E3 | **Cross-Server LFG** | MessagingService broadcast · join via `TeleportToPlaceInstance` |
| E4 | **Global Leaderboard UI** | Full-screen panel · Checkpoint Terminal · key **L** |
| E5 | **Horizon Ring 4** | Seasonal Echo Frontier @ **30 nights** · shrine + shard bonus |

---

## E1 — Hellbound Tickets

| Item ID | Mode |
|---------|------|
| `hellbound_public_airplane` | PublicAirplane |
| `hellbound_private_jet` | PrivateJet |

Purchase ใน Commerce → `HellboundTerminalService.depart()` ทันที

---

## E2 — Spirit Chamber Co-op

- Session key ต่อ chamber index (หนึ่ง wave ต่อ chamber ต่อ server)
- ผู้เล่นที่เข้า combat ขณะ session active → join อัตโนมัติ
- Robots โจมตีสมาชิกใกล้ที่สุดใน session

---

## E3 — Cross-Server LFG

- Topic: `UtopiaDV_LFG_v1`
- Listing มี `jobId` + `placeId` สำหรับ join ข้าม server
- Local join ยังใช้ได้บน server เดียวกัน

---

## E4 — Global Leaderboard

- `DeathValleyGlobalLeaderboardUI` — top 25 + season + your rank
- เปิดจาก Checkpoint Terminal หรือกด **L**

---

## E5 — Ring 4 Seasonal

- ปลด **30 nights survived**
- POI **Seasonal Echo Shrine** — claim 1× shard bonus / season
- Gate วงที่ 4 บน Horizon Rings

---

## Validation

```bash
rg "LfgCrossServer|SpiritChamber|GlobalLeaderboard|Ring4|hellbound_public" utopia-of-eternity-game/src/
```
