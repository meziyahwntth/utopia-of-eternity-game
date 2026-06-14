# CURSOR PROMPT — NPC Item Drop System
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก Daily Quest (01da4a0)
> อ้างอิง: `ItemCraftingConfig` materials: StoneFragment / IronOre / MagicCrystal

---

## บริบท

เมื่อฆ่า NPC → สุ่ม drop วัตถุดิบ → เก็บใน `PlayerItemStore` → ใช้ Craft ผ่าน `ItemCraftingConfig`
NPC ระบุด้วย attribute `CombatNpcId` (number) ตาม `CombatConfig.NpcIdAttribute`

**API ที่มีอยู่แล้ว (ห้ามเขียนซ้ำ):**
- `PlayerItemStore.addItem(userId, itemId, qty)` — `ServerScriptService/Progression/PlayerItemStore`
- `CombatConfig.NpcIdAttribute = "CombatNpcId"` — `ReplicatedStorage/Modules/CombatConfig`
- `NpcKillEvent` BindableEvent ใน `ReplicatedStorage` (สร้างโดย QuestHandlers)

---

## ไฟล์ที่ต้องสร้าง/แก้

| ไฟล์ | Action | Path |
|------|--------|------|
| `NpcDropConfig.luau` | สร้างใหม่ | `ReplicatedStorage/Modules/` |
| `NpcDropService.luau` | สร้างใหม่ | `ServerScriptService/Combat/` |
| `CombatService.luau` | แก้ `grantKillExp` + เพิ่ม drop call | `ServerScriptService/Combat/` |
| `DropNotifClient.client.luau` | สร้างใหม่ | `StarterPlayerScripts/` |

---

## 1. NpcDropConfig.luau

```lua
--!strict
-- ReplicatedStorage/Modules/NpcDropConfig.luau
--[[
  Drop table per NpcId (ตรงกับ CombatNpcId attribute บน NPC model)
  dropTable: รายการ item ที่อาจ drop — สุ่มแต่ละชิ้นแยกกัน (chance-per-item)
]]

export type DropEntry = {
  itemId  : string,
  minQty  : number,
  maxQty  : number,
  chance  : number,   -- 0-1 (เช่น 0.5 = 50%)
}

export type NpcDropProfile = {
  npcId    : number,
  nameTH   : string,
  dropTable: { DropEntry },
  baseXP   : number,   -- ส่งให้ CombatService ใช้แทน hardcode 25
}

-- NpcId 1-5 = ศัตรูพื้นฐาน Eternity City
-- เพิ่ม NpcId ใหม่ได้โดยไม่ต้องแก้โค้ดอื่น
return {
  Profiles = {
    [1] = {
      npcId=1, nameTH="หุ่นฝึกหัด",
      baseXP=25,
      dropTable={
        { itemId="StoneFragment", minQty=1, maxQty=3, chance=0.70 },
        { itemId="IronOre",       minQty=1, maxQty=1, chance=0.20 },
      },
    },
    [2] = {
      npcId=2, nameTH="ทหารซอมบี้",
      baseXP=35,
      dropTable={
        { itemId="StoneFragment", minQty=2, maxQty=5, chance=0.65 },
        { itemId="IronOre",       minQty=1, maxQty=2, chance=0.30 },
        { itemId="MagicCrystal",  minQty=1, maxQty=1, chance=0.05 },
      },
    },
    [3] = {
      npcId=3, nameTH="อัศวินมืด",
      baseXP=50,
      dropTable={
        { itemId="StoneFragment", minQty=3, maxQty=8, chance=0.60 },
        { itemId="IronOre",       minQty=2, maxQty=4, chance=0.40 },
        { itemId="MagicCrystal",  minQty=1, maxQty=2, chance=0.10 },
      },
    },
    [4] = {
      npcId=4, nameTH="นักเวทย์ผีดิบ",
      baseXP=65,
      dropTable={
        { itemId="IronOre",      minQty=3, maxQty=6, chance=0.50 },
        { itemId="MagicCrystal", minQty=1, maxQty=3, chance=0.25 },
        { itemId="StoneFragment",minQty=5, maxQty=10, chance=0.40 },
      },
    },
    [5] = {
      npcId=5, nameTH="ราชาหุ่น (BOSS)",
      baseXP=120,
      dropTable={
        { itemId="MagicCrystal",  minQty=3, maxQty=8,  chance=0.70 },
        { itemId="IronOre",       minQty=5, maxQty=10, chance=0.80 },
        { itemId="StoneFragment", minQty=10, maxQty=20, chance=0.90 },
      },
    },
  } :: { [number]: NpcDropProfile },

  -- fallback ถ้าไม่พบ NpcId
  DefaultProfile = {
    npcId=0, nameTH="ศัตรูไม่รู้จัก",
    baseXP=15,
    dropTable={
      { itemId="StoneFragment", minQty=1, maxQty=2, chance=0.50 },
    },
  } :: NpcDropProfile,
}
```

