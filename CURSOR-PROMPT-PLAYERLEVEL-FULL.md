# CURSOR PROMPT — PlayerLevelService Full Implementation
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก Backlog-B (01a376b)
> อ้างอิง: `docs/MASTER-BLUEPRINT.md` §4 Progression · PlayerTierConfig tiers 1-7 (Lv1-149)

---

## บริบท / ปัญหาเดิม

`PlayerLevelService` เป็น **stub** — level อยู่แค่ใน `Player:SetAttribute` ไม่มี DataStore
`CombatService.grantKillExp` ใช้ `CombatExpAccum` attribute แทน XP จริง (รีเซ็ตเมื่อ rejoin)

งานนี้: เปลี่ยนเป็น **DataStore-backed XP + Level** แบบเต็ม + XP bar client

---

## ไฟล์ที่ต้องสร้าง/แก้

| ไฟล์ | Action | Path |
|------|--------|------|
| `LevelStore.luau` | สร้างใหม่ | `ServerScriptService/Progression/` |
| `PlayerLevelService.luau` | แก้ (replace) | `ServerScriptService/Progression/` |
| `CombatService.luau` | แก้ `grantKillExp` เท่านั้น | `ServerScriptService/Combat/` |
| `LevelHUDClient.client.luau` | สร้างใหม่ | `StarterPlayerScripts/` |

---

## 1. LevelStore.luau (ใหม่)

```lua
--!strict
-- ServerScriptService/Progression/LevelStore.luau

local DataStoreService = game:GetService("DataStoreService")
local ds = DataStoreService:GetDataStore("UtopiaLevel_v1")

export type LevelData = {
  level : number,
  xp    : number,   -- XP สะสมในเลเวลปัจจุบัน
}

local function default(): LevelData
  return { level = 1, xp = 0 }
end

local LevelStore = {}

function LevelStore.get(userId: number): LevelData
  local ok, result = pcall(function()
    return ds:GetAsync("lv_" .. userId)
  end)
  if ok and result then
    return result :: LevelData
  end
  return default()
end

function LevelStore.save(userId: number, data: LevelData)
  local ok, err = pcall(function()
    ds:SetAsync("lv_" .. userId, data)
  end)
  if not ok then
    warn("[LevelStore] save failed:", err)
  end
end

return LevelStore
```

---

## 2. PlayerLevelService.luau (replace ทั้งหมด)

