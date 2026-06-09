# Death Valley Phase C — Persistence, Travel & Mega Depth

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-B-EXPANSION.md`

---

## Phase C Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| C1 | **DataStore Checkpoint** | บันทึก run ข้าม session (Beacon Lv3+) |
| C2 | **Hellbound Travel** | เล่นได้ — Peak → Rail → Base → Spirit 3 → Sanctuary |
| C3 | **Mega Zones 2–5** | Squad / Raid / Legion / Abyss Throne |
| C4 | **Weekly Boss** | หมุน boss รายสัปดาห์ · ปลด Ring 3 (20 nights) |

---

## C1 — DataStore Checkpoint

- Store: `UtopiaDeathValley_v1` · key `player:{userId}`
- บันทึกหลังคืนสำเร็จ + Beacon ≥ Lv3
- โหลดเมื่อ `PlayerAdded` → restore server ถ้ายังไม่มี progress สูงกว่า
- Studio (API ปิด): fallback attributes เท่านั้น

---

## C2 — Hellbound Travel (Playable)

Phases ตาม `PrismHellboundConfig.TravelPhases` — prompt ที่แต่ละ station ใน Death Valley greybox

Terminal Eternity City (Phase C+): `BeginHellboundTravel` remote → teleport DeathValley + flag arrival

---

## C3 — Mega Dungeon Zones

| Zone | ID | Team | Boss HP |
|------|-----|------|---------|
| 1 | duo_depth | 2 | 240 |
| 2 | squad_hollow | 5 | 480 |
| 3 | raid_cavern | 10 | 1200 |
| 4 | legion_pass | 20 | 2400 |
| 5 | abyss_throne | 50 | 6000 |

Shared runtime: `DungeonZoneRuntime.luau` · handler: `DungeonMegaZoneHandlers.server.luau`

---

## C4 — Weekly Boss

- ปลด: **20 Nights Survived** (Horizon Ring 3)
- Week ID: `YYYY-Www` (UTC)
- Boss rotation: Echo Tyrant → Hollow Leviathan → Legion Avatar
- Reward: Luminite shards + 1 weekly clear flag (no duplicate key same week)

---

## Validation

```bash
rg "DeathValleyPlayerStore|HellboundTravel|DungeonZoneRuntime|WeeklyBoss" utopia-of-eternity-game/src/
```

Studio: survive 20 nights → weekly boss · travel Peak→Sanctuary · Zone 2 gate · rejoin = checkpoint restore
