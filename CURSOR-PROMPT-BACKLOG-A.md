# CURSOR PROMPT — Backlog A: Event Banner HUD + Camera Persist + PvP Zone Gate
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก commit `79e499e` (P8 Live-ops done)
> **3 fixes รวม 1 commit**

---

## Fix 1: Event Banner HUD (client)

**บริบท:** `ActiveEventsUpdate` RemoteEvent พร้อมแล้วใน SocialRemotes — ยังไม่มี UI รับ

**สร้างไฟล์:** `src/StarterPlayer/StarterPlayerScripts/EventBannerClient.client.luau`

```lua
--!strict
-- StarterPlayerScripts/EventBannerClient.client.luau

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local remotes           = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local activeEventsUpdate= remotes:WaitForChild("ActiveEventsUpdate") :: RemoteEvent

type BuffEntry = { buffType: string, value: number, eventName: string }

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "EventBannerHUD"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = game:GetService("Players").LocalPlayer.PlayerGui

-- ============ Banner (slide in/out จากด้านบน) ============
local banner = Instance.new("Frame")
banner.Name                  = "EventBanner"
banner.Size                  = UDim2.fromScale(0.5, 0.07)
banner.Position              = UDim2.fromScale(0.25, -0.08)   -- ซ่อนนอกจอ
banner.BackgroundColor3      = Color3.fromRGB(30, 30, 50)
banner.BackgroundTransparency= 0.1
banner.BorderSizePixel       = 0
banner.Parent                = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent       = banner

local bannerText = Instance.new("TextLabel")
bannerText.Size                  = UDim2.fromScale(0.7, 1)
bannerText.Position              = UDim2.fromScale(0.02, 0)
bannerText.BackgroundTransparency= 1
bannerText.TextColor3            = Color3.new(1, 1, 1)
bannerText.TextScaled            = true
bannerText.TextXAlignment        = Enum.TextXAlignment.Left
bannerText.Font                  = Enum.Font.GothamBold
bannerText.Text                  = ""
bannerText.Parent                = banner

local multLabel = Instance.new("TextLabel")
multLabel.Size                  = UDim2.fromScale(0.26, 1)
multLabel.Position              = UDim2.fromScale(0.72, 0)
multLabel.BackgroundTransparency= 1
multLabel.TextColor3            = Color3.fromRGB(255, 240, 100)
multLabel.TextScaled            = true
multLabel.TextXAlignment        = Enum.TextXAlignment.Right
multLabel.Font                  = Enum.Font.GothamBold
multLabel.Text                  = ""
multLabel.Parent                = banner

-- ============ Active buff chips (ด้านล่าง banner) ============
local chipContainer = Instance.new("Frame")
chipContainer.Name                  = "ChipContainer"
chipContainer.Size                  = UDim2.fromScale(0.5, 0.04)
chipContainer.Position              = UDim2.fromScale(0.25, 0.07)
chipContainer.BackgroundTransparency= 1
chipContainer.Parent                = screenGui

local chipLayout = Instance.new("UIListLayout")
chipLayout.FillDirection = Enum.FillDirection.Horizontal
chipLayout.Padding       = UDim.new(0, 6)
chipLayout.Parent        = chipContainer

local function clearChips()
  for _, c in chipContainer:GetChildren() do
    if c:IsA("TextLabel") then c:Destroy() end
  end
end

local function addChip(text: string, color: Color3)
  local chip = Instance.new("TextLabel")
  chip.Size                  = UDim2.new(0, 0, 1, 0)
  chip.AutomaticSize         = Enum.AutomaticSize.X
  chip.BackgroundColor3      = color
  chip.BackgroundTransparency= 0.2
  chip.TextColor3            = Color3.new(1, 1, 1)
  chip.TextScaled            = false
  chip.TextSize              = 14
  chip.Font                  = Enum.Font.Gotham
  chip.Text                  = " " .. text .. " "
  chip.Parent                = chipContainer
  local cc = Instance.new("UICorner")
  cc.CornerRadius = UDim.new(0, 6)
  cc.Parent       = chip
end

local buffColors: { [string]: Color3 } = {
  DoubleExp      = Color3.fromRGB(80, 200, 120),
  DoubleDrop     = Color3.fromRGB(80, 160, 255),
  DoubleCurrency = Color3.fromRGB(255, 200, 50),
}

local function showBannerSlide(text: string, mult: string, slideIn: boolean)
  local targetY = slideIn and 0.01 or -0.08
  TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Quart), {
    Position = UDim2.fromScale(0.25, targetY)
  }):Play()
  if slideIn then
    bannerText.Text = text
    multLabel.Text  = mult
  end
end

activeEventsUpdate:Connect(function(buffs)
  clearChips()
  local buffList = buffs :: { BuffEntry }

  if #buffList == 0 then
    showBannerSlide("", "", false)
    chipContainer.Visible = false
    return
  end

  chipContainer.Visible = true

  -- สร้าง banner text จาก event แรก (สำคัญสุด)
  local first = buffList[1]
  local buffTypeLabel = first.buffType:gsub("Double", "×" .. first.value .. " ")
  showBannerSlide("🎉 " .. first.eventName, buffTypeLabel, true)

  -- ซ่อนหลัง 8 วินาที แต่ chips ยังอยู่
  task.delay(8, function()
    showBannerSlide("", "", false)
  end)

  -- สร้าง chips ทุก buff ที่ active
  for _, b in buffList do
    local label = b.eventName .. " " .. b.buffType:gsub("Double", "×" .. b.value .. " ")
    addChip(label, buffColors[b.buffType] or Color3.fromRGB(120, 120, 180))
  end
end)
```

