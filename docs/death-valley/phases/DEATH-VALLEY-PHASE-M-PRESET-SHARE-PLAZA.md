# Death Valley Phase M — Preset Share & Cross-Plaza Loadout

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-L-UNIFIED-MIRROR.md`

---

## Phase M Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| M1 | **Share Preset → Friend** | ส่ง slot ให้เพื่อน · inbox persist · Apply ถ้า owned |
| M2 | **Mirror Auto-Rotate** | Clone บน pedestal หมุนช้าๆ (Hub + EC) |
| M3 | **Eternity City Plaza** | Wardrobe + mirror ใน sanctuary plaza |

---

## M1 — Preset Share

- Server: `DeathValleyLoadoutPresetShareService.luau`
- PlayerStore: `presetInbox`
- Remotes: `ShareLoadoutPreset`, `GetSharedPresets`, `ApplySharedPreset`, `DismissSharedPreset`
- UI: แท็บ **Shared** ใน unified wardrobe

---

## M2 — Auto-Rotate Mirror

- `DeathValleyLoadoutMirrorService` — Heartbeat spin · `MirrorAutoRotate` attribute
- Kit default: rotate enabled

---

## M3 — Eternity City

- `LoadoutPlazaKit.luau` — shared terminals + mirror builder
- `EternityCityWorldBuilder` — plaza @ sanctuary edge
- `LoadoutHandlers` wires `UtopiaEternityCity`

---

## Validation

```bash
rg "PresetShare|LoadoutPlazaKit|MirrorAutoRotate|SharedPresets" utopia-of-eternity-game/src/
python3 -m json.tool utopia-of-eternity-game/default.project.json > /dev/null
```
