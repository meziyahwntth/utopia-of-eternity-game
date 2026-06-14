# MemPalace Diary — Mobile-First Design Mandates
**วันที่:** 13 มิ.ย. 2026 · **Session:** Blueprint Update

---

## งานที่ทำ

อัปเดต `docs/MASTER-BLUEPRINT.md` ด้วย Mobile-First Design requirements จาก Praphan

### ระบบใหม่ที่เพิ่มใน Blueprint (§10)

| ระบบ | ที่มา | Phase |
|------|------|-------|
| Radial Interaction Wheel (วงล้อคำสั่ง) | Ragnarok Mobile | P3-C+ |
| Target Lock System + Highlight + BillboardGui | Lineage W | P3-C+ |
| Auto-Battle / Auto-Skill Toggle | Lineage W | P3-C+ |
| Follow System (PathfindingService) | Ragnarok Mobile | P3-C done stub |
| Trade Window 2-step confirm | MMORPG standard | P4 |
| HUD Layout mobile-first (Scale, thumb zones) | Mobile standard | P4+ |
| Player Action Log / Anti-Bot DataStore | Admin system | P6 |
| In-game Report button | Admin system | P3-C done stub |
| Collapsible UI (auto-hide ≤5s) | Mobile standard | ทุก phase |

### การตัดสินใจสำคัญ

- **Radial Menu แทน List**: context menu เดิม (InteractionClient P3-C) เป็น list → ต้องอัปเกรดเป็น Radial Wheel
- **HUD Zone Map**: Bottom-right = Action/Skill ใหญ่; Bottom-left = Menu/Toggle; Top = Info
- **Scale-only rule**: ทุก UI component หลักต้องใช้ Scale ไม่ใช่ Offset + UIAspectRatioConstraint
- **Auto-Battle**: server-authoritative เสมอ (client ส่ง intent → server ยืนยัน) กันบอท exploit
- **Touch Zone**: ปุ่มทุกอัน ≥44×44 px ที่ 360p

### เสา Design Pillars เพิ่มขึ้น
จาก 5 เสา → **6 เสา**: เพิ่ม "📱 Mobile-First UX" เป็นเสาที่ 6

---

## ไฟล์ที่อัปเดต
- `docs/MASTER-BLUEPRINT.md` — เพิ่ม §10, อัปเดตตาราง §4 (Social/Live/Economy), เพิ่ม Pillar 6
