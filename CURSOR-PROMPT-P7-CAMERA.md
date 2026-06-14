# CURSOR PROMPT — P7 Camera/UX + Visible Power
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก commit `94ac45e` (P6 Integration done)
> อ้างอิง: `docs/MASTER-BLUEPRINT.md` §6 Roadmap P7 + `docs/BLUEPRINT-V2-WORLD-PROGRESSION.md` §B

---

## บริบท

- `PlayerTierConfig.luau` ยังไม่มี → ต้องสร้างใหม่ (tier 1–7 ตาม level band)
- กล้อง 3 มุมเป็นความต้องการหลักของ Praphan (ยืนยันแล้วใน §G ว่า 1st/3rd/TopDown)
- Visible power = aura/glow แสดงตาม Player Tier — ทำให้ผู้เล่นระดับสูงโดดเด่นเห็นได้ชัด

---

## ไฟล์ที่ต้องสร้าง

| ไฟล์ | บทบาท | Path |
|------|------|------|
| `PlayerTierConfig.luau` | level bands → tier name/color/aura | `ReplicatedStorage/Modules/` |
| `CameraModeController.client.luau` | สลับ 3 มุมกล้อง + save preference | `StarterPlayerScripts/` |
| `VisiblePowerService.luau` | ฟัง tier change → apply aura/glow บน server | `ServerScriptService/Progression/` |
| `VisiblePowerClient.client.luau` | รับ TierChanged event → apply Highlight + particle ฝั่ง client | `StarterPlayerScripts/` |

---

## 1. PlayerTierConfig.luau

```lua
--!strict
-- ReplicatedStorage/Modules/PlayerTierConfig.luau

export type TierInfo = {
  tier       : number,
  name       : string,
  nameTH     : string,
  minLevel   : number,
  maxLevel   : number,
  color      : Color3,        -- สีฉายา/UI
  auraColor  : Color3,        -- สีออร่า
  auraEnabled: boolean,       -- tier 1–3 ไม่มีออร่า
  glowIntensity: number,      -- 0 = ไม่เรือง, 1–5
}

local tiers: { TierInfo } = {
  { tier=1, name="Newbie",     nameTH="ผู้เล่นใหม่",   minLevel=1,   maxLevel=15,
    color=Color3.fromRGB(180,180,180), auraColor=Color3.new(1,1,1),   auraEnabled=false, glowIntensity=0 },
  { tier=2, name="Apprentice", nameTH="ผู้ฝึกหัด",     minLevel=16,  maxLevel=25,
    color=Color3.fromRGB(100,220,100), auraColor=Color3.new(1,1,1),   auraEnabled=false, glowIntensity=0 },
  { tier=3, name="Adept",      nameTH="ชำนาญการ",       minLevel=26,  maxLevel=40,
    color=Color3.fromRGB(80,180,255),  auraColor=Color3.fromRGB(80,200,255),  auraEnabled=false, glowIntensity=0 },
  { tier=4, name="Veteran",    nameTH="ผู้เจนสนาม",     minLevel=41,  maxLevel=60,
    color=Color3.fromRGB(255,200,50),  auraColor=Color3.fromRGB(255,220,80),  auraEnabled=true,  glowIntensity=1 },
  { tier=5, name="Expert",     nameTH="ผู้เชี่ยวชาญ",   minLevel=61,  maxLevel=80,
    color=Color3.fromRGB(255,120,0),   auraColor=Color3.fromRGB(255,140,30),  auraEnabled=true,  glowIntensity=2 },
  { tier=6, name="Master",     nameTH="ปรมาจารย์",       minLevel=81,  maxLevel=99,
    color=Color3.fromRGB(200,80,255),  auraColor=Color3.fromRGB(200,100,255), auraEnabled=true,  glowIntensity=3 },
  { tier=7, name="Hero",       nameTH="วีรบุรุษ",        minLevel=100, maxLevel=149,
    color=Color3.fromRGB(255,220,0),   auraColor=Color3.fromRGB(255,240,100), auraEnabled=true,  glowIntensity=5 },
}

local PlayerTierConfig = {}

function PlayerTierConfig.getTierForLevel(level: number): TierInfo
  for i = #tiers, 1, -1 do
    if level >= tiers[i].minLevel then
      return tiers[i]
    end
  end
  return tiers[1]
end

function PlayerTierConfig.getAll(): { TierInfo }
  return tiers
end

return PlayerTierConfig
```

