# CURSOR PROMPT — Bounty Post Escrow
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก Trade Credit UI
> แก้เฉพาะ: `ServerScriptService/Mercenary/BountyService.luau`

---

## บริบท / ปัญหา

`BountyService.post()` สร้าง bounty โดย **ไม่ตัดเงิน** จาก poster ทำให้:
- poster โพสต์ bounty ได้โดยไม่มีเงินจริง
- ถ้า bounty expire ก็ไม่มีเงินคืน (ไม่มี escrow เลย)

**API ที่มีอยู่:**
- `CurrencyService.getBalance(userId)` → number
- `CurrencyService.deductCredits(userId, amount)` → (boolean, string)
- `CurrencyService.addCredits(userId, amount)` → boolean
- path: `ServerScriptService/Commerce/CurrencyService`
- **CurrencyService มี require อยู่แล้วใน BountyService** (ดูบรรทัด `CurrencyService.addCredits(killerId, totalReward)`)

---

## การแก้ไข (แก้เฉพาะ BountyService.luau)

### แก้ 1 — `BountyService.post()` ตรวจ + ตัดเงิน escrow

ค้นหาฟังก์ชัน `post()` (บรรทัดที่ 45) แล้วเพิ่มหลังบล็อก `MaxBountiesPerPlayer` check และก่อน `makeBountyId()`:

```lua
-- ตรวจ balance ก่อน
local balance = CurrencyService.getBalance(poster.UserId)
if balance < amount then
  return false, string.format("credits ไม่พอ (มี %d, ต้องการ %d)", balance, amount)
end

-- ตัดเงิน escrow
local deducted, deductErr = CurrencyService.deductCredits(poster.UserId, amount)
if not deducted then
  return false, "ตัด credits ล้มเหลว: " .. tostring(deductErr)
end
```

### แก้ 2 — expire task คืนเงินถ้า unclaimed

ค้นหา `task.delay(expirySecs, function()` แล้ว **replace block ทั้งหมด**:

```lua
task.delay(expirySecs, function()
  local bounty = bounties[id]
  if bounty and not bounty.claimed then
    bounties[id] = nil
    -- คืนเงิน escrow ให้ poster
    local refunded = CurrencyService.addCredits(bounty.posterId, bounty.amount)
    if not refunded then
      warn("[BountyService] refund failed for poster", bounty.posterId)
    end
  end
end)
```

### แก้ 3 — `onTargetKilled()` ไม่ต้องตัดเงินซ้ำ (เงินถูกตัดตอน post แล้ว)

ตรวจสอบว่าใน `onTargetKilled()` ไม่มีการเรียก `deductCredits` อีก (ปัจจุบันเรียกแค่ `addCredits(killerId, totalReward)` ซึ่งถูกต้องแล้ว — ไม่ต้องแก้)

---

## สิ่งที่รู้ล่วงหน้า

| ประเด็น | รายละเอียด |
|---------|-----------|
| escrow เป็น in-memory | ถ้า server restart ระหว่าง bounty active → poster เสียเงินโดยไม่ได้คืน (acceptable สำหรับตอนนี้ — DataStore bounty เป็น future work) |
| `CurrencyService` require | มีอยู่แล้วใน BountyService ไม่ต้อง require ใหม่ |
| `BountyMinAmount = 100` | ตรวจ balance ≥ amount ครอบคลุม min แล้ว |
| `MaxBountiesPerPlayer = 5` | นับ bounty บน target ไม่ใช่ของ poster — poster ยังโพสต์ได้หลายคน |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-bounty-escrow.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ServerScriptService/Mercenary/BountyService.luau
```

## ทดสอบใน Studio (Server console)

```lua
local BS = require(game.ServerScriptService.Mercenary.BountyService)
local CU = require(game.ServerScriptService.Commerce.CurrencyService)
local p  = game.Players:GetPlayers()[1]

-- ทดสอบ 1: ไม่มีเงิน → ควร fail
print(BS.post(p, 99999, 500))  -- false, "credits ไม่พอ"

-- ทดสอบ 2: มีเงิน → ตัดเงินทันที
CU.addCredits(p.UserId, 1000)
print(CU.getBalance(p.UserId))  -- 1000
local ok, id = BS.post(p, 99999, 300)
print(ok, id)                   -- true, bountyId
print(CU.getBalance(p.UserId))  -- 700 (ตัดแล้ว)
```

## Git commit (ถ้า clean)

```bash
git add src/ServerScriptService/Mercenary/BountyService.luau
git commit -m "fix(Bounty): escrow credits on post, refund on expire

- post(): check balance before creating bounty
- post(): deductCredits immediately (escrow)
- expire task: addCredits(posterId, amount) if unclaimed on expiry"
```

## รายงานกลับ

- ✅/❌ BUILD · ✅/❌ STRICT CLEAN · commit hash
- ทดสอบ: balance หลัง post ลดไหม / balance หลัง fail ไม่เปลี่ยนไหม