```lua
--!strict
--[[
  PlayerLevelService (Full) — DataStore XP + Level + Tier broadcast
  XP required to level: expNeeded(lv) = lv * 100 + lv^2 * 5
  Max level: 149 (Hero tier cap ใน PlayerTierConfig)
]]
local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerTierConfig  = require(ReplicatedStorage.Modules.PlayerTierConfig)
local VisiblePowerService= require(script.Parent.VisiblePowerService)
local LevelStore        = require(script.Parent.LevelStore)

-- In-memory cache: userId → LevelData
local cache: { [number]: LevelStore.LevelData } = {}

local MAX_LEVEL = 149

-- XP ที่ต้องการเพื่อ level ขึ้น (จากเลเวล lv ไป lv+1)
local function expNeeded(lv: number): number
  return lv * 100 + lv * lv * 5
end

local function applyData(player: Player, data: LevelStore.LevelData)
  cache[player.UserId] = data
  player:SetAttribute("PlayerLevel", data.level)
  player:SetAttribute("PlayerXP",    data.xp)
  player:SetAttribute("PlayerXPMax", expNeeded(data.level))
  local tier = PlayerTierConfig.getTierForLevel(data.level)
  player:SetAttribute("PlayerTier", tier.tier)
  VisiblePowerService.onLevelChanged(player, data.level)
end

local PlayerLevelService = {}

function PlayerLevelService.getLevel(player: Player): number
  local d = cache[player.UserId]
  return if d then d.level else 1
end

function PlayerLevelService.getXP(player: Player): number
  local d = cache[player.UserId]
  return if d then d.xp else 0
end

-- เพิ่ม XP (ใช้จาก CombatService / quest / event)
function PlayerLevelService.addExp(player: Player, amount: number)
  if amount <= 0 then return end
  local data = cache[player.UserId]
  if not data then return end

  data.xp += amount
  local leveledUp = false

  while data.level < MAX_LEVEL do
    local needed = expNeeded(data.level)
    if data.xp >= needed then
      data.xp -= needed
      data.level += 1
      leveledUp = true
    else
      break
    end
  end

  -- ปิด XP ที่ max level
  if data.level >= MAX_LEVEL then
    data.xp = 0
  end

  applyData(player, data)

  -- แจ้ง client level up
  if leveledUp then
    local ev = game:GetService("ReplicatedStorage"):FindFirstChild("SocialRemotes")
      and game:GetService("ReplicatedStorage").SocialRemotes:FindFirstChild("LevelUp") :: RemoteEvent?
    if ev then ev:FireClient(player, data.level) end
  end

  -- บันทึก DataStore แบบ deferred (ไม่รอ)
  task.spawn(function()
    LevelStore.save(player.UserId, data)
  end)
end

-- legacy compat (ใช้ใน test console: PLS.addLevel(player, 1))
function PlayerLevelService.addLevel(player: Player, delta: number)
  local data = cache[player.UserId]
  if not data then return end
  local newLv = math.clamp(data.level + math.floor(delta), 1, MAX_LEVEL)
  data.level = newLv
  data.xp = 0
  applyData(player, data)
  task.spawn(function()
    LevelStore.save(player.UserId, data)
  end)
end

function PlayerLevelService.setLevel(player: Player, newLevel: number)
  PlayerLevelService.addLevel(player, newLevel - PlayerLevelService.getLevel(player))
end

-- คืน multiplier รวม (pet + event calendar)
function PlayerLevelService.getExpGainMultiplier(player: Player): number
  local mult = 1.0

  local petBonus = player:GetAttribute("PetExpBonus")
  if typeof(petBonus) == "number" and petBonus > 0 then
    mult += petBonus
  end

  local ok, ecs = pcall(function()
    return require(ServerScriptService.LiveOps.EventCalendarService)
  end)
  if ok and ecs then
    mult *= (ecs :: any).getMultiplier("DoubleExp")
  end

  return mult
end

function PlayerLevelService.init(remotesFolder: Folder)
  VisiblePowerService.init(remotesFolder)

  -- สร้าง LevelUp remote (ถ้ายังไม่มี)
  if not remotesFolder:FindFirstChild("LevelUp") then
    local ev = Instance.new("RemoteEvent")
    ev.Name   = "LevelUp"
    ev.Parent = remotesFolder
  end
end

function PlayerLevelService.onPlayerReady(player: Player)
  local data = LevelStore.get(player.UserId)
  applyData(player, data)
end

Players.PlayerAdded:Connect(function(player)
  PlayerLevelService.onPlayerReady(player)
  player.CharacterAdded:Connect(function()
    task.wait(0.5)
    local data = cache[player.UserId]
    if data then
      VisiblePowerService.onLevelChanged(player, data.level)
    end
  end)
end)

Players.PlayerRemoving:Connect(function(player)
  local data = cache[player.UserId]
  if data then
    LevelStore.save(player.UserId, data)
  end
  cache[player.UserId] = nil
end)

return PlayerLevelService
```

---

## 3. CombatService.luau — แก้เฉพาะ `grantKillExp`

ค้นหาฟังก์ชัน `grantKillExp` (ประมาณบรรทัด 132–154) แล้ว **replace ทั้งฟังก์ชัน** ด้วย:

```lua
local function grantKillExp(player: Player)
  local okPls, pls = pcall(function()
    return require(ServerScriptService:WaitForChild("Progression"):WaitForChild("PlayerLevelService"))
  end)
  if not okPls or not pls then return end

  local BASE_KILL_EXP = 25   -- XP ต่อ kill ก่อนคูณ multiplier
  local mult = (pls :: any).getExpGainMultiplier(player)
  local xpGain = math.floor(BASE_KILL_EXP * mult + 0.5);
  (pls :: any).addExp(player, xpGain)
end
```

