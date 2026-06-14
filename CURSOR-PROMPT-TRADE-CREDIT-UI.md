# CURSOR PROMPT — TradingClient Credit Offer UI
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก Crafting (3488b91)
> แก้เฉพาะ: `StarterPlayerScripts/TradingClient.client.luau`

---

## บริบท

`TradingService` และ `TradingHandlers` รองรับ credit offer ครบแล้ว:
- `TradeUpdateCreditOffer` RF อยู่ใน `CommerceRemotes` (line 33 ของ TradingHandlers)
- `TradeSession.a/b.creditOffer` ถูก publish ใน `TradeSessionUpdate` event ทุกครั้ง

**ปัญหา:** `TradingClient.client.luau` ไม่มี UI ให้ผู้เล่นกรอก credit offer — ขาดแค่ TextBox + ปุ่ม

---

## การแก้ไข (แก้เฉพาะ TradingClient.client.luau)

### ขั้นที่ 1 — เพิ่ม RF variable (หลัง `tradeCancel`)

```lua
local tradeUpdateCreditOffer = remotes:WaitForChild("TradeUpdateCreditOffer") :: RemoteFunction
```

### ขั้นที่ 2 — ขยาย window.Size

เปลี่ยน:
```lua
window.Size = UDim2.fromOffset(420, 320)
```
เป็น:
```lua
window.Size = UDim2.fromOffset(420, 360)
```

### ขั้นที่ 3 — เพิ่ม credit row (วางหลัง partnerPanel, ก่อน makeBtn)

```lua
-- ============ Credit Offer Row ============
local creditRow = Instance.new("Frame")
creditRow.Size             = UDim2.new(1, -16, 0, 34)
creditRow.Position         = UDim2.fromOffset(8, 226)
creditRow.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
creditRow.BorderSizePixel  = 0
creditRow.Parent           = window
Instance.new("UICorner", creditRow).CornerRadius = UDim.new(0, 6)

local creditIcon = Instance.new("TextLabel")
creditIcon.Size   = UDim2.fromOffset(80, 34)
creditIcon.BackgroundTransparency = 1
creditIcon.TextColor3 = Color3.fromRGB(255, 200, 50)
creditIcon.Font   = Enum.Font.GothamBold
creditIcon.TextSize = 12
creditIcon.Text   = "💰 Credits:"
creditIcon.Parent = creditRow

local creditBox = Instance.new("TextBox")
creditBox.Size              = UDim2.fromOffset(120, 26)
creditBox.Position          = UDim2.fromOffset(84, 4)
creditBox.BackgroundColor3  = Color3.fromRGB(25, 35, 60)
creditBox.BorderSizePixel   = 0
creditBox.TextColor3        = Color3.new(1, 1, 1)
creditBox.PlaceholderText   = "0"
creditBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
creditBox.Text              = "0"
creditBox.Font              = Enum.Font.GothamBold
creditBox.TextSize          = 13
creditBox.ClearTextOnFocus  = true
creditBox.Parent            = creditRow
Instance.new("UICorner", creditBox).CornerRadius = UDim.new(0, 4)

local setCreditBtn = Instance.new("TextButton")
setCreditBtn.Size             = UDim2.fromOffset(80, 26)
setCreditBtn.Position         = UDim2.fromOffset(208, 4)
setCreditBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 160)
setCreditBtn.BorderSizePixel  = 0
setCreditBtn.Text             = "ยืนยัน"
setCreditBtn.TextColor3       = Color3.new(1, 1, 1)
setCreditBtn.Font             = Enum.Font.GothamBold
setCreditBtn.TextSize         = 12
setCreditBtn.Parent           = creditRow
Instance.new("UICorner", setCreditBtn).CornerRadius = UDim.new(0, 4)

local partnerCreditLabel = Instance.new("TextLabel")
partnerCreditLabel.Size              = UDim2.fromOffset(110, 26)
partnerCreditLabel.Position          = UDim2.fromOffset(298, 4)
partnerCreditLabel.BackgroundTransparency = 1
partnerCreditLabel.TextColor3        = Color3.fromRGB(180, 230, 180)
partnerCreditLabel.Font              = Enum.Font.Gotham
partnerCreditLabel.TextSize          = 12
partnerCreditLabel.Text              = "คู่: 0 💰"
partnerCreditLabel.TextXAlignment    = Enum.TextXAlignment.Left
partnerCreditLabel.Parent            = creditRow
```