---

## 2. NpcDropService.luau

```lua
--!strict
-- ServerScriptService/Combat/NpcDropService.luau

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local NpcDropConfig = require(ReplicatedStorage.Modules.NpcDropConfig)

-- lazy-require PlayerItemStore
local function getItemStore()
  return require(ServerScriptService.Progression.PlayerItemStore) :: any
end

local NpcDropService = {}

export type DropResult = {
  itemId : string,
  qty    : number,
}

-- สุ่ม drop สำหรับ npcId หนึ่ง
-- คืน: รายการที่ drop ได้จริง (อาจว่าง)
function NpcDropService.rollDrops(npcId: number): { DropResult }
  local profile = NpcDropConfig.Profiles[npcId] or NpcDropConfig.DefaultProfile
  local results: { DropResult } = {}

  for _, entry in profile.dropTable do
    if math.random() <= entry.chance then
      local qty = math.random(entry.minQty, entry.maxQty)
      table.insert(results, { itemId = entry.itemId, qty = qty })
    end
  end

  return results
end

-- ใช้เมื่อ NPC ถูกฆ่า: สุ่ม drop แล้วใส่ Inventory ผู้เล่น
function NpcDropService.grantDrops(player: Player, npcId: number): { DropResult }
  local drops = NpcDropService.rollDrops(npcId)
  if #drops == 0 then return drops end

  local itemStore = getItemStore()
  for _, drop in drops do
    itemStore.addItem(player.UserId, drop.itemId, drop.qty)
  end

  -- แจ้ง client ผ่าน RemoteEvent (ถ้ามี)
  local remotes = ReplicatedStorage:FindFirstChild("SocialRemotes") :: Folder?
  if remotes then
    local ev = remotes:FindFirstChild("ItemDropped") :: RemoteEvent?
    if ev then ev:FireClient(player, drops) end
  end

  return drops
end

-- ดึง baseXP ของ NPC (ให้ CombatService ใช้แทน hardcode)
function NpcDropService.getBaseXP(npcId: number): number
  local profile = NpcDropConfig.Profiles[npcId]
  return if profile then profile.baseXP else NpcDropConfig.DefaultProfile.baseXP
end

return NpcDropService
```

---

## 3. CombatService.luau — แก้ `grantKillExp`

ค้นหาฟังก์ชัน `grantKillExp` แล้ว **replace ทั้งหมด**:

```lua
local NpcDropService = require(script.Parent.NpcDropService)

local function grantKillRewards(player: Player, npcId: number)
  -- 1. XP (ใช้ baseXP จาก NpcDropConfig แทน hardcode 25)
  local okPls, pls = pcall(function()
    return require(ServerScriptService:WaitForChild("Progression"):WaitForChild("PlayerLevelService"))
  end)
  if okPls and pls then
    local baseXP = NpcDropService.getBaseXP(npcId)
    local mult   = (pls :: any).getExpGainMultiplier(player)
    local xpGain = math.floor(baseXP * mult + 0.5)
    ;(pls :: any).addExp(player, xpGain)
  end

  -- 2. Item drops
  NpcDropService.grantDrops(player, npcId)

  -- 3. Quest hook
  local killBindable = game:GetService("ReplicatedStorage"):FindFirstChild("NpcKillEvent") :: BindableEvent?
  if killBindable then
    killBindable:Fire(player)
  end
end
```

