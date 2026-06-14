# CURSOR PROMPT — P6 Integration (3 fixes)
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก commit `3124399` (P6 Sky Treasure done)
> **เล็ก — ทำรวม 1 commit**

---

## Fix 1: PvP Kill — LastAttackerUserId บน Player (ไม่ใช่แค่ NPC)

**ไฟล์:** `src/ServerScriptService/Combat/CombatService.luau`

ในฟังก์ชัน `processAttack` ตอนนี้ set attribute บน `npc` Humanoid เท่านั้น
ต้องเพิ่มกรณี **target เป็น Player** ด้วย:

```lua
-- หลัง damage apply (ทั้ง NPC และ Player PvP)
local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
if targetHumanoid then
  targetHumanoid:SetAttribute("LastAttackerUserId", player.UserId)
end
```

หมายเหตุ:
- `target` หมายถึง model ของ NPC หรือตัวละครผู้เล่น
- PvP damage ควรเกิดเฉพาะใน Eternal Colosseum (เช็ค zone flag ก่อน) — ถ้ายังไม่มี zone flag ให้ใส่ `-- TODO: PvP zone check` แล้วข้ามไปก่อน
- BountyService.onTargetKilled จะถูก trigger ผ่าน Humanoid.Died ที่ wire ไว้ใน MercenaryHandlers อยู่แล้ว

---

## Fix 2: Wire CurrencyService เข้า 3 ระบบ

### 2a. MercenaryService.completeEscort

**ไฟล์:** `src/ServerScriptService/Mercenary/MercenaryService.luau`

เพิ่ม require ที่ top:
```lua
local CurrencyService = require(script.Parent.Parent.Commerce.CurrencyService)
```

แทนที่ `-- TODO: CurrencyService.addCredits(merc, job.pay)` ด้วย:
```lua
if merc then
  CurrencyService.addCredits(merc.UserId, job.pay)
end
```

### 2b. BountyService.onTargetKilled

**ไฟล์:** `src/ServerScriptService/Mercenary/BountyService.luau`

เพิ่ม require ที่ top:
```lua
local CurrencyService = require(script.Parent.Parent.Commerce.CurrencyService)
```

แทนที่ `-- TODO: CurrencyService.addCredits(killer, totalReward)` ด้วย:
```lua
if totalReward > 0 then
  CurrencyService.addCredits(killerId, totalReward)
end
```

### 2c. TradingService (ถ้า execute ยังไม่ transfer credits)

**ไฟล์:** `src/ServerScriptService/Commerce/TradingService.luau`

ในขั้นตอน execute ตรวจว่ามี credits transfer หรือเปล่า ถ้าไม่มีให้เพิ่ม:
```lua
local CurrencyService = require(script.Parent.CurrencyService)

-- ใน executeTrade():
-- ถ้า session มี creditOffer จาก proposer ให้โอน
if session.proposerCreditOffer and session.proposerCreditOffer > 0 then
  local ok, msg = CurrencyService.deductCredits(
    session.proposerId, session.proposerCreditOffer)
  if not ok then return false, "ยอด credits ไม่พอ: " .. msg end
  CurrencyService.addCredits(session.targetId, session.proposerCreditOffer)
end
```
ถ้า TradingService ยังไม่มี credit offer field ใน session → เพิ่ม `proposerCreditOffer: number?` ใน TradeSession type แล้ว expose ผ่าน Remote ที่มีอยู่

---

## Fix 3: ปรับ SkyTreasureConfig Spawn Y ให้ถูกต้อง

**ไฟล์:** `src/ReplicatedStorage/Modules/SkyTreasureConfig.luau`

เปิด Roblox Studio → Eternity City → วัด Y ของพื้นเมือง (HumanoidRootPart ของผู้เล่นเมื่อยืนปกติ)
ค่า default ในโค้ดตั้งไว้ Y = 2010 — ปรับตามจริง:

```lua
SpawnPoints = {
  { id = "marina_dock",    position = Vector3.new(120, <Y_จริง>, -80),   displayName = "Marina Dock"    },
  { id = "aurora_plaza",   position = Vector3.new(-40, <Y_จริง>, 200),   displayName = "Aurora Plaza"   },
  { id = "canal_bridge",   position = Vector3.new(60,  <Y_จริง>, 350),   displayName = "Canal Bridge"   },
  { id = "sky_rail_north", position = Vector3.new(-200,<Y_จริง>, 0),     displayName = "Sky Rail North" },
  { id = "market_square",  position = Vector3.new(0,   <Y_จริง>, -200),  displayName = "Market Square"  },
},
```

วิธีหา Y จริง: เปิด Studio → Eternity City → เล่น → print(game.Players.LocalPlayer.Character.HumanoidRootPart.Position.Y)

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-p6int.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ServerScriptService/Combat/CombatService.luau \
  src/ServerScriptService/Mercenary/MercenaryService.luau \
  src/ServerScriptService/Mercenary/BountyService.luau \
  src/ServerScriptService/Commerce/TradingService.luau \
  src/ReplicatedStorage/Modules/SkyTreasureConfig.luau
```

## Git commit (ถ้า clean)

```bash
git add -A
git commit -m "fix(P6-integration): wire CurrencyService + PvP kill attr + spawn Y

- CombatService: SetAttribute LastAttackerUserId on player target too
- MercenaryService: CurrencyService.addCredits on completeEscort
- BountyService: CurrencyService.addCredits on bounty claim
- TradingService: CurrencyService deduct/add on credit offer execute
- SkyTreasureConfig: adjust spawn Y to match Eternity City altitude"
```

## รายงานกลับ
- ✅/❌ BUILD
- ✅/❌ STRICT CLEAN (error+line)
- commit hash
- **Y altitude ที่วัดได้จริงใน Studio** (จะได้อัปเดต Blueprint)