> **ลบ** `CombatExpAccum` attribute logic ทิ้งด้วย (streak/while loop)

---

## 4. LevelHUDClient.client.luau (ใหม่)

```lua
--!strict
-- StarterPlayerScripts/LevelHUDClient.client.luau

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local remotes     = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local levelUpEv   = remotes:WaitForChild("LevelUp") :: RemoteEvent

-- ============ HUD (top-left) ============
local screenGui = Instance.new("ScreenGui")
screenGui.Name         = "LevelHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent       = localPlayer.PlayerGui

-- level badge
local badge = Instance.new("Frame")
badge.Size              = UDim2.fromScale(0.09, 0.05)
badge.Position          = UDim2.fromScale(0.01, 0.01)
badge.BackgroundColor3  = Color3.fromRGB(30, 30, 50)
badge.BorderSizePixel   = 0
badge.Parent            = screenGui
Instance.new("UICorner", badge).CornerRadius = UDim.new(0.2, 0)

local levelLabel = Instance.new("TextLabel")
levelLabel.Size              = UDim2.fromScale(1, 0.45)
levelLabel.Position          = UDim2.fromScale(0, 0)
levelLabel.BackgroundTransparency = 1
levelLabel.TextColor3        = Color3.fromRGB(255, 220, 100)
levelLabel.TextScaled        = true
levelLabel.Text              = "Lv 1"
levelLabel.Font              = Enum.Font.GothamBold
levelLabel.Parent            = badge

-- XP bar background
local xpBg = Instance.new("Frame")
xpBg.Size             = UDim2.fromScale(1, 0.25)
xpBg.Position         = UDim2.fromScale(0, 0.65)
xpBg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
xpBg.BorderSizePixel  = 0
xpBg.Parent           = badge

-- XP fill
local xpFill = Instance.new("Frame")
xpFill.Size            = UDim2.fromScale(0, 1)
xpFill.BackgroundColor3= Color3.fromRGB(80, 200, 120)
xpFill.BorderSizePixel = 0
xpFill.Parent          = xpBg

-- XP text (hover label บน xpBg)
local xpLabel = Instance.new("TextLabel")
xpLabel.Size              = UDim2.fromScale(1, 0.28)
xpLabel.Position          = UDim2.fromScale(0, 0.37)
xpLabel.BackgroundTransparency = 1
xpLabel.TextColor3        = Color3.fromRGB(200, 200, 200)
xpLabel.TextScaled        = true
xpLabel.Text              = "0 / 105 XP"
xpLabel.Font              = Enum.Font.Gotham
xpLabel.Parent            = badge

-- Level-up flash banner
local flashBanner = Instance.new("TextLabel")
flashBanner.Size              = UDim2.fromScale(0.4, 0.08)
flashBanner.Position          = UDim2.fromScale(0.3, -0.1)
flashBanner.BackgroundColor3  = Color3.fromRGB(255, 220, 60)
flashBanner.BackgroundTransparency = 0.1
flashBanner.TextColor3        = Color3.fromRGB(20, 20, 20)
flashBanner.TextScaled        = true
flashBanner.Font              = Enum.Font.GothamBold
flashBanner.Text              = "⬆ LEVEL UP!"
flashBanner.Visible           = false
flashBanner.ZIndex            = 10
flashBanner.Parent            = screenGui
Instance.new("UICorner", flashBanner).CornerRadius = UDim.new(0.15, 0)

local function showFlash(newLevel: number)
  flashBanner.Text    = string.format("⬆ LEVEL %d!", newLevel)
  flashBanner.Visible = true
  local tweenIn = TweenService:Create(flashBanner,
    TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    { Position = UDim2.fromScale(0.3, 0.08) })
  tweenIn:Play()
  tweenIn.Completed:Wait()
  task.wait(2)
  local tweenOut = TweenService:Create(flashBanner,
    TweenInfo.new(0.3),
    { Position = UDim2.fromScale(0.3, -0.1) })
  tweenOut:Play()
  tweenOut.Completed:Wait()
  flashBanner.Visible = false
end

-- อัปเดต HUD จาก attributes
local function updateHUD()
  local lv     = localPlayer:GetAttribute("PlayerLevel")
  local xp     = localPlayer:GetAttribute("PlayerXP")
  local xpMax  = localPlayer:GetAttribute("PlayerXPMax")

  lv    = if typeof(lv)    == "number" then lv    else 1
  xp    = if typeof(xp)    == "number" then xp    else 0
  xpMax = if typeof(xpMax) == "number" and xpMax > 0 then xpMax else 100

  levelLabel.Text = "Lv " .. lv
  xpLabel.Text    = xp .. " / " .. xpMax .. " XP"

  local ratio = math.clamp(xp / xpMax, 0, 1)
  TweenService:Create(xpFill,
    TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    { Size = UDim2.fromScale(ratio, 1) }):Play()
end

-- ฟัง attribute changes
localPlayer:GetAttributeChangedSignal("PlayerXP"):Connect(updateHUD)
localPlayer:GetAttributeChangedSignal("PlayerLevel"):Connect(updateHUD)

-- ฟัง LevelUp event จาก server
levelUpEv:Connect(function(newLevel)
  task.spawn(showFlash, newLevel :: number)
end)

-- init
task.wait(1)
updateHUD()
```

