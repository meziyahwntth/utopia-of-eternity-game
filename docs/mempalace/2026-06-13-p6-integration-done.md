# MemPalace Diary — P6 Integration Done
**วันที่:** 13 มิ.ย. 2026 · **Commit:** 94ac45e

## สิ่งสำคัญที่ต้องจำ

- **Eternity City floor Y = 2004** (SkyAltitude 2000 + localFloor + 4 offset) — อ้างจาก WorldBuildConfig
- sky_rail_north Y = 2010 (สูงกว่าปกติ 6 studs — ชั้นบน), canal_bridge Y = 2007
- `markLastAttacker(target, userId)` helper ใน CombatService — ทั้ง NPC และ Player path
- `processPlayerAttack()` มี `-- TODO: PvP zone check (Eternal Colosseum only)` — ยังไม่ wire remote
- `TradeUpdateCreditOffer` remote เพิ่มใน CommerceRemoteSetup แล้ว
- `updateCreditOffer()` ใน TradingService (validate ก่อน, deduct/add สองทาง)

## Out of scope (ทำทีหลัง)
- PvP zone gating (Eternal Colosseum place check)
- TradingClient credit offer UI (ช่องกรอกจำนวน credits ในหน้าต่างเทรด)
- Bounty post escrow (หัก credits ผู้โพสต์ก่อน ไม่ใช่แค่ track)

## ถัดไป: P7 Camera/UX
- `CameraModeController.client.luau` — 3 มุม (1st/3rd/TopDown) + save preference
- Visible power (aura/glow ตาม Player Tier)
