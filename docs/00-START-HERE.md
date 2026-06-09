# Utopia of Eternity — เริ่มที่นี่ (New Session)

**อัปเดต:** 9 มิถุนายน 2026 · **สถานะล่าสุด:** P0 live · Group owner `791898614` · Bridge production · Phase **T** payout sync

---

## สถานะ Post-Transfer (ไม่ต้องทำซ้ำ)

| รายการ | สถานะ |
|--------|--------|
| Owner → Utopia of Eternity (`791898614`) | ✅ |
| Private + APIs saved | ✅ |
| Community experience visibility | ✅ |
| Bridge `https://api.utopiaofeternity.com` | ✅ live |
| Republish 5 places | ✅ |

**รอ manual (~10 มิ.ย. 2026):** Configure → Public/Limited Save · Studio Play/Team Test  
**Trigger agent:** พิมพ์ **`Public Save แล้ว`** หลัง Save สำเร็จ

**ห้าม agent แตะ:** Roblox website / Studio จนกว่าคุณจะพร้อม (ลด account lock risk)

---

## โฟลเดอร์หลักของโปรเจกต์

```
/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game/
```

เปิด Cursor ที่ path นี้ แล้วอ่าน **`docs/PROJECT-MASTER-HANDBOOK.md`** ก่อนทำงานต่อ

---

## 3 ไฟล์ที่ต้องอ่านก่อน

| ลำดับ | ไฟล์ | ใช้เมื่อ |
|-------|------|---------|
| 1 | `docs/PROJECT-MASTER-HANDBOOK.md` | บันทึกโปรเจกต์ฉบับสมบูรณ์ — ตั้งแต่ร่างจนถึง Phase S |
| 2 | `docs/design/GDD-UTOPIA-OF-ETERNITY.md` | ภาพรวม MVP 5 Places |
| 3 | `docs/design/DESIGN-V02-SYSTEMS.md` | ระบบหลัก + Death Valley Phase A→S |

---

## Studio ทดสอบเร็ว

**แนะนำ (ไม่ต้อง Rojo Connect):** ดู **`docs/STUDIO-WORKFLOW.md`**

```bash
cd "/Users/macbook/Desktop/Utopia of Eternity/utopia-of-eternity-game"
bash scripts/studio-playtest-build.sh
# Studio → File → Open from File → /tmp/utopia-playtest.rbxlx → Play
```

```lua
-- GameConfig.luau — เมื่อ PlaceId == 0 เท่านั้น
GameConfig.StudioDev.SimulatePlaceKey = "EternityCity"  -- หรือ "DeathValley", "Hub"
```

**Computer Use (Cursor):** `bash scripts/start-cua-driver-daemon.sh` แล้ว reload Cursor (MCP: cua-driver + peekaboo). ใช้ Dashboard automation **หลัง Public/Limited Save (~10 มิ.ย.)** เท่านั้น.

```bash
rojo serve   # optional — เมื่อ Rojo plugin Connect ได้
```

---

## Phase ถัดไป (ทำได้โดยไม่แตะ Roblox web/Studio)

- **Prism Keys chain** — pickups Hub #1 · Solhaven #2 · Nocturne #3 · Eternity gate #11/#15/#20 + place guard
- **Support Desk UI** — fan report + ban appeal → Bridge (Community group ID ใน UI)
- **Blockbench UGC prep** — ดู `docs/ugc/OFFLINE-WORK-CHECKLIST.md`
- **IP audit refresh** — `docs/legal/IP-AUDIT-UTOPIA-OF-ETERNITY.md`

**รอ ~10 มิ.ย. (manual):** Public Save · Studio Play · `publish-all-places.sh`

---

## Meziyah ecosystem

Boot ก่อนทำงาน:

```bash
~/blue-topaz-ai/scripts/agent-boot-contract.sh --wing utopia-of-eternity --task-type coding --query "..."
```

| Resource | Path |
|----------|------|
| Memory | `~/Obsidian/knowledge_base/UTOPIA-OF-ETERNITY-PROJECT-MEMORY.md` |
| Mirror | `~/Obsidian/knowledge_base/projects/utopia-of-eternity/` |
| Registry | `~/blue-topaz-ai/config/projects/utopia-of-eternity.yaml` |
| Skill | `~/blue-topaz-ai/skills/utopia-of-eternity/SKILL.md` |

---

## Cursor / Agent context

- Transcript session ก่อนหน้า: ค้นหา `Phase S` ใน agent transcripts
- Design plan ต้นฉบับ: `~/.cursor/plans/roblox_ip-safe_game_design_3a5374d5.plan.md`
- Visual upgrade plan: `~/.cursor/plans/eternity_city_visual_upgrade_4abf9c47.plan.md`
