---
name: utopia-of-eternity-handover
description: Roblox Utopia of Eternity handover — Eternity City world build, publish, security blockers, landmark art passes
---

# Utopia of Eternity — Handover Skill

## When to use
Roblox game at `/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game/`. Eternity City world build, publish, security audit, landmark art passes.

## Boot sequence
1. Read `docs/HANDOVER_REPORT.md` and `docs/00-START-HERE.md`
2. `python3 scripts/validate-p0-publish.py`
3. `rojo build default.project.json -o ~/Desktop/utopia-playtest.rbxlx`

## Architecture
- Luau greybox builders via `WorldBootstrap` → `*WorldBuilder`
- `WorldPlaceGuard`: PlaceId 0 → `SimulatePlaceKey` (EternityCity)
- Boot order: BridgeBootstrap → BuildCurrent → WorldStudioSpawnGuard

## Eternity City landmarks (done)
MarinaRing, AuroraSpireDistrict, CanalPromenade — wired in EternityCityWorldBuilder

## Blockers
CRITICAL: DEV_GRANT_FREE, ProcessReceipt, DevGrant remote. HIGH: RemoteGuard unwired.

## Publish
`bash scripts/publish-place.sh EternityCity` only — never publish-all without user OK.

## Policy
No Roblox website automation until user approves. No secrets in commits.
