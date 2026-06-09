# Utopia of Eternity — Roblox Game (Rojo)

Open-world Roblox universe · 5 MVP places · IP-safe · Utopia Shield anti-cheat.

> **New session?** Read `docs/00-START-HERE.md` then `docs/PROJECT-MASTER-HANDBOOK.md`

## MVP Places

| Place | Mode | Role |
|-------|------|------|
| Utopia Plaza Hub | Permanent day | Spawn, Museum, Teleport |
| Solhaven | Permanent day | Garden, treasure, trade |
| Nocturne Alley | Permanent twilight | Mystery, cipher — not horror |
| Utopia of Eternity | Permanent day | Solarpunk, photo mode, fashion |
| หุบเขามรณะ | Eternal night | Opt-in horror survival (Hellbound) |

## Project root

```
/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game/
```

## Project layout

```
utopia-of-eternity-game/
├── default.project.json
├── docs/
│   ├── 00-START-HERE.md
│   ├── PROJECT-MASTER-HANDBOOK.md    ← full history Phase 0→R
│   ├── INDEX.md
│   ├── design/                       ← GDD, DESIGN-V02/V03
│   ├── death-valley/phases/          ← Phase A→R specs
│   ├── commerce/, world/, legal/, systems/
│   └── visual-ref/, ugc/, reference/
├── src/
│   ├── ServerScriptService/
│   │   ├── SecurityCore.server.luau
│   │   ├── DeathValley/              ← 45 modules
│   │   ├── Commerce/, World/, Hellbound/
│   │   └── Secrets/                  ← gitignored
│   └── ReplicatedStorage/Modules/GameConfig.luau
└── bridge/                           ← FastAPI :8011
```

## Setup (Roblox Studio)

1. Install [Rojo](https://rojo.space/) 7.x
2. Run `bash scripts/init-secrets.sh`
3. **P0 publish:** Fill `PlaceSecrets.luau` + `CatalogSecrets.luau` — see `docs/P0-PUBLISH-SETUP.md`
4. Validate: `python3 scripts/validate-p0-publish.py`
5. `rojo serve` → Rojo plugin in Studio
6. Enable HttpService when Bridge is ready

## Current status (9 Jun 2026)

- **Security:** Phase 0.5 complete
- **World:** Greybox builders for all 5 places
- **Death Valley:** Phases **A through T** implemented
- **Live publish:** Universe `10293115628` — 5 places + 7 Dev Products on Roblox
- **P0:** Complete — `python3 scripts/validate-p0-publish.py` OK

## Docs map

See `docs/INDEX.md` for full listing.

## References

- Design plan: `~/.cursor/plans/roblox_ip-safe_game_design_3a5374d5.plan.md`
- Pitch: `~/Desktop/Utopia of Eternity/UTOPIA-OF-ETERNITY-PITCH.html`
- Official web: https://utopiaofeternity.com
