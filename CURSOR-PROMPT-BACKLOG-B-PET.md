# CURSOR PROMPT — Backlog B: Pet/Companion System
> สร้าง: 13 มิ.ย. 2026 · ทำหลัง Backlog A commit
> อ้างอิง: `docs/MASTER-BLUEPRINT.md` §4 เสา 5 Live & Fair + §F Engagement

---

## บริบท

Pet/Companion = สัตว์เลี้ยง/เพื่อนร่วมทาง วิ่งตาม + แสดง passive buff + cosmetic
- ต่อยอดจาก Mount system (มีอยู่แล้วใน `src/`) และ Follow system (InteractionClient)
- ไม่ pay-to-win: pet ให้ QoL buff เล็กน้อย (EXP +5%, item pickup radius +3) — cosmetic คือรายได้หลัก
- DataStore: เก็บ petId ที่ active ต่อ player

---

## ไฟล์ที่ต้องสร้าง

| ไฟล์ | บทบาท | Path |
|------|------|------|
| `PetConfig.luau` | catalog: petId, model, buff, rarity, obtain method | `ReplicatedStorage/Modules/` |
| `PetStore.luau` | DataStore wrapper: owned pets + active pet per player | `ServerScriptService/Commerce/` |
| `PetService.luau` | equip/unequip, spawn model, apply buff, follow logic (server) | `ServerScriptService/Commerce/` |
| `PetHandlers.server.luau` | wire remotes → PetService | `ServerScriptService/Commerce/` |
| `PetClient.client.luau` | pet HUD button (slot), nameplate, smooth follow (client-side lerp) | `StarterPlayerScripts/` |

---

## 1. PetConfig.luau

```lua
--!strict
-- ReplicatedStorage/Modules/PetConfig.luau

export type PetBuff = {
  expBonus    : number,   -- multiplier เพิ่มเติม (เช่น 0.05 = +5%)
  pickupRadius: number,   -- studs เพิ่มรัศมีเก็บไอเทม
  luckBonus   : number,   -- +% drop rate
}

export type PetEntry = {
  id         : string,
  nameTH     : string,
  icon       : string,           -- emoji
  modelId    : string,           -- rbxassetid:// (ใช้ simple Part ถ้ายังไม่มี model)
  rarity     : "Common" | "Rare" | "Epic" | "Legendary",
  buff       : PetBuff,
  obtainMethod: "Event" | "Drop" | "Shop" | "Quest",
}

return {
  Pets = {
    {
      id="slime_blue", nameTH="สไลม์ฟ้า 💧", icon="💧",
      modelId="rbxassetid://0",  -- placeholder → ใส่ asset จริงทีหลัง
      rarity="Common",
      buff={ expBonus=0.05, pickupRadius=3, luckBonus=0 },
      obtainMethod="Drop",
    },
    {
      id="fox_fire", nameTH="จิ้งจอกไฟ 🦊", icon="🦊",
      modelId="rbxassetid://0",
      rarity="Rare",
      buff={ expBonus=0.10, pickupRadius=5, luckBonus=0.03 },
      obtainMethod="Event",
    },
    {
      id="dragon_mini", nameTH="มังกรจิ๋ว 🐉", icon="🐉",
      modelId="rbxassetid://0",
      rarity="Legendary",
      buff={ expBonus=0.15, pickupRadius=8, luckBonus=0.05 },
      obtainMethod="Quest",
    },
  } :: { PetEntry },
}
```

---

## 2. PetStore.luau

```lua
--!strict
-- ServerScriptService/Commerce/PetStore.luau

local DataStoreService = game:GetService("DataStoreService")
local ds = DataStoreService:GetDataStore("UtopiaPet_v1")

export type PlayerPetData = {
  ownedPets : { string },    -- array of petId
  activePetId: string?,      -- nil = ไม่มี pet active
}

local function defaultData(): PlayerPetData
  return { ownedPets = {}, activePetId = nil }
end

local PetStore = {}

function PetStore.get(userId: number): PlayerPetData
  local ok, result = pcall(function()
    return ds:GetAsync("pet_" .. userId)
  end)
  return (ok and result) and result :: PlayerPetData or defaultData()
end

function PetStore.save(userId: number, data: PlayerPetData)
  local ok, err = pcall(function()
    ds:SetAsync("pet_" .. userId, data)
  end)
  if not ok then warn("[PetStore] save failed:", err) end
end

function PetStore.addPet(userId: number, petId: string): boolean
  local data = PetStore.get(userId)
  -- ไม่ซ้ำ
  for _, id in data.ownedPets do
    if id == petId then return false end
  end
  table.insert(data.ownedPets, petId)
  PetStore.save(userId, data)
  return true
end

function PetStore.setActive(userId: number, petId: string?): boolean
  local data = PetStore.get(userId)
  if petId then
    -- ต้องมีใน owned
    local owned = false
    for _, id in data.ownedPets do
      if id == petId then owned = true; break end
    end
    if not owned then return false end
  end
  data.activePetId = petId
  PetStore.save(userId, data)
  return true
end

return PetStore
```

