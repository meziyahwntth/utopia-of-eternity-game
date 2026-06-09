# Death Valley Phase A — Survival Loop (Beacon + Wraith Waves + Night Survived)

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Goal:** Greybox หุบเขามรณะเล่นได้แบบ co-op horror survival — เทียบ loop 99 Nights ใน 30 นาทีแรก โดยไม่ copy IP

---

## Scope (Phase A)

| # | Feature | Status |
|---|---------|--------|
| A1 | Light Beacon Lv1–3 + shared fuel | ✅ MVP |
| A2 | Prep → Wave night cycle + Night Survived counter | ✅ MVP |
| A3 | Wraith types: Whisper, Stalker, Legion Echo | ✅ MVP greybox |
| A4 | Revive at Beacon (party ไม่ fail ทั้งก้อน) | ✅ MVP |
| A5 | Exit Portal → Hub | ✅ MVP |
| A6 | Vignette + heartbeat (opt-out) | ✅ MVP client |

**Out of scope Phase A:** Luminite crafting full loop, POI Whispering Grove/Hollow Lake, Hellbound travel pipeline, Zones 2–5, DataStore persistence

---

## Loop

```
Join → Prep (30s) → deposit fuel at depot
  → Wave (90s) → Wraiths spawn outside Beacon radius
  → Fuel drains · downed players revive at Beacon
  → Wave ends → Night Survived +1 → Prep again
```

---

## Beacon

| Level | Radius | Max Fuel | Upgrade (stub) |
|-------|--------|----------|----------------|
| 1 | 60 stud | 100 | — |
| 2 | 90 stud | 150 | 25 Luminite shards |
| 3 | 120 stud | 150 | 50 Luminite shards |

- **Shared fuel** — `GameConfig.DeathValley.SharedBeaconFuel = true`
- Deposit **+15 fuel** per interaction (cap at max)
- Fuel drain **0.35/s** during wave; wave fails if fuel hits 0 (wraith breach message, no night credit)

---

## Wraith waves

| Type | Behavior | Nights |
|------|----------|--------|
| **Whisper** | Slow stalk, audio cue | 1+ |
| **Stalker** | Fast rush outside light | 3+ |
| **Legion Echo** | Tank, spawns in pairs | 5+, every 3rd night |

Count formula: `base + partySize + floor(nightsSurvived / 3)` · downscale when player leaves

---

## Revive

- Downed at 0 HP → `Downed` state 45s
- Ally at Beacon + channel 3s → restore 50% HP
- Solo: auto-revive at Beacon after 5s if inside sanctuary

---

## Code map

```
PrismDeathValleySurvivalConfig.luau     — tuning constants
DeathValley/DeathValleyBeaconService    — fuel, level, radius
DeathValley/DeathValleyNightService     — cycle, spawn orchestration
DeathValley/DeathValleyWraithFactory    — greybox wraith models
DeathValley/DeathValleyReviveService    — downed + revive
DeathValley/DeathValleySurvivalHandlers  — remotes + bootstrap
DeathValleySurvivalHUD.client.luau      — fuel, night, phase UI
DeathValleyHorrorFX.client.luau         — vignette + heartbeat
DeathValleyWorldBuilder                 — fuel depot, exit portal
```

---

## Validation (Studio)

1. `GameConfig.StudioDev.SimulatePlaceKey = "DeathValley"`
2. Play → HUD shows Prep · deposit fuel → Wave starts
3. Step outside amber ring → wraiths chase
4. Let HP hit 0 → revive at beacon
5. Survive wave → Night Survived +1
6. Exit Portal → Hub teleport (or Studio message if PlaceId unset)

```bash
rg "DeathValleyNight|BeaconFuel|NightSurvived|WraithWhisper" utopia-of-eternity-game/src/
python3 -m json.tool utopia-of-eternity-game/default.project.json
```