### ขั้นที่ 4 — เลื่อน makeBtn ลง 40px

เปลี่ยน `UDim2.fromOffset(x, 232)` ใน `makeBtn` เป็น `UDim2.fromOffset(x, 272)`:

```lua
-- เดิม:
btn.Position = UDim2.fromOffset(x, 232)
-- แก้เป็น:
btn.Position = UDim2.fromOffset(x, 272)
```

### ขั้นที่ 5 — wire setCreditBtn

เพิ่มหลัง creditRow block:

```lua
setCreditBtn.MouseButton1Click:Connect(function()
  if myLocked then return end
  local amount = tonumber(creditBox.Text) or 0
  amount = math.max(0, math.floor(amount))
  creditBox.Text = tostring(amount)
  local ok, msg = pcall(function()
    return tradeUpdateCreditOffer:InvokeServer(amount)
  end)
  if not ok then
    statusLabel.Text = "❌ ใส่ credits ล้มเหลว"
  end
end)
```

### ขั้นที่ 6 — อัปเดต TradeSessionUpdate handler

ในฟังก์ชันที่รับ `tradeSessionUpdate.OnClientEvent` ค้นหาส่วนที่ update `myList.Text` และ `partnerList.Text` แล้วเพิ่มการแสดง creditOffer:

```lua
-- หาตำแหน่งที่ update myList / partnerList (มีอยู่แล้ว)
-- เพิ่มต่อท้ายใน handler เดิม:

-- อัปเดต credit display
local myCredit   = 0
local ptnCredit  = 0
if data then
  -- data มี structure: { a = {userId, items, creditOffer, locked}, b = {...} }
  local isA = (data.a and data.a.userId == myUserId)
  local mySide = if isA then data.a else data.b
  local ptnSide= if isA then data.b else data.a
  if mySide  then myCredit  = mySide.creditOffer  or 0 end
  if ptnSide then ptnCredit = ptnSide.creditOffer or 0 end
end
creditBox.Text         = tostring(myCredit)
partnerCreditLabel.Text= "คู่: " .. ptnCredit .. " 💰"

-- ล็อก TextBox เมื่อ lock แล้ว
creditBox.TextEditable    = not myLocked
setCreditBtn.Active       = not myLocked
setCreditBtn.BackgroundColor3 = if myLocked
  then Color3.fromRGB(40, 40, 40)
  else Color3.fromRGB(60, 100, 160)
```

---

## สิ่งที่รู้ล่วงหน้า

| ประเด็น | รายละเอียด |
|---------|-----------|
| `data` structure ใน SessionUpdate | ดู TradingHandlers `publish()` — ส่งมา: `{ sessionId, a={userId,items,creditOffer,locked,confirmed}, b={...} }` |
| `myUserId` | มีอยู่แล้วใน scope ของ TradingClient (`localPlayer.UserId`) |
| `myLocked` | มีอยู่แล้ว (`myLocked = false` ต้นไฟล์) |
| `TradeUpdateCreditOffer` RF | ใน `CommerceRemotes` ไม่ใช่ `SocialRemotes` |
| TextBox input validation | `tonumber()` + `math.max(0, math.floor())` ป้องกัน negative + float |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-tradecredit.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/StarterPlayer/StarterPlayerScripts/TradingClient.client.luau
```

## ทดสอบใน Studio

1. เปิด Studio 2 client (LocalTest)
2. กด Trade บน interactionClient → เปิด Trade window
3. พิมพ์ `100` ใน TextBox → กด "ยืนยัน"
4. อีก client เห็น "คู่: 100 💰"
5. Lock → Confirm ทั้งสองฝั่ง → credits โอนจริง

## Git commit (ถ้า clean)

```bash
git add src/StarterPlayer/StarterPlayerScripts/TradingClient.client.luau
git commit -m "feat(Trade): credit offer UI in trade window

- Add credit TextBox + ยืนยัน button in trade window
- Wire TradeUpdateCreditOffer RF (already exists in TradingHandlers)
- Show partner credit offer in real-time via TradeSessionUpdate
- Lock input when own side locked"
```

## รายงานกลับ

- ✅/❌ BUILD · ✅/❌ STRICT CLEAN · commit hash
- credit แสดงฝั่งคู่ได้ไหม
