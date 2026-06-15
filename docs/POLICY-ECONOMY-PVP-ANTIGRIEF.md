# นโยบายถาวร: Economy + PvP / Anti-Grief

> 15 มิ.ย. 2026 · อนุมัติโดย Praphan · **เป็นกฎถาวร** — ทุกระบบเศรษฐกิจ/PvP/social ต้องยึดเอกสารนี้
> อิงของจริง: `Security/GriefingGuard`, `RemoteGuard`, ranged PvE-only (blueprint E2), no-P2W (MASTER-BLUEPRINT), pricing (blueprint E5)

## A. Economy — Time vs Convenience (ไม่มี Pay-to-Win)

### หลักแกน
- **สกุลเงินของ progression คือ "เวลา" ไม่ใช่ "เงิน"**
- **Solo เล่นฟรีได้ครบทุกอย่าง** — แค่ช้ากว่า ไม่มีเนื้อหาไหนถูกล็อกหลังเงินหรือหลัง party-only
- **Social = เร็วกว่าฟรี** — โบนัส EXP/drop/ค่าเงินจากปาร์ตี้/จิตอาสา/clan (earned ไม่ใช่ซื้อ)
- **เงินซื้อได้แค่ "ความสะดวก + ความสวย" ไม่ใช่ "พลัง"**

### อนุญาตให้ขาย (✅) vs ห้ามขาย (❌)
| ✅ ขายได้ (convenience/cosmetic) | ❌ ห้ามขาย (power = P2W) |
|---|---|
| Time-saver (ลดเวลา cooldown/craft/เดินทาง) | ค่าพลัง/ดาเมจ/HP ที่ทำให้ชนะ PvP/PvE |
| Slot เพิ่ม (pet/mercenary/inventory) | อาวุธ/เกราะที่แรงกว่าของฟรีแบบหาไม่ได้ในเกม |
| Cosmetic / Grandeur (ความสวย ไม่เพิ่มพลัง) | drop-rate boost ที่ทำลายสมดุล PvP |
| Battle pass (reward ที่ฟรีก็ไปถึงได้ แค่ช้ากว่า) | ขายชัยชนะ/อันดับ leaderboard โดยตรง |
| QoL (เก็บอัตโนมัติ, fast travel) | gating เนื้อหาหลักไว้หลัง paywall |

### Solo ที่อยากเร็วโดยไม่เข้าสังคม
จ่ายเพื่อ **"สะดวก"** ได้ (time-saver/slot) — **ไม่ใช่จ่ายเพื่อ "ชนะ"** → solo ไม่ถูกบังคับ P2W, social ไม่ถูกบังคับ, ทุกคนแข่งบนพลังที่ "หาได้ในเกม" เท่ากัน

> ⚠️ **ยกเลิกแนวคิด "solo ต้อง P2W"** — ขัด no-P2W + ไล่กลุ่ม solo (ที่มีเยอะ) หนี · แทนด้วยโมเดล time-vs-convenience นี้ ([[../world/SOLO-PLAYER-SUPPORT-2026-06.md]])

## B. PvP Zoning

- **PvP = opt-in + zone-gated เท่านั้น** — ผู้เล่นเลือกเข้าโซน/เปิด flag เอง
- โซน PvP: Nocturne arena (3rd-person), อนาคต FPS instanced place (เลื่อนไว้)
- **นอกโซน PvP: การโจมตีไม่มีผลใด ๆ ต่อผู้เล่นที่ไม่ยินยอม** — **ไม่มีทั้งดาเมจ และไม่มีเอฟเฟกต์บนตัว/จอเหยื่อ** (กันสแปมบังจอ โดยเฉพาะมือถือ)
- ranged weapon คง **PvE-only** (blueprint E2) — ยิงโดนผู้เล่นไม่ได้นอกโซน

## C. Anti-Grief (แอดมินมีจริยธรรม เข้มงวด)

- **ห้าม "ใบอนุญาตกวนฝ่ายเดียว"** — ยกเลิกแนวคิด "ตีรำคาญนอกโซน" เพราะความรำคาญ = griefing ที่ไล่คนหนี
- อยากตีกันเล่น → **Duel/Spar แบบ consensual (กดยอมรับ 2 ฝ่าย)** หรือใช้ emote/ท่าทาง แทนการกระทำฝ่ายเดียว
- **Block/Mute ผู้เล่น** ต่อบุคคล (ตัดเอฟเฟกต์/แชท/ตามตัว)
- ใช้ **`GriefingGuard`** (มีอยู่) จับ pattern การตามรังควาน/สแปม → auto-flag/limit ; ผ่าน `RemoteGuard` rate-limit ทุก remote
- เกเรอยากปล่อยของ → ส่งเข้า **PvP zone/arena** (sandbox) ไม่ใช่ปล่อยกวนคน cozy/solo

## D. หลักคิดสรุป
- ให้ **"พื้นที่"** กับคนชอบ PvP/social แทนการให้ **"ใบอนุญาตกวน/บังคับ"** คนที่ไม่เล่นแนวนั้น
- ทุกคนแข่งบนพลังที่ "หาได้ในเกม" — เงิน = สะดวก/สวย, เวลา+สังคม = เร็ว, ฝีมือ = ชนะ
- balance/ราคา/scaling ทั้งหมดผ่าน config ปรับได้ ไม่แตะ logic

## E. ผลต่อ implementation (Cursor งานต่อ)
- Monetization/PurchaseService: บังคับ rule ✅/❌ ข้างบน (no power for sale)
- PvP: zone flag + damage filter (นอกโซน = 0 ผลต่อ non-consenting) + Duel consensual handshake
- Anti-grief: wire GriefingGuard กับ proximity/spam pattern + Block/Mute API
- ผูกกับ [[../CLASS-JOB-SYSTEM-BLUEPRINT.md]] (PvP balance ต้อง no-P2W) + Party-Size Scaling