จากนั้นใน `processAttack` / `processPlayerAttack` แทนที่การเรียก `grantKillExp(player)` ด้วย:

```lua
-- หา npcId จาก NPC model (attribute CombatNpcId)
local npcModel = findNpc(npcId)
local resolvedNpcId = if npcModel
  then (npcModel:GetAttribute("CombatNpcId") :: number? or 0)
  else 0
grantKillRewards(player, resolvedNpcId)
```

> **ลบ** ฟังก์ชัน `grantKillExp` เดิมออก (แทนด้วย `grantKillRewards` แล้ว)

---

## 4. DropNotifClient.client.luau

```lua
--!strict
-- StarterPlayerScripts/DropNotifClient.client.luau
-- แสดง drop notification เล็กๆ มุมขวาล่าง (stack สูงสุด 5 แถว)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local remotes     = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local screenGui = Instance.new("ScreenGui")
screenGui.Name         = "DropNotif"
screenGui.ResetOnSpawn = false
screenGui.Parent       = localPlayer.PlayerGui

-- container stack (bottom-up)
local container = Instance.new("Frame")
container.Size              = UDim2.fromScale(0.2, 0.35)
container.Position          = UDim2.fromScale(0.79, 0.62)
container.BackgroundTransparency = 1
container.Parent            = screenGui

local listLayout = Instance.new("UIListLayout")
listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
listLayout.Padding           = UDim.new(0, 3)
listLayout.Parent            = container

local MAX_NOTIFS = 5
local activeNotifs: { Frame } = {}

local itemColors: { [string]: Color3 } = {
  StoneFragment = Color3.fromRGB(160, 140, 100),
  IronOre       = Color3.fromRGB(140, 160, 180),
  MagicCrystal  = Color3.fromRGB(140, 80, 220),
}
local itemIcons: { [string]: string } = {
  StoneFragment = "🪨",
  IronOre       = "⛏",
  MagicCrystal  = "💎",
}

local function spawnNotif(text: string, color: Color3)
  -- จำกัดจำนวน
  while #activeNotifs >= MAX_NOTIFS do
    local oldest = table.remove(activeNotifs, 1)
    if oldest and oldest.Parent then oldest:Destroy() end
  end

  local row = Instance.new("Frame")
  row.Size             = UDim2.fromScale(1, 0)
  row.AutomaticSize    = Enum.AutomaticSize.Y
  row.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
  row.BackgroundTransparency = 0.2
  row.BorderSizePixel  = 0
  Instance.new("UICorner", row).CornerRadius = UDim.new(0.15, 0)
  row.Parent = container
  table.insert(activeNotifs, row)

  local lbl = Instance.new("TextLabel")
  lbl.Size              = UDim2.fromScale(1, 0)
  lbl.AutomaticSize     = Enum.AutomaticSize.Y
  lbl.BackgroundTransparency = 1
  lbl.TextColor3        = color
  lbl.TextScaled        = false
  lbl.TextSize          = 13
  lbl.Font              = Enum.Font.GothamBold
  lbl.Text              = text
  lbl.TextXAlignment    = Enum.TextXAlignment.Left
  Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0.05, 0)
  lbl.Parent = row

  -- fade out หลัง 3 วิ
  task.delay(3, function()
    if not row.Parent then return end
    TweenService:Create(row, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(lbl, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
    task.wait(0.55)
    if row.Parent then row:Destroy() end
    local idx = table.find(activeNotifs, row)
    if idx then table.remove(activeNotifs, idx) end
  end)
end

-- รับ drops จาก server
type DropResult = { itemId: string, qty: number }

local itemDroppedEv: RemoteEvent? = nil
task.spawn(function()
  -- รอให้ remote พร้อม
  itemDroppedEv = remotes:WaitForChild("ItemDropped", 10) :: RemoteEvent?
  if not itemDroppedEv then return end
  itemDroppedEv.OnClientEvent:Connect(function(drops)
    for _, drop in (drops :: { DropResult }) do
      local icon  = itemIcons[drop.itemId]  or "📦"
      local color = itemColors[drop.itemId] or Color3.fromRGB(200, 200, 200)
      spawnNotif(string.format("%s +%d %s", icon, drop.qty, drop.itemId), color)
    end
  end)
end)
```

