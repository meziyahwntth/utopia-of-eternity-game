# Death Valley Phase K — Loadout Hub & 3D Preview

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-J-COSMETIC-PERSISTENCE.md`

---

## Phase K Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| K1 | **Title Picker (T)** | เลือก title แยกจาก cosmetic · persist `equippedTitleSeasonId` |
| K2 | **3D Preview** | ViewportFrame ใน picker ทั้ง title + cosmetic |
| K3 | **Hub Loadout Terminal** | ตั้ง loadout ที่ Hub · sync ข้าม place ผ่าน DataStore |

---

## K1 — Title Picker

- Server: `DeathValleyTitleService.luau`
- Client: `DeathValleySeasonTitlePickerUI.client.luau` · key **T**
- Remotes: `GetTitleInventory`, `EquipSeasonTitle`, `UnequipSeasonTitle`

---

## K2 — 3D Preview

- Module: `DeathValleyLoadoutPreview.luau` (ReplicatedStorage)
- Clone local character · billboard title · cosmetic particles ใน ViewportFrame

---

## K3 — Cross-Place Hub

- Handlers: `DeathValleyLoadoutHandlers.server.luau` (Hub + DeathValley + ทุก place)
- Hub terminal attribute: `ValleyLoadoutTerminal`
- Prompt → `DV_OpenLoadoutPicker` = `"title"` | `"cosmetic"`

---

## Validation

```bash
rg "TitlePicker|LoadoutPreview|LoadoutHandlers|ValleyLoadoutTerminal|EquipSeasonTitle" utopia-of-eternity-game/src/
python3 -m json.tool utopia-of-eternity-game/default.project.json > /dev/null
```