**เพิ่มใน default.project.json (StarterPlayerScripts):**
```json
"EventBannerClient": { "$path": "src/StarterPlayer/StarterPlayerScripts/EventBannerClient.client.luau" }
```

---

## Fix 2: Camera Mode Persist ข้าม Session (DataStore)

**บริบท:** `CameraModeController` เก็บ mode ใน Player Attribute เท่านั้น — reset เมื่อ rejoin

**แก้ไฟล์:** `src/StarterPlayer/StarterPlayerScripts/CameraModeController.client.luau`

เพิ่ม require + save/load:
```lua
-- เพิ่มที่ top (หลัง local player = ...)
local remotes         = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local saveCameraRF    = remotes:WaitForChild("SaveCameraMode")   :: RemoteFunction
local loadCameraRF    = remotes:WaitForChild("LoadCameraMode")   :: RemoteFunction
```

แก้ `switchMode()` — เพิ่ม save หลัง SetAttribute:
```lua
player:SetAttribute("CameraMode", mode)
-- save to DataStore (fire-and-forget)
task.spawn(function()
  pcall(function() saveCameraRF:InvokeServer(mode) end)
end)
```

แก้ `CharacterAdded` handler — load จาก server ก่อน:
```lua
player.CharacterAdded:Connect(function()
  task.wait(0.2)
  -- โหลด preference จาก DataStore
  local ok, savedMode = pcall(function()
    return loadCameraRF:InvokeServer()
  end)
  local mode: CameraMode = (ok and savedMode) and savedMode :: CameraMode or "ThirdPerson"
  for i, m in MODES do
    if m == mode then switchMode(i); break end
  end
  camBtn.Text = modeLabels[MODES[currentModeIndex]]
end)
```

**สร้างไฟล์:** `src/ServerScriptService/Progression/CameraPreferenceService.luau`

```lua
--!strict
-- ServerScriptService/Progression/CameraPreferenceService.luau

local DataStoreService = game:GetService("DataStoreService")
local ds = DataStoreService:GetDataStore("UtopiaCamera_v1")

local CameraPreferenceService = {}

function CameraPreferenceService.save(userId: number, mode: string)
  local ok, err = pcall(function()
    ds:SetAsync("cam_" .. userId, mode)
  end)
  if not ok then warn("[CameraPrefs] save failed:", err) end
end

function CameraPreferenceService.load(userId: number): string
  local ok, result = pcall(function()
    return ds:GetAsync("cam_" .. userId)
  end)
  return (ok and result) and result :: string or "ThirdPerson"
end

return CameraPreferenceService
```

**สร้างไฟล์:** `src/ServerScriptService/Progression/CameraPreferenceHandlers.server.luau`