---

## 5. SocialRemoteSetup — เพิ่ม ItemDropped

ใน `SocialRemoteSetup.server.luau` เพิ่มใน `ensure` list:

```lua
ensure("RemoteEvent", "ItemDropped")
```

---

## 6. default.project.json — เพิ่ม entries

```json
"NpcDropConfig":     { "$path": "src/ReplicatedStorage/Modules/NpcDropConfig.luau" },
"NpcDropService":    { "$path": "src/ServerScriptService/Combat/NpcDropService.luau" },
"DropNotifClient":   { "$path": "src/StarterPlayer/StarterPlayerScripts/DropNotifClient.client.luau" }
```

---

## สิ่งที่รู้ล่วงหน้า

| ประเด็น | รายละเอียด |
|---------|-----------|
| `findNpc(npcId)` | function มีอยู่แล้วใน CombatService — ใช้ได้ตรง |
| NpcId 0 | fallback profile (StoneFragment 50%) ป้องกัน nil |
| PetPickupRadius | attribute `PetPickupRadius` พร้อมใช้แต่ pickup system ยังไม่มี — drop ตรงเข้า inventory ฝั่ง server ปลอดภัยกว่า |
| `ItemDropped` remote direction | Server → Client FireClient เท่านั้น (ไม่มี OnServerEvent) |
| QuestConfig `stone_fragment` | ควรแก้เป็น `StoneFragment` ให้ตรงกัน (capital S F) หรือทำ alias ใน QuestConfig |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-drop.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ReplicatedStorage/Modules/NpcDropConfig.luau \
  src/ServerScriptService/Combat/NpcDropService.luau \
  src/ServerScriptService/Combat/CombatService.luau \
  src/StarterPlayer/StarterPlayerScripts/DropNotifClient.client.luau
```

## ทดสอบใน Studio (Server console)

```lua
-- ทดสอบ drop rolls สำหรับ NPC 5 (Boss)
local DS = require(game.ServerScriptService.Combat.NpcDropService)
local rolls = DS.rollDrops(5)
for _, r in rolls do
  print(r.itemId, r.qty)
end

-- ทดสอบ grantDrops จริง
local p = game.Players:GetPlayers()[1]
DS.grantDrops(p, 2)   -- zombie soldier
-- ดู PlayerItemStore inventory หลัง drop
local IS = require(game.ServerScriptService.Progression.PlayerItemStore)
print(IS.getInventory(p.UserId))
```

## Git commit (ถ้า clean)

```bash
git add -A
git commit -m "feat(Combat): NPC Item Drop System

- NpcDropConfig: 5 NPC profiles + fallback, drop table with chance/qty range
- NpcDropService: rollDrops(), grantDrops() → PlayerItemStore, getBaseXP()
- CombatService: replace grantKillExp → grantKillRewards(player, npcId)
  uses NpcDropConfig.baseXP, fires drops + quest hook
- DropNotifClient: stack notif mุมขวาล่าง, fade-out 3s, icon+color per item
- SocialRemoteSetup: +ItemDropped RemoteEvent"
```

## รายงานกลับ

- ✅/❌ BUILD · ✅/❌ STRICT CLEAN (error+line) · commit hash
- drop rolls ของ NPC 5 (Boss): ได้ items อะไรบ้าง
- inventory หลัง grantDrops
