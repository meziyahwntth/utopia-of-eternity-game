# CURSOR PROMPT — Neon Utopia Place Setup + SpawnRouter
> สร้าง: 13 มิ.ย. 2026 · ทำหลัง Fusion/Card/Rune + MVP Boss เสร็จแล้ว
> งาน: wire Neon Utopia Place ที่มี builder แล้ว → ผู้เล่นใหม่ spawn ที่นี่ + ขึ้นยานไป Eternity

---

## บริบท

`NeonUtopiaWorldBuilder.luau` มีอยู่แล้วและ build greybox ได้ แต่:
1. **ยังไม่มี Roblox Place ID** — ต้องสร้าง Place ใน Dashboard ก่อน
2. **SpawnService ยังไม่ route ผู้เล่นใหม่** ไป Neon Utopia
3. **AirTransportService** ยังไม่มี teleport จาก Neon → Eternity City
4. GameConfig มี `SimulatePlaceKey = "EternityCity"` — ต้องเปลี่ยนได้เมื่อทดสอบ Neon

**ไฟล์ที่มีอยู่แล้ว:**
- `NeonUtopiaWorldBuilder.luau` — greybox builder พร้อม DeparturePad
- `SpawnService.luau` — `ServerScriptService/World/SpawnService`
- `WorldPlaceGuard.luau` — `ShouldBuild("NeonUtopia")` มีอยู่แล้ว
- `GameConfig.luau` — line 33: `NeonUtopia = { ... }`, line 584: `SimulatePlaceKey = "EternityCity"`
- `WorldBootstrap.luau` — เรียก `BuildCurrent()` ทุก builder

---

## ขั้นตอนที่ 1 — สร้าง Roblox Place (Manual, ทำใน Browser)

> ⚠️ Cursor ทำขั้นตอนนี้ไม่ได้ — Praphan ทำเองใน create.roblox.com

