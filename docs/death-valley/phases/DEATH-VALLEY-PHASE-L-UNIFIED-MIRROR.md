# Death Valley Phase L — Unified Loadout & Hub Mirror

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-K-LOADOUT-HUB.md`

---

## Phase L Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| L1 | **Unified Tab UI** | Titles · Cosmetics · Presets ใน panel เดียว · key **V** |
| L2 | **Preset Slots (×3)** | บันทึก/apply คู่ title+cosmetic · DataStore persist |
| L3 | **Hub Mirror Showcase** | Server clone บน pedestal · ผู้เล่นอื่นเห็นใน Hub |

---

## L1 — Unified UI

- Client: `DeathValleyUnifiedLoadoutUI.client.luau`
- Keys: **V** (wardrobe) · **T** / **C** เปิด tab ที่เกี่ยวข้อง
- Legacy pickers → redirect scripts

---

## L2 — Presets

- Server: `DeathValleyLoadoutPresetService.luau`
- PlayerStore: `loadoutPresets` (3 slots)
- Remotes: `GetLoadoutFull`, `SaveLoadoutPreset`, `ApplyLoadoutPreset`, `ClearLoadoutPreset`

---

## L3 — Hub Mirror

- Server: `DeathValleyLoadoutMirrorService.luau`
- Visuals: `DeathValleyLoadoutVisuals.luau` (shared client + server)
- Hub part: `ValleyLoadoutMirror` + 3× `MirrorPedestal`

---

## Validation

```bash
rg "UnifiedLoadout|LoadoutPreset|LoadoutMirror|LoadoutVisuals|MirrorPedestal" utopia-of-eternity-game/src/
python3 -m json.tool utopia-of-eternity-game/default.project.json > /dev/null
```
