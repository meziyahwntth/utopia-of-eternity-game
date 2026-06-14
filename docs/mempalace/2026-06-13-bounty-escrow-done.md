# 2026-06-13 — Bounty Post Escrow ✅

## Commit: 818edc8 → origin/main

## การเปลี่ยนแปลง (BountyService.luau เท่านั้น)
- `post()`: getBalance() ก่อน → deductCredits(poster, amount) ทันที → ถ้า fail ไม่สร้าง bounty
- `task.delay` expire: addCredits(posterId, amount) คืน escrow ถ้า unclaimed
- `onTargetKilled()`: ไม่เปลี่ยน — addCredits(killerId) จากเงินที่ escrow ไว้แล้ว

## สถานะ optional backlog (อัปเดต)
- ✅ Bounty Post Escrow
- ⏳ Trade Credit UI (รอ commit hash จาก Cursor)
- ⬜ visit_zone quest hook
- ⬜ NPC Dialogue (รอ Story Bible จาก ChatGPT)
