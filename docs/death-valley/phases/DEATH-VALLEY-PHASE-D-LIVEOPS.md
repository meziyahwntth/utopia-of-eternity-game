# Death Valley Phase D — Terminal, Spirit Combat & Live Ops

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-C-PERSISTENCE.md`

---

## Phase D Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| D1 | **Hellbound Terminal** | Eternity City → Teleport DeathValley + hyperspace spectator |
| D2 | **Spirit Chamber Combat** | 3 chambers · robot guard waves · ปลด tunnel |
| D3 | **LFG Board** | Military Base · โพสต์หาทีม Zone 2–5 (สูงสุด 50) |
| D4 | **Season + Leaderboard** | Nights Survived ราย season · OrderedDataStore top 25 |

---

## D1 — Hellbound Terminal (Cross-Place)

**Eternity City:** `HellboundDepartureGate` @ Commerce Hellbound Terminal  
**Flow:** Board → Hyperspace spectator (city clients) → `TeleportAsync` + TeleportData  
**Death Valley arrival:** Peak Colony Dock · attribute `HellboundArrivalFromTerminal`

Studio same-place: local pivot + skip dock (no PlaceId)

---

## D2 — Spirit Chambers

| Chamber | Guards | ปลด |
|---------|--------|-----|
| I | 8 robots | Rail → Base |
| II | 12 robots | Base → Chamber III |
| III | 16 robots | → Sanctuary pipeline |

Config: `PrismHellboundConfig.SpiritChambers` · combat greybox ที่ chamber stations

---

## D3 — LFG Board

- ตำแหน่ง: **Military Research Base** station
- โพสต์: zone id + slots needed (2/5/10/20/50)
- Join listing → attribute `DV_LfgPartyId` · HUD แสดงรายการ

---

## D4 — Seasons & Leaderboard

- Season ID: `{year}-{GameConfig.Seasons[month]}`  
- บันทึก best nights ต่อ season ใน `DeathValleyPlayerStore`  
- OrderedDataStore `UtopiaDV_NightsLeaderboard_v1` · key `{seasonId}:{userId}`  
- HUD: top 25 + อันดับของคุณ

---

## Validation

```bash
rg "HellboundTerminal|SpiritChamber|LfgService|LeaderboardService|SeasonService" utopia-of-eternity-game/src/
```

Studio DeathValley: Spirit chambers · LFG · leaderboard after nights  
Studio EternityCity: Terminal departure (local skip if PlaceId=0)