---

## 3. PetService.luau

```lua
--!strict
-- ServerScriptService/Commerce/PetService.luau

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetConfig         = require(ReplicatedStorage.Modules.PetConfig)
local PetStore          = require(script.Parent.PetStore)

-- active pet models ใน workspace (key = userId)
local activePetModels: { [number]: Model } = {}
local remotes: Folder

local PetService = {}

local function findPetConfig(petId: string): PetConfig.PetEntry?
  for _, p in PetConfig.Pets do
    if p.id == petId then return p end
  end
  return nil
end

-- spawn pet model ใกล้ผู้เล่น
local function spawnPetModel(player: Player, petCfg: PetConfig.PetEntry): Model?
  local char = player.Character
  if not char then return nil end
  local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
  if not hrp then return nil end

  -- placeholder: สร้าง Part ง่ายๆ จนกว่าจะมี model จริง
  local model = Instance.new("Model")
  model.Name = "Pet_" .. player.UserId

  local body = Instance.new("Part")
  body.Name     = "PetBody"
  body.Size     = Vector3.new(2, 2, 2)
  body.Position = hrp.Position + Vector3.new(3, 0, 0)
  body.Anchored = false
  body.CanCollide= false
  body.BrickColor= BrickColor.new("Bright blue")
  body.Shape    = Enum.PartType.Ball
  body.Parent   = model

  local nameTag = Instance.new("BillboardGui")
  nameTag.Size        = UDim2.fromOffset(100, 30)
  nameTag.StudsOffset = Vector3.new(0, 2, 0)
  nameTag.Parent      = body
  local nameLbl = Instance.new("TextLabel")
  nameLbl.Size              = UDim2.fromScale(1, 1)
  nameLbl.BackgroundTransparency= 1
  nameLbl.TextColor3        = Color3.new(1, 1, 1)
  nameLbl.TextScaled        = true
  nameLbl.Text              = petCfg.icon .. " " .. petCfg.nameTH
  nameLbl.Parent            = nameTag

  model.PrimaryPart = body
  model.Parent      = workspace

  return model
end

-- เรียกทุก Heartbeat จาก client หรือ server loop เพื่อ follow
-- (ใช้ CFrame lerp ฝั่ง server เบาๆ — client lerp ใน PetClient ด้วย)
local function startFollowLoop(player: Player, petModel: Model)
  local conn: RBXScriptConnection?
  conn = game:GetService("RunService").Heartbeat:Connect(function()
    if not player.Character or not petModel.Parent then
      if conn then conn:Disconnect() end
      return
    end
    local hrp  = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
    local body = petModel:FindFirstChild("PetBody") :: BasePart?
    if not hrp or not body then return end

    local target = hrp.Position + Vector3.new(3, 0, 0)
    local current= body.Position
    -- gentle lerp
    body.CFrame = CFrame.new(current:Lerp(target, 0.05))
  end)
end

function PetService.equipPet(player: Player, petId: string): (boolean, string)
  local petCfg = findPetConfig(petId)
  if not petCfg then return false, "ไม่พบ pet" end

  local ok = PetStore.setActive(player.UserId, petId)
  if not ok then return false, "ไม่มี pet นี้ในคอลเลกชัน" end

  -- ลบ model เดิม (ถ้ามี)
  PetService.unequipPet(player)

  local model = spawnPetModel(player, petCfg)
  if model then
    activePetModels[player.UserId] = model
    startFollowLoop(player, model)
  end

  -- แจ้ง client (buff values)
  if remotes then
    local ev = remotes:FindFirstChild("PetEquipped") :: RemoteEvent?
    if ev then
      ev:FireClient(player, petId, petCfg.buff.expBonus,
        petCfg.buff.pickupRadius, petCfg.buff.luckBonus)
    end
  end

  return true, petCfg.nameTH .. " ออกมาแล้ว!"
end

function PetService.unequipPet(player: Player)
  PetStore.setActive(player.UserId, nil)
  local model = activePetModels[player.UserId]
  if model and model.Parent then model:Destroy() end
  activePetModels[player.UserId] = nil

  if remotes then
    local ev = remotes:FindFirstChild("PetUnequipped") :: RemoteEvent?
    if ev then ev:FireClient(player) end
  end
end

-- ให้ pet แก่ผู้เล่น (จาก drop/quest/event)
function PetService.grantPet(player: Player, petId: string): (boolean, string)
  local petCfg = findPetConfig(petId)
  if not petCfg then return false, "ไม่พบ pet" end
  local added = PetStore.addPet(player.UserId, petId)
  if not added then return false, "มี pet นี้แล้ว" end
  return true, "ได้รับ " .. petCfg.nameTH .. "!"
end

-- ดูคอลเลกชัน pet ของผู้เล่น
function PetService.getCollection(player: Player): { string }
  return PetStore.get(player.UserId).ownedPets
end

function PetService.getActivePetId(player: Player): string?
  return PetStore.get(player.UserId).activePetId
end

-- cleanup เมื่อผู้เล่นออก
function PetService.onPlayerRemoving(player: Player)
  local model = activePetModels[player.UserId]
  if model and model.Parent then model:Destroy() end
  activePetModels[player.UserId] = nil
end

function PetService.init(remotesFolder: Folder)
  remotes = remotesFolder
  local function ensure(cls: string, name: string)
    if not remotes:FindFirstChild(name) then
      local i = Instance.new(cls); i.Name = name; i.Parent = remotes
    end
  end
  ensure("RemoteFunction", "EquipPet")
  ensure("RemoteFunction", "UnequipPet")
  ensure("RemoteFunction", "GetPetCollection")
  ensure("RemoteEvent",   "PetEquipped")
  ensure("RemoteEvent",   "PetUnequipped")

  Players.PlayerRemoving:Connect(PetService.onPlayerRemoving)
end

return PetService
```

