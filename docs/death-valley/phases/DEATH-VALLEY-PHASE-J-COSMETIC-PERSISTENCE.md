# Death Valley Phase J — Cosmetic Picker & Persistence

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-I-PRESENTATION-ADMIN.md`

---

## Phase J Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| J1 | **Cosmetic Picker UI** | เลือก/ถอด aura · key **C** · แสดง owned จาก server |
| J2 | **DataStore Persistence** | `ownedCosmetics` + `equippedCosmeticId` ใน `UtopiaDeathValley_v1` |
| J3 | **Admin Reset Pointer** | ปุ่ม Reset Season Pointer ใน F9 Studio panel |

---

## J1 — Cosmetic Picker

- Client: `DeathValleySeasonCosmeticPickerUI.client.luau`
- Remotes: `GetCosmeticInventory`, `EquipSeasonCosmetic`, `UnequipSeasonCosmetic`
- Server: `DeathValleyCosmeticService.luau`

---

## J2 — Persistence

PlayerStore fields:

| Field | Type | หน้าที่ |
|-------|------|--------|
| `ownedCosmetics` | `{ string }` | cosmetic IDs ที่ได้จาก season rewards |
| `equippedCosmeticId` | `string?` | ที่ equip ล่าสุด (restore ตอน join) |

Grant flow (season reward / auto rollover) → `DeathValleyCosmeticService.grantCosmetic` → save + auto-equip.

---

## J3 — Studio Admin

| Remote | หน้าที่ |
|--------|--------|
| `AdminResetSeasonPointer` | Reset stored season → calendar current · clear ended-season test flags |

---

## Validation

```bash
rg "CosmeticPicker|CosmeticService|AdminResetSeason|equippedCosmeticId" utopia-of-eternity-game/src/
python3 -m json.tool utopia-of-eternity-game/default.project.json > /dev/null
```