---

## 2. CameraModeController.client.luau

```lua
--!strict
-- StarterPlayerScripts/CameraModeController.client.luau

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local DataStoreService  = game:GetService("DataStoreService")

-- ไม่สามารถเข้า DataStore จาก client → ใช้ RemoteFunction SaveCameraMode แทน
-- (ง่ายกว่า: เก็บใน LocalPlayer Attribute แทนการ persist)

local player  = Players.LocalPlayer
local camera  = workspace.CurrentCamera

type CameraMode = "FirstPerson" | "ThirdPerson" | "TopDown"
local MODES: { CameraMode } = { "FirstPerson", "ThirdPerson", "TopDown" }
local currentModeIndex = 2  -- default = ThirdPerson

-- TopDown config
local TOP_DOWN_HEIGHT  = 60   -- studs เหนือตัวละคร
local TOP_DOWN_ANGLE   = -75  -- องศา (มองลงเกือบตั้งฉาก)

local function applyMode(mode: CameraMode)
  local char = player.Character
  if not char then return end
  local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
  if not hrp then return end

  if mode == "FirstPerson" then
    player.CameraMode = Enum.CameraMode.LockFirstPerson
    camera.CameraType = Enum.CameraType.Custom

  elseif mode == "ThirdPerson" then
    player.CameraMode = Enum.CameraMode.Classic
    camera.CameraType = Enum.CameraType.Custom

  elseif mode == "TopDown" then
    player.CameraMode = Enum.CameraMode.Classic
    camera.CameraType = Enum.CameraType.Scriptable
    -- กล้องจะ update ต่อเนื่องใน RenderStep
  end
end

-- RenderStep สำหรับ TopDown
local topDownConn: RBXScriptConnection?
local function startTopDown()
  if topDownConn then topDownConn:Disconnect() end
  topDownConn = RunService.RenderStepped:Connect(function()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return end
    local target = hrp.Position + Vector3.new(0, TOP_DOWN_HEIGHT, 0)
    camera.CFrame = CFrame.new(target, hrp.Position)
  end)
end

local function stopTopDown()
  if topDownConn then
    topDownConn:Disconnect()
    topDownConn = nil
  end
end

local function switchMode(newIndex: number)
  currentModeIndex = ((newIndex - 1) % #MODES) + 1
  local mode = MODES[currentModeIndex]

  if mode == "TopDown" then
    startTopDown()
  else
    stopTopDown()
  end
  applyMode(mode)

  -- บันทึก preference ใน Attribute (persist ข้าม respawn ภายใน session)
  player:SetAttribute("CameraMode", mode)
end

-- ปุ่มสลับกล้อง: C หรือปุ่ม UI
UserInputService.InputBegan:Connect(function(input, gpe)
  if gpe then return end
  if input.KeyCode == Enum.KeyCode.C then
    switchMode(currentModeIndex + 1)
  end
end)

-- สร้างปุ่ม UI (Scale-based, top-right)
local screenGui = Instance.new("ScreenGui")
screenGui.Name          = "CameraHUD"
screenGui.ResetOnSpawn  = false
screenGui.ZIndexBehavior= Enum.ZIndexBehavior.Sibling
screenGui.Parent        = player.PlayerGui

local camBtn = Instance.new("TextButton")
camBtn.Size     = UDim2.fromScale(0.08, 0.05)
camBtn.Position = UDim2.fromScale(0.91, 0.01)
camBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
camBtn.BackgroundTransparency = 0.2
camBtn.TextColor3 = Color3.new(1,1,1)
camBtn.TextScaled = true
camBtn.Text = "📷 3rd"
camBtn.Parent = screenGui

local modeLabels: { [CameraMode]: string } = {
  FirstPerson = "📷 1st",
  ThirdPerson = "📷 3rd",
  TopDown     = "📷 Top",
}

camBtn.MouseButton1Click:Connect(function()
  switchMode(currentModeIndex + 1)
  camBtn.Text = modeLabels[MODES[currentModeIndex]]
end)

-- ตั้งค่าเริ่มต้น
player.CharacterAdded:Connect(function()
  task.wait(0.1)  -- รอ character load
  local saved = player:GetAttribute("CameraMode") :: CameraMode?
  if saved then
    for i, m in MODES do
      if m == saved then switchMode(i); break end
    end
  else
    switchMode(currentModeIndex)
  end
  camBtn.Text = modeLabels[MODES[currentModeIndex]]
end)
```