---

## 4. PetHandlers.server.luau

```lua
--!strict
-- ServerScriptService/Commerce/PetHandlers.server.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetService        = require(script.Parent.PetService)

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
PetService.init(remotes)

local equipPetRF       = remotes:WaitForChild("EquipPet")        :: RemoteFunction
local unequipPetRF     = remotes:WaitForChild("UnequipPet")      :: RemoteFunction
local getCollectionRF  = remotes:WaitForChild("GetPetCollection") :: RemoteFunction

equipPetRF.OnServerInvoke = function(player, petId)
  return PetService.equipPet(player, petId :: string)
end

unequipPetRF.OnServerInvoke = function(player)
  PetService.unequipPet(player)
  return true
end

getCollectionRF.OnServerInvoke = function(player)
  return PetService.getCollection(player)
end
```

---

## 5. PetClient.client.luau

```lua
--!strict
-- StarterPlayerScripts/PetClient.client.luau

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local PetConfig         = require(ReplicatedStorage.Modules.PetConfig)

local localPlayer  = Players.LocalPlayer
local remotes      = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local equipPetRF   = remotes:WaitForChild("EquipPet")        :: RemoteFunction
local unequipPetRF = remotes:WaitForChild("UnequipPet")      :: RemoteFunction
local getColRF     = remotes:WaitForChild("GetPetCollection") :: RemoteFunction
local petEquipped  = remotes:WaitForChild("PetEquipped")     :: RemoteEvent
local petUnequipped= remotes:WaitForChild("PetUnequipped")   :: RemoteEvent

-- ============ Pet HUD (bottom-center) ============
local screenGui = Instance.new("ScreenGui")
screenGui.Name          = "PetHUD"
screenGui.ResetOnSpawn  = false
screenGui.Parent        = localPlayer.PlayerGui

-- ปุ่มเปิด/ปิด panel
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size     = UDim2.fromScale(0.07, 0.05)
toggleBtn.Position = UDim2.fromScale(0.465, 0.88)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
toggleBtn.TextScaled= true
toggleBtn.Text     = "🐾"
toggleBtn.Parent   = screenGui

-- Collection panel
local panel = Instance.new("Frame")
panel.Size     = UDim2.fromScale(0.45, 0.35)
panel.Position = UDim2.fromScale(0.275, 0.52)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
panel.BackgroundTransparency = 0.1
panel.Visible  = false
panel.Parent   = screenGui

local panelLayout = Instance.new("UIGridLayout")
panelLayout.CellSize    = UDim2.fromScale(0.18, 0.45)
panelLayout.CellPadding = UDim2.fromScale(0.02, 0.05)
panelLayout.Parent      = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Size  = UDim2.fromScale(0.1, 0.15)
closeBtn.Position = UDim2.fromScale(0.89, 0.02)
closeBtn.Text  = "✕"
closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
closeBtn.ZIndex = 2
closeBtn.Parent = panel
closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)

-- Active buff label (แสดงข้างใต้ toggle)
local buffLabel = Instance.new("TextLabel")
buffLabel.Size     = UDim2.fromScale(0.2, 0.04)
buffLabel.Position = UDim2.fromScale(0.4, 0.84)
buffLabel.BackgroundTransparency = 1
buffLabel.TextColor3 = Color3.fromRGB(255, 230, 100)
buffLabel.TextScaled = true
buffLabel.Text     = ""
buffLabel.Parent   = screenGui

local activePetId: string? = nil

local function refreshPanel()
  -- ลบปุ่มเดิม
  for _, c in panel:GetChildren() do
    if c:IsA("TextButton") then c:Destroy() end
  end

  local ok, owned = pcall(function() return getColRF:InvokeServer() end)
  if not ok or not owned then return end

  for _, petId in owned :: { string } do
    local cfg: PetConfig.PetEntry? = nil
    for _, p in PetConfig.Pets do
      if p.id == petId then cfg = p; break end
    end
    if not cfg then continue end

    local btn = Instance.new("TextButton")
    btn.Size   = UDim2.fromScale(1, 1)
    btn.BackgroundColor3 = activePetId == petId
      and Color3.fromRGB(80,160,80) or Color3.fromRGB(50,50,80)
    btn.TextScaled = true
    btn.Text = cfg.icon .. "\n" .. cfg.nameTH
    btn.Parent = panel

    btn.MouseButton1Click:Connect(function()
      if activePetId == petId then
        -- unequip
        pcall(function() unequipPetRF:InvokeServer() end)
      else
        pcall(function() equipPetRF:InvokeServer(petId) end)
      end
      panel.Visible = false
    end)
  end
end

toggleBtn.MouseButton1Click:Connect(function()
  panel.Visible = not panel.Visible
  if panel.Visible then refreshPanel() end
end)

-- รับ buff update จาก server
petEquipped:Connect(function(petId, expBonus, pickupRadius, luckBonus)
  activePetId = petId :: string
  buffLabel.Text = string.format("🐾 EXP+%d%% Drop+%d%%",
    math.floor((expBonus :: number) * 100),
    math.floor((luckBonus :: number) * 100))
  -- client-side smooth follow (ใช้ RenderStepped lerp บน pet Part)
  -- PetService server ทำ follow loop แล้ว — client แค่ update label
end)

petUnequipped:Connect(function()
  activePetId = nil
  buffLabel.Text = ""
end)
```