1. ไปที่ [create.roblox.com](https://create.roblox.com) → Group "Utopia of Eternity" → Experiences
2. เปิด Experience "Utopia of Eternity"
3. แท็บ **Places** → "Add Place" (หรือ "Create new place") → ตั้งชื่อ **"Neon Utopia"**
4. คัดลอก **Place ID** ของ Neon Utopia (ตัวเลขใน URL)
5. นำ Place ID มาใส่ใน GameConfig (ขั้นตอนที่ 2)

---

## ขั้นตอนที่ 2 — แก้ GameConfig.luau ใส่ Place ID

ค้นหาส่วน `NeonUtopia = {` ใน GameConfig.luau แล้วเพิ่ม `PlaceId`:

```lua
-- เดิม (ประมาณบรรทัด 33):
NeonUtopia = {
  -- ... config อื่น ๆ
},

-- แก้เป็น: เพิ่ม PlaceId จริงที่ได้จาก Dashboard
NeonUtopia = {
  PlaceId = XXXXXXXXXXXXXXX,  -- ← ใส่ Place ID จริงที่ได้จาก step 1
  -- ... config อื่น ๆ ที่มีอยู่แล้ว
},
```

> **หมายเหตุ:** ถ้า `NeonUtopia` section ใน GameConfig ยังไม่มี `PlaceId` field ให้เพิ่มเป็น field แรก

---

## ขั้นตอนที่ 3 — สร้าง AirTransportService.luau

ไฟล์ใหม่สำหรับ teleport ผู้เล่นจาก Neon → Eternity City:

```lua
--!strict
-- ServerScriptService/World/AirTransportService.luau
-- จัดการการขึ้น Air Transport: ตรวจตั๋ว → หัก → TeleportService ไป Eternity

local Players          = game:GetService("Players")
local TeleportService  = game:GetService("TeleportService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local AirTransportService = {}

-- Ticket item ID (ใช้ PlayerItemStore)
local TICKET_ITEM_ID = "AirTicket"
local TICKET_COST    = 1   -- ตั๋ว 1 ใบต่อเที่ยว

local function getItemStore()
  return require(ServerScriptService.Progression.PlayerItemStore) :: any
end

-- ตรวจสอบว่า player อยู่ใกล้ DeparturePad ไหม (ป้องกันโกง)
local function isNearPad(player: Player): boolean
  local char = player.Character
  local hrp  = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
  if not hrp then return false end

  local pad = workspace:FindFirstChild("UtopiaNeonCity")
  if not pad then return true end  -- ถ้าไม่มี model → อนุโลม
  local padPart = (pad :: Model):FindFirstChild("AirTransportDeparturePad") :: BasePart?
  if not padPart then return true end

  local dist = (hrp.Position - padPart.Position).Magnitude
  return dist < 60  -- 60 studs จาก pad
end

function AirTransportService.boardTransport(player: Player): (boolean, string)
  if not isNearPad(player) then
    return false, "ต้องไปที่แท่นออกเดินทางก่อน"
  end

  local itmStore = getItemStore()
  local tickets  = itmStore.getQty(player.UserId, TICKET_ITEM_ID)
  if tickets < TICKET_COST then
    return false, string.format("ต้องมี %s %d ใบ (มี %d)", TICKET_ITEM_ID, TICKET_COST, tickets)
  end

  -- หักตั๋ว
  if not itmStore.removeItem(player.UserId, TICKET_ITEM_ID, TICKET_COST) then
    return false, "หักตั๋วล้มเหลว"
  end

  -- Teleport ไป Eternity City
  local eternityPlaceId = GameConfig.PlaceIds and GameConfig.PlaceIds.EternityCity
    or 94486544638073  -- fallback Place ID จริง

  task.spawn(function()
    local ok, err = pcall(function()
      TeleportService:TeleportAsync(eternityPlaceId, { player })
    end)
    if not ok then
      warn("[AirTransport] TeleportAsync failed:", err)
      -- คืนตั๋วถ้า teleport ล้มเหลว
      itmStore.addItem(player.UserId, TICKET_ITEM_ID, TICKET_COST)
    end
  end)

  return true, "กำลังขึ้นยาน... ไปสู่ Utopia!"
end

-- เพิ่ม AirTicket ให้ผู้เล่นใหม่ (เรียกจาก SpawnRouter)
function AirTransportService.grantStarterTickets(player: Player, count: number?)
  local n = count or 5
  local itmStore = getItemStore()
  itmStore.addItem(player.UserId, TICKET_ITEM_ID, n)
  print(string.format("[AirTransport] gave %d AirTicket to %s", n, player.Name))
end

return AirTransportService
```

---

## ขั้นตอนที่ 4 — สร้าง AirTransportHandlers.server.luau

```lua
--!strict
-- ServerScriptService/World/AirTransportHandlers.server.luau

local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local Players               = game:GetService("Players")
local AirTransportService   = require(script.Parent.AirTransportService)

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local function ensure(t: string, name: string)
  local r = remotes:FindFirstChild(name)
  if not r then
    r = Instance.new(t)
    r.Name = name
    r.Parent = remotes
  end
  return r
end

local BoardTransportRF = ensure("RemoteFunction", "BoardAirTransport") :: RemoteFunction

BoardTransportRF.OnServerInvoke = function(player: Player)
  return AirTransportService.boardTransport(player)
end

-- ให้ตั๋วเริ่มต้นผู้เล่นใหม่
Players.PlayerAdded:Connect(function(player)
  -- ตรวจว่าเป็นผู้เล่นใหม่หรือไม่ (เช็คจาก ticket qty)
  task.wait(3)  -- รอ PlayerItemStore load
  local itmStore = require(game:GetService("ServerScriptService").Progression.PlayerItemStore)
  local tickets = itmStore.getQty(player.UserId, "AirTicket")
  if tickets == 0 then
    AirTransportService.grantStarterTickets(player, 5)
  end
end)
```

---

## ขั้นตอนที่ 5 — แก้ SpawnService.luau ให้ route ผู้เล่นใหม่ไป Neon

ค้นหาใน `SpawnService.luau` ส่วนที่ handle `Players.PlayerAdded` หรือ initial spawn แล้วแก้:

```lua
-- เพิ่ม require AirTransportService (lazy)
local function getAirTransport()
  return require(script.Parent.AirTransportService) :: any
end

-- ใน Players.PlayerAdded handler (หรือสร้าง handler ใหม่ถ้ายังไม่มี):
Players.PlayerAdded:Connect(function(player: Player)
  -- ตรวจว่า place ปัจจุบันเป็น NeonUtopia ไหม
  local placeKey = GameConfig:GetCurrentPlaceKey()
  if placeKey == "NeonUtopia" then
    -- ให้ตั๋วเริ่มต้น (ถ้ายังไม่มี)
    task.wait(5)  -- รอ data load
    getAirTransport().grantStarterTickets(player, 5)
  end
end)
```

> **หมายเหตุ:** ถ้า SpawnService.luau ซับซ้อน → แค่ตรวจว่ามี `Players.PlayerAdded` แล้วเพิ่ม block นี้ต่อท้าย ไม่ต้องแก้ logic เดิม

---

## ขั้นตอนที่ 6 — สร้าง DeparturePadTrigger.server.luau

Proximity trigger ที่แท่น (server-side):

```lua
--!strict
-- ServerScriptService/World/DeparturePadTrigger.server.luau
-- ตรวจ player เข้าใกล้ AirTransportDeparturePad → แสดง UI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local function ensure(t: string, name: string)
  local r = remotes:FindFirstChild(name)
  if not r then r = Instance.new(t); r.Name = name; r.Parent = remotes end
  return r
end
local showTransportUI = ensure("RemoteEvent", "ShowAirTransportUI") :: RemoteEvent

-- รอ NeonUtopiaWorldBuilder build เสร็จ
local function findPad(): BasePart?
  local city = workspace:WaitForChild("UtopiaNeonCity", 30) :: Model?
  if not city then return nil end
  return (city :: Model):FindFirstChild("AirTransportDeparturePad") :: BasePart?
end

task.spawn(function()
  local pad = findPad()
  if not pad then
    warn("[DeparturePad] AirTransportDeparturePad not found")
    return
  end

  -- proximity detector
  local detector = Instance.new("ProximityPrompt")
  detector.ActionText = "ขึ้นยาน → Utopia"
  detector.ObjectText  = "✈ Air Transport"
  detector.MaxActivationDistance = 12
  detector.Parent = pad

  detector.Triggered:Connect(function(player: Player)
    showTransportUI:FireClient(player)
  end)
  print("[DeparturePad] Departure prompt ready")
end)
```

---

## ขั้นตอนที่ 7 — สร้าง AirTransportClient.client.luau

```lua
--!strict
-- StarterPlayerScripts/AirTransportClient.client.luau
-- แสดง UI เมื่อเข้าใกล้ DeparturePad และจัดการการขึ้นยาน

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui") :: PlayerGui
local remotes     = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local showUIEv      = remotes:WaitForChild("ShowAirTransportUI") :: RemoteEvent
local boardRF       = remotes:WaitForChild("BoardAirTransport")  :: RemoteFunction

-- UI
local sg = Instance.new("ScreenGui")
sg.Name = "AirTransportGui"
sg.ResetOnSpawn = false
sg.Parent = playerGui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(320, 180)
panel.Position = UDim2.new(0.5,-160,0.5,-90)
panel.BackgroundColor3 = Color3.fromRGB(10,15,30)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = sg
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,44)
title.BackgroundTransparency = 1
title.Text = "✈️  Air Transport → Utopia"
title.TextColor3 = Color3.fromRGB(80,200,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = panel

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1,-16,0,60)
info.Position = UDim2.fromOffset(8,48)
info.BackgroundTransparency = 1
info.Text = "ค่าโดยสาร: 1 AirTicket\nผู้เล่นใหม่ได้รับ 5 ตั๋วฟรี"
info.TextColor3 = Color3.fromRGB(200,200,200)
info.Font = Enum.Font.Gotham
info.TextSize = 13
info.TextWrapped = true
info.TextXAlignment = Enum.TextXAlignment.Left
info.Parent = panel

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,-16,0,20)
statusLabel.Position = UDim2.fromOffset(8,112)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(200,100,100)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.Parent = panel

local function makeBtn(text: string, x: number, color: Color3): TextButton
  local b = Instance.new("TextButton")
  b.Size = UDim2.fromOffset(130,36)
  b.Position = UDim2.fromOffset(x,136)
  b.BackgroundColor3 = color
  b.BorderSizePixel = 0
  b.Text = text
  b.TextColor3 = Color3.new(1,1,1)
  b.Font = Enum.Font.GothamBold
  b.TextSize = 13
  b.Parent = panel
  Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
  return b
end

local boardBtn  = makeBtn("✈️ ขึ้นยาน", 8, Color3.fromRGB(40,120,200))
local cancelBtn = makeBtn("✕ ยกเลิก", 150, Color3.fromRGB(100,40,40))

boardBtn.MouseButton1Click:Connect(function()
  boardBtn.Active = false
  statusLabel.TextColor3 = Color3.fromRGB(200,200,200)
  statusLabel.Text = "กำลังประมวลผล..."
  local ok, msg = pcall(function() return boardRF:InvokeServer() end)
  if ok and type(msg) == "string" then
    statusLabel.Text = msg
    statusLabel.TextColor3 = Color3.fromRGB(80,200,120)
    task.delay(3, function() panel.Visible = false end)
  else
    statusLabel.Text = "❌ " .. tostring(msg)
    statusLabel.TextColor3 = Color3.fromRGB(220,80,80)
    boardBtn.Active = true
  end
end)

cancelBtn.MouseButton1Click:Connect(function() panel.Visible = false end)

showUIEv.OnClientEvent:Connect(function()
  statusLabel.Text = ""
  boardBtn.Active = true
  panel.Visible = true
end)
```

---

## ขั้นตอนที่ 8 — แก้ ItemTierConfig.luau เพิ่ม AirTicket

```lua
AirTicket = {
  id="AirTicket", name="ตั๋วโดยสาร",
  requiredLevel=1, grandeurRank=0, weight=0.01,
  weaponType="None", tradeable=true,
},
```

---

## ขั้นตอนที่ 9 — default.project.json เพิ่ม entries

```json
"AirTransportService":  { "$path": "src/ServerScriptService/World/AirTransportService.luau" },
"AirTransportHandlers": { "$path": "src/ServerScriptService/World/AirTransportHandlers.server.luau" },
"DeparturePadTrigger":  { "$path": "src/ServerScriptService/World/DeparturePadTrigger.server.luau" },
"AirTransportClient":   { "$path": "src/StarterPlayer/StarterPlayerScripts/AirTransportClient.client.luau" }
```

---

## ขั้นตอนที่ 10 — ทดสอบ Neon Utopia ใน Studio

แก้ GameConfig.luau:

```lua
-- line 584:
SimulatePlaceKey = "NeonUtopia" :: string?,  -- เปลี่ยนจาก "EternityCity"
```

Build → Studio Play → เห็น UtopiaNeonCity + DeparturePad + ProximityPrompt

---

## สิ่งที่รู้ล่วงหน้า

| ประเด็น | รายละเอียด |
|---------|-----------|
| Place ID จริง | ต้องได้จาก Dashboard ก่อน — Cursor ทำขั้นตอน 2+ ได้ แต่ Step 1 Praphan ทำเอง |
| EternityCity PlaceId | fallback ใช้ `94486544638073` (Place ID จริงที่ publish แล้ว) |
| SimulatePlaceKey | กลับมาตั้งเป็น "EternityCity" หลังทดสอบ Neon เสร็จ |
| AirTicket starter | `AirTransportHandlers` ให้ 5 ตั๋วตอน PlayerAdded ถ้า ticket=0 (new player) |
| TeleportAsync | อาจ throttle ใน Studio — ทดสอบใน published game จริง |
| SpawnService | ถ้า SpawnService ซับซ้อนมาก — สร้าง `NeonSpawnInit.server.luau` แทน แล้วใส่ใน default.project.json |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game

# ทดสอบ Neon Utopia (เปลี่ยน SimulatePlaceKey ก่อน)
rojo build default.project.json --output /tmp/utopia-neon.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ServerScriptService/World/AirTransportService.luau \
  src/ServerScriptService/World/AirTransportHandlers.server.luau \
  src/ServerScriptService/World/DeparturePadTrigger.server.luau \
  src/StarterPlayer/StarterPlayerScripts/AirTransportClient.client.luau
```

## ทดสอบใน Studio (SimulatePlaceKey = "NeonUtopia")

1. Build + Studio Play
2. เห็น UtopiaNeonCity greybox + DeparturePad (cylinder สีขาว)
3. เดินเข้าใกล้ pad → เห็น ProximityPrompt "✈ Air Transport"
4. กด → เห็น UI Transport panel
5. Server console:
```lua
local AT = require(game.ServerScriptService.World.AirTransportService)
local IS = require(game.ServerScriptService.Progression.PlayerItemStore)
local p = game.Players:GetPlayers()[1]
IS.addItem(p.UserId, "AirTicket", 5)
print(AT.boardTransport(p))  -- true, "กำลังขึ้นยาน..."
-- (TeleportAsync จะ fail ใน Studio — ปกติ)
```

## Git commit

```bash
git add -A
git commit -m "feat(World): Neon Utopia Place wiring + AirTransport system

- AirTransportService: ticket check + TeleportAsync to EternityCity
  grantStarterTickets(5) for new players
- AirTransportHandlers: BoardAirTransport RF + ShowAirTransportUI RE
- DeparturePadTrigger: ProximityPrompt on AirTransportDeparturePad
- AirTransportClient: boarding UI with status feedback
- ItemTierConfig: +AirTicket item
NOTE: Neon Place ID must be set in GameConfig after Dashboard setup"
```

## รายงานกลับ

- ✅/❌ BUILD · ✅/❌ STRICT CLEAN · commit hash
- ทดสอบ: ProximityPrompt ขึ้นไหม / UI panel เปิดได้ไหม
- **Place ID จาก Dashboard** (ถ้าสร้างแล้ว) — เพื่ออัปเดต GameConfig