```lua
--!strict
local ReplicatedStorage        = game:GetService("ReplicatedStorage")
local CameraPreferenceService  = require(script.Parent.CameraPreferenceService)

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local function ensure(cls: string, name: string): Instance
  local e = remotes:FindFirstChild(name)
  if e then return e end
  local i = Instance.new(cls); i.Name = name; i.Parent = remotes; return i
end

local saveRF = ensure("RemoteFunction", "SaveCameraMode") :: RemoteFunction
local loadRF = ensure("RemoteFunction", "LoadCameraMode") :: RemoteFunction

saveRF.OnServerInvoke = function(player, mode)
  CameraPreferenceService.save(player.UserId, mode :: string)
  return true
end

loadRF.OnServerInvoke = function(player)
  return CameraPreferenceService.load(player.UserId)
end
```

**เพิ่มใน default.project.json (Progression/):**
```json
"CameraPreferenceService": { "$path": "src/ServerScriptService/Progression/CameraPreferenceService.luau" },
"CameraPreferenceHandlers": { "$path": "src/ServerScriptService/Progression/CameraPreferenceHandlers.server.luau" }
```

---

## Fix 3: PvP Zone Gate (Eternal Colosseum only)

**บริบท:** `CombatService.processPlayerAttack()` มี `-- TODO: PvP zone check` — ต้องตรวจว่าทั้ง attacker และ target อยู่ใน Eternal Colosseum zone

**แก้ไฟล์:** `src/ServerScriptService/Combat/CombatService.luau`

เพิ่มที่ top:
```lua
-- PvP zone config: ชื่อ Model/Folder ใน Workspace ที่เป็น Colosseum zone
local PVP_ZONE_NAME = "EternalColosseum"

local function isInPvpZone(character: Model): boolean
  local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
  if not hrp then return false end
  -- ตรวจว่า HRP อยู่ภายใน bounding box ของ EternalColosseum model
  local zone = workspace:FindFirstChild(PVP_ZONE_NAME) :: Model?
  if not zone then return false end
  local primary = zone:FindFirstChildOfClass("Part") or
                  zone:FindFirstChildOfClass("MeshPart")
  if not primary then return false end
  -- ใช้ Region3 check แบบง่าย (ปรับเป็น WorldRoot:GetPartBoundsInBox ถ้าต้องการแม่น)
  local pos  = hrp.Position
  local cf   = primary.CFrame
  local size = primary.Size * 0.5
  local local_ = cf:PointToObjectSpace(pos)
  return math.abs(local_.X) <= size.X
     and math.abs(local_.Y) <= size.Y + 20  -- +20 สำหรับความสูงตัวละคร
     and math.abs(local_.Z) <= size.Z
end
```

แทนที่ `-- TODO: PvP zone check` ใน `processPlayerAttack()` ด้วย:
```lua
-- PvP zone gate: ทั้ง attacker และ target ต้องอยู่ใน EternalColosseum
local attackerChar = attacker.Character
local targetChar   = target.Character
if not attackerChar or not targetChar then return false end
if not isInPvpZone(attackerChar) or not isInPvpZone(targetChar) then
  return false  -- silent reject — ไม่ใช่ zone PvP
end
-- ผ่าน zone check → apply damage ต่อ
```

**หมายเหตุ Cursor:** ถ้า `EternalColosseum` ยังไม่มีใน Workspace → zone check จะ return false เสมอ (ปลอดภัย — PvP disabled จนกว่าจะวาง model จริงใน Studio)

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-backlog-a.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/StarterPlayer/StarterPlayerScripts/EventBannerClient.client.luau \
  src/ServerScriptService/Progression/CameraPreferenceService.luau \
  src/ServerScriptService/Progression/CameraPreferenceHandlers.server.luau \
  src/StarterPlayer/StarterPlayerScripts/CameraModeController.client.luau \
  src/ServerScriptService/Combat/CombatService.luau
```

## Git commit (ถ้า clean)

```bash
git add -A
git commit -m "fix(backlog-A): Event banner HUD + camera persist + PvP zone gate

- EventBannerClient: slide-in banner + buff chips (ActiveEventsUpdate)
- CameraPreferenceService: DataStore save/load per player
- CameraPreferenceHandlers: SaveCameraMode/LoadCameraMode RF
- CameraModeController: persist on switch + load on CharacterAdded
- CombatService: isInPvpZone() check — PvP only in EternalColosseum model"
```

## รายงานกลับ
- ✅/❌ BUILD · ✅/❌ STRICT CLEAN (error+line) · commit hash