---

## 3. VisiblePowerService.luau

```lua
--!strict
-- ServerScriptService/Progression/VisiblePowerService.luau
-- เมื่อ player level เปลี่ยน → แจ้ง client เพื่อ update aura/glow

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerTierConfig  = require(ReplicatedStorage.Modules.PlayerTierConfig)

local VisiblePowerService = {}
local remotes: Folder

-- เรียกจาก PlayerLevelService เมื่อ level เปลี่ยน
function VisiblePowerService.onLevelChanged(player: Player, newLevel: number)
  local tier = PlayerTierConfig.getTierForLevel(newLevel)
  -- แจ้ง client คนนั้น
  local tierChanged = remotes:FindFirstChild("TierChanged") :: RemoteEvent?
  if tierChanged then
    tierChanged:FireClient(player, tier.tier, tier.auraEnabled, tier.auraColor, tier.glowIntensity)
  end
  -- แจ้ง client อื่นในเซิร์ฟเวอร์เดียวกัน (ให้เห็นออร่าของคนอื่น)
  local tierChangedOther = remotes:FindFirstChild("PlayerTierBroadcast") :: RemoteEvent?
  if tierChangedOther then
    tierChangedOther:FireAllClients(player.UserId, tier.tier, tier.auraEnabled,
      tier.auraColor, tier.glowIntensity)
  end
end

function VisiblePowerService.init(remotesFolder: Folder)
  remotes = remotesFolder
  -- ensure remotes
  local function ensure(cls: string, name: string)
    if not remotes:FindFirstChild(name) then
      local inst = Instance.new(cls)
      inst.Name   = name
      inst.Parent = remotes
    end
  end
  ensure("RemoteEvent", "TierChanged")
  ensure("RemoteEvent", "PlayerTierBroadcast")
end

return VisiblePowerService
```

---

## 4. VisiblePowerClient.client.luau

