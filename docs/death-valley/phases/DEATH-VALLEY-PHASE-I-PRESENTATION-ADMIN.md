# Death Valley Phase I — Presentation & Studio Admin

**Version:** 1.0 · **Date:** 8 มิถุนายน 2026  
**Builds on:** `DEATH-VALLEY-PHASE-H-ROLLOVER-SOCIAL.md`

---

## Phase I Scope

| # | Feature | รายละเอียด |
|---|---------|------------|
| I1 | **Overhead Title** | BillboardGui เหนือหัว · sync `DV_EquippedTitle` ทุก player |
| I2 | **Cosmetic Aura FX** | Client particles + light ตาม `DV_EquippedSeasonCosmetic` |
| I3 | **Studio Admin Rollover** | บังคับ end season + advance · deliver auto rewards (Studio only) |

---

## I1 — Title Billboard

- Client: `DeathValleySeasonTitleBillboard.client.luau`
- Attribute: `DV_EquippedTitle` (replicated)
- ซ่อนเมื่อ title ว่าง

---

## I2 — Cosmetic FX

- Config: `PrismDeathValleySeasonCosmetics.luau`
- Client: `DeathValleySeasonCosmeticFx.client.luau`
- รองรับ aura / trail / badge styles

---

## I3 — Studio Admin

| Remote | หน้าที่ |
|--------|--------|
| `AdminForceSeasonRollover` | End current season · queue top 25 · advance stored season |
| `AdminDeliverRolloverRewards` | Deliver pending auto rewards ให้ตัวเอง |

UI: `DeathValleyStudioAdminUI.client.luau` (Studio only · key **F9**)

---

## Validation

```bash
rg "SeasonTitleBillboard|SeasonCosmeticFx|AdminForceSeason|PrismDeathValleySeasonCosmetics" utopia-of-eternity-game/src/
```
