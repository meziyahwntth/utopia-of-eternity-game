# MemPalace Diary — P3-C+ Combat + Radial Wheel + P4 Economy
**วันที่:** 13 มิ.ย. 2026 · **Session:** Cursor รัน ACTION PLAN ลำดับ 1–3

---

## commits

| Phase | Commit | งาน |
|-------|--------|-----|
| P3-C+ Combat Foundation | `905740e` | CombatService (3-layer sanity) + AutoBattleService + AutoBattleClient |
| P3-C+ Radial Wheel | `fbf8b50` | RadialMenuConfig (8 ทิศ, 48px) + InteractionClient radial + tween |
| P4 Economy Core | `b0856c4` | ItemTierConfig, ItemCraftingConfig, WeightService, TradingService, TradingClient |

---

## สิ่งสำคัญ

- **Combat**: WeaponType/WeaponTier explicit type — แก้ก่อน commit
- **Radial Wheel**: tween scale 0→1, Highlight+BillboardGui เมื่อเปิดเมนู, touch zone 48px
- **Trading flow**: propose → lock → confirm → execute (server-authoritative, กัน race condition)
- **Weight penalty**: -50% WalkSpeed + CombatMultiplier เมื่อ overweight (อ่านจาก WeightConfig)
- **Material Sink**: ItemCraftingConfig recipe ★★★ Sword ต้องการ StoneFragment×500 (low-tier)

---

## ถัดไป
P5 Clan War → ClanWarService + TaxDistributionService + TerritoryStore + DefensiveFatigueService