```lua
--!strict
-- StarterPlayerScripts/VisiblePowerClient.client.luau

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local remotes     = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local tierChanged      = remotes:WaitForChild("TierChanged")        :: RemoteEvent
local tierBroadcast    = remotes:WaitForChild("PlayerTierBroadcast"):: RemoteEvent

-- apply aura/glow บน character
local function applyAura(character: Model, auraColor: Color3, glowIntensity: number, enabled: boolean)
  -- ลบออร่าเดิม
  local old = character:FindFirstChild("TierAura")
  if old then old:Destroy() end
  if not enabled or glowIntensity == 0 then return end

  -- Highlight (ขอบเรืองแสง)
  local highlight = Instance.new("Highlight")
  highlight.Name            = "TierAura"
  highlight.OutlineColor    = auraColor
  highlight.OutlineTransparency = 1 - (glowIntensity / 5)  -- tier 7 = โปร่งน้อย = เห็นชัด
  highlight.FillTransparency = 1  -- ไม่ fill ข้างใน
  highlight.Parent          = character

  -- PointLight บน HumanoidRootPart
  local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
  if hrp then
    local oldLight = hrp:FindFirstChild("TierLight")
    if oldLight then oldLight:Destroy() end
    local light = Instance.new("PointLight")
    light.Name       = "TierLight"
    light.Color      = auraColor
    light.Brightness = glowIntensity * 0.6
    light.Range      = 10 + (glowIntensity * 4)
    light.Parent     = hrp
  end
end

-- อัปเดต aura ตัวเอง
tierChanged:Connect(function(tier, auraEnabled, auraColor, glowIntensity)
  local char = localPlayer.Character
  if char then
    applyAura(char, auraColor :: Color3, glowIntensity :: number, auraEnabled :: boolean)
  end
  -- re-apply เมื่อ respawn
  localPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    applyAura(newChar, auraColor :: Color3, glowIntensity :: number, auraEnabled :: boolean)
  end)
end)

-- อัปเดต aura ของผู้เล่นคนอื่น
tierBroadcast:Connect(function(userId, _tier, auraEnabled, auraColor, glowIntensity)
  local target = Players:GetPlayerByUserId(userId :: number)
  if not target or target == localPlayer then return end
  local char = target.Character
  if char then
    applyAura(char, auraColor :: Color3, glowIntensity :: number, auraEnabled :: boolean)
  end
end)
```

---

## 5. default.project.json — เพิ่ม entries

```json
"PlayerTierConfig": { "$path": "src/ReplicatedStorage/Modules/PlayerTierConfig.luau" },
"VisiblePowerService": { "$path": "src/ServerScriptService/Progression/VisiblePowerService.luau" },
"CameraModeController": { "$path": "src/StarterPlayer/StarterPlayerScripts/CameraModeController.client.luau" },
"VisiblePowerClient": { "$path": "src/StarterPlayer/StarterPlayerScripts/VisiblePowerClient.client.luau" }
```

---

## สิ่งที่รู้ล่วงหน้า

| ประเด็น | วิธีแก้ |
|---------|---------|
| `PlayerLevelService` ยังไม่เรียก `VisiblePowerService.onLevelChanged` | เพิ่ม call ใน `PlayerLevelService` ตอน level เปลี่ยน (ถ้ายังไม่มี PlayerLevelService → ใส่ stub) |
| TopDown กล้อง + Character ซ่อน | อาจต้องตั้ง `character.HumanoidRootPart.LocalTransparencyModifier` |
| `Highlight` ใน workspace อาจกระทบ performance | จำกัดไม่เกิน tier 4+ (ตาม `auraEnabled` ใน config) |
| `CameraMode` Attribute ไม่ persist ข้าม session | ถ้าต้องการ persist → เพิ่ม SaveCameraMode RF + server DataStore |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-p7.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ReplicatedStorage/Modules/PlayerTierConfig.luau \
  src/ServerScriptService/Progression/VisiblePowerService.luau \
  src/StarterPlayer/StarterPlayerScripts/CameraModeController.client.luau \
  src/StarterPlayer/StarterPlayerScripts/VisiblePowerClient.client.luau
```

## Git commit (ถ้า clean)

```bash
git add -A
git commit -m "feat(P7): 3-mode camera controller + visible power (tier aura/glow)

- PlayerTierConfig: 7 tiers (Lv1-149), aura color/intensity per tier
- CameraModeController: 1st/3rd/TopDown toggle (key C + UI button), Scale-based
- VisiblePowerService: fires TierChanged + PlayerTierBroadcast on level up
- VisiblePowerClient: Highlight outline + PointLight per tier (T4+)"
```

## รายงานกลับ
- ✅/❌ BUILD
- ✅/❌ STRICT CLEAN (error+line)
- commit hash