---

## 5. default.project.json — เพิ่ม entries

```json
"LevelStore":      { "$path": "src/ServerScriptService/Progression/LevelStore.luau" },
"LevelHUDClient":  { "$path": "src/StarterPlayer/StarterPlayerScripts/LevelHUDClient.client.luau" }
```

(PlayerLevelService เดิมมีอยู่แล้ว — เปลี่ยนแค่ไฟล์)

---

## สิ่งที่รู้ล่วงหน้า

| ประเด็น | รายละเอียด |
|---------|-----------|
| `expNeeded(lv) = lv*100 + lv²*5` | L1→2=105, L10→11=1500, L50→51=17500, L99→100=59000 |
| BASE_KILL_EXP = 25 | pet +5-15% + event ×2 สูงสุด = 57 XP/kill; ~1850 kills to L100 |
| DataStore save async | `task.spawn` ใน addExp() ป้องกัน throttle; on PlayerRemoving save sync |
| `CombatExpAccum` attribute | ลบทิ้ง — ไม่ใช้แล้ว |
| PlayerLevelService.addLevel() | ยังอยู่ (backward compat สำหรับ test console) |
| LevelUp remote | สร้างใน `SocialRemotes` เหมือนกับ remote อื่น |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-playerlevel.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ServerScriptService/Progression/LevelStore.luau \
  src/ServerScriptService/Progression/PlayerLevelService.luau \
  src/ServerScriptService/Combat/CombatService.luau \
  src/StarterPlayer/StarterPlayerScripts/LevelHUDClient.client.luau
```

## ทดสอบใน Studio (Server console)

```lua
-- ให้ XP 200 ดู level up (Lv1→2 ต้องการ 105 XP)
local PLS = require(game.ServerScriptService.Progression.PlayerLevelService)
local p = game.Players:GetPlayers()[1]
PLS.addExp(p, 200)
print(PLS.getLevel(p), PLS.getXP(p))  -- ควรได้ Lv 2, XP เหลือ 95
```

## Git commit (ถ้า clean)

```bash
git add -A
git commit -m "feat(Progression): PlayerLevelService full DataStore XP system

- LevelStore: DataStore UtopiaLevel_v1, get/save with pcall
- PlayerLevelService: addExp() real XP table (lv*100+lv²*5), level-up loop,
  DataStore persist, LevelUp RemoteEvent, backward-compat addLevel()
- CombatService: replace CombatExpAccum hack → addExp(player, 25*mult)
- LevelHUDClient: XP bar + level badge + level-up flash banner"
```

## รายงานกลับ

- ✅/❌ BUILD · ✅/❌ STRICT CLEAN (error+line) · commit hash
- XP ที่ได้ต่อ kill (Studio test) · level up ทำงานหรือไม่
