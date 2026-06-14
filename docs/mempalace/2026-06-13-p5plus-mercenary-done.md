# MemPalace Diary — P5+ Mercenary & Bounty Done
**วันที่:** 13 มิ.ย. 2026 · **Commit:** c68c6da

## สิ่งสำคัญ
- Bounty claim trigger: `Humanoid.LastAttackerUserId` (number) ต้องตั้งใน CombatService ก่อนตาย
- CurrencyService ยัง TODO — credits โอนจริงใน P6
- OpenBountyBoard: BindableEvent ใน ReplicatedStorage (NPC ProximityPrompt fire ได้เลย)
- Wire `Humanoid.Died → onTargetKilled` อยู่ใน MercenaryHandlers แล้ว (ใช้ LastAttackerUserId)

## ถัดไป
1. Fix LastAttackerUserId ใน CombatService (เล็ก — ทำรวมกับ P6)
2. P6 Sky Treasure RNG Event + CurrencyService