---

## 6. default.project.json — เพิ่ม entries

```json
"PetConfig":    { "$path": "src/ReplicatedStorage/Modules/PetConfig.luau" },
"PetStore":     { "$path": "src/ServerScriptService/Commerce/PetStore.luau" },
"PetService":   { "$path": "src/ServerScriptService/Commerce/PetService.luau" },
"PetHandlers":  { "$path": "src/ServerScriptService/Commerce/PetHandlers.server.luau" },
"PetClient":    { "$path": "src/StarterPlayer/StarterPlayerScripts/PetClient.client.luau" }
```

---

## สิ่งที่รู้ล่วงหน้า

| ประเด็น | วิธีแก้ |
|---------|---------|
| `modelId = "rbxassetid://0"` | placeholder — ใส่ asset จริงทีหลัง ไม่กระทบ build |
| Server Heartbeat follow กิน performance | จำกัด: 1 loop ต่อ player, lerp factor เล็ก (0.05), ยกเลิกเมื่อ model ถูก destroy |
| `PetConfig.PetEntry` type ใน PetClient | ต้องใช้ `for _, p in PetConfig.Pets do` loop แทน index direct |
| pet buff apply จริง | `EventCalendarService.getMultiplier("DoubleExp")` + `petCfg.buff.expBonus` รวมกันใน `PlayerLevelService` |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-backlog-b.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ReplicatedStorage/Modules/PetConfig.luau \
  src/ServerScriptService/Commerce/PetStore.luau \
  src/ServerScriptService/Commerce/PetService.luau \
  src/ServerScriptService/Commerce/PetHandlers.server.luau \
  src/StarterPlayer/StarterPlayerScripts/PetClient.client.luau
```

## Git commit (ถ้า clean)

```bash
git add -A
git commit -m "feat(P8+): Pet/Companion system

- PetConfig: 3 pets (Common/Rare/Legendary), buff table, obtain method
- PetStore: DataStore owned list + active pet per player
- PetService: equip/unequip/grant, spawn placeholder model, Heartbeat follow loop
- PetHandlers: wire EquipPet/UnequipPet/GetPetCollection RF
- PetClient: collection panel (grid), buff label, active highlight"
```

## รายงานกลับ
- ✅/❌ BUILD · ✅/❌ STRICT CLEAN (error+line) · commit hash
