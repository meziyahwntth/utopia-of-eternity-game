# CURSOR PROMPT — Vehicle & Legendary Mount System
> สร้าง: 13 มิ.ย. 2026
> Visual refs: รูปที่ Praphan ส่งมา (white-gold aesthetic ตลอด — Eternity City theme)

---

## Visual Reference Summary

ภาพ concept ที่กำหนด direction:

| ประเภท | Visual |
|--------|--------|
| Ground Personal | Luxury futuristic sedan white-gold, sports roadster, motorcycle |
| Ground Group | Open-top gold SUV (6 seat), pickup truck white-gold, city tram glass+gold |
| Air | Hoverpod (4 seat open), sky shuttle (large transparent hull + gold) |
| Water | Speedboat white-gold, glass-dome water bus |
| Mount — Ground | White Wolf gold armor, White Lion crown, White Celestial Deer gold antlers |
| Mount — Flying | Red-Gold Phoenix, White Pegasus gold harness, White Dragon gold filigree, Gold Griffin crowned |

**สี palette ทุก asset:** White pearl body · Gold trim/accent · Teal/cyan glow detail

---

## สิ่งที่ต้องสร้างใหม่ทั้งหมด

| ไฟล์ | บทบาท |
|------|-------|
| `ReplicatedStorage/Modules/VehicleConfig.luau` | catalog ยานพาหนะ 15 คัน |
| `ReplicatedStorage/Modules/MountConfig.luau` | catalog legendary mount 7 ตัว |
| `ServerScriptService/Commerce/VehicleMountService.server.luau` | spawn/despawn + speed |
| `ServerScriptService/Commerce/VehicleMountHandlers.server.luau` | remote wire |
| `StarterPlayerScripts/VehicleMountClient.client.luau` | equip UI + garage panel |
| `default.project.json` | +5 entries |

**Remote folder:** `CommerceRemotes` (ตาม TravelTicketWallet pattern)

---

## VehicleConfig.luau

```lua
--!strict
-- VehicleConfig.luau
-- Visual ref: white-gold Eternity City aesthetic

export type VehicleDef = {
  id            : string,
  displayName   : string,
  vehicleClass  : "Personal" | "Group" | "Air" | "Water",
  seats         : number,     -- รวม driver
  speedBoost    : number,     -- +studs/s บน default walkspeed 16
  canFly        : boolean,
  canSwim       : boolean,
  robuxPrice    : number,
  creditPrice   : number,     -- 0 = ซื้อด้วย Robux เท่านั้น
  modelId       : number,     -- Roblox Asset ID (0 = placeholder box)
  trailEffect   : string,     -- particle effect name
  tier          : "Standard" | "Premium" | "Legendary",
}

local VehicleConfig = {}

VehicleConfig.All: {VehicleDef} = {

  -- ==============================
  -- PERSONAL GROUND (solo/duo)
  -- ==============================
  {
    id = "eternity_roadster",
    displayName = "Eternity Roadster",
    vehicleClass = "Personal",
    seats = 2,
    speedBoost = 20,
    canFly = false, canSwim = false,
    robuxPrice = 399, creditPrice = 0,
    modelId = 0,
    trailEffect = "GoldSpark",
    tier = "Standard",
  },
  {
    id = "prism_motorcycle",
    displayName = "Prism Motorcycle",
    vehicleClass = "Personal",
    seats = 1,
    speedBoost = 28,
    canFly = false, canSwim = false,
    robuxPrice = 299, creditPrice = 0,
    modelId = 0,
    trailEffect = "NeonBlue",
    tier = "Standard",
  },
  {
    id = "luxe_sedan_aurora",
    displayName = "Aurora Luxe Sedan",
    vehicleClass = "Personal",
    seats = 2,
    speedBoost = 18,
    canFly = false, canSwim = false,
    robuxPrice = 499, creditPrice = 0,
    modelId = 0,
    trailEffect = "GoldGlow",
    tier = "Premium",
  },
  {
    id = "cyber_hoverbike",
    displayName = "Cyber Hoverbike",
    vehicleClass = "Personal",
    seats = 1,
    speedBoost = 32,
    canFly = false, canSwim = false,
    robuxPrice = 449, creditPrice = 0,
    modelId = 0,
    trailEffect = "CyberPulse",
    tier = "Premium",
  },

  -- ==============================
  -- GROUP GROUND (3-6 seats)
  -- ==============================
  {
    id = "gold_party_suv",
    displayName = "Gold Party SUV",
    vehicleClass = "Group",
    seats = 6,
    speedBoost = 14,
    canFly = false, canSwim = false,
    robuxPrice = 799, creditPrice = 0,
    modelId = 0,
    trailEffect = "GoldConfetti",
    tier = "Premium",
  },
  {
    id = "eternity_pickup",
    displayName = "Eternity Pickup",
    vehicleClass = "Group",
    seats = 4,
    speedBoost = 16,
    canFly = false, canSwim = false,
    robuxPrice = 599, creditPrice = 0,
    modelId = 0,
    trailEffect = "DustGold",
    tier = "Standard",
  },
  {
    id = "city_glass_tram",
    displayName = "City Glass Tram",
    vehicleClass = "Group",
    seats = 12,
    speedBoost = 10,
    canFly = false, canSwim = false,
    robuxPrice = 999, creditPrice = 0,
    modelId = 0,
    trailEffect = "ElectricArc",
    tier = "Premium",
  },

  -- ==============================
  -- AIR VEHICLES
  -- ==============================
  {
    id = "sky_hoverpod",
    displayName = "Sky Hoverpod",
    vehicleClass = "Air",
    seats = 4,
    speedBoost = 24,
    canFly = true, canSwim = false,
    robuxPrice = 899, creditPrice = 0,
    modelId = 0,
    trailEffect = "CloudPuff",
    tier = "Premium",
  },
  {
    id = "eternity_sky_shuttle",
    displayName = "Eternity Sky Shuttle",
    vehicleClass = "Air",
    seats = 10,
    speedBoost = 18,
    canFly = true, canSwim = false,
    robuxPrice = 1499, creditPrice = 0,
    modelId = 0,
    trailEffect = "GoldContrail",
    tier = "Legendary",
  },
  {
    id = "prism_jet_solo",
    displayName = "Prism Personal Jet",
    vehicleClass = "Air",
    seats = 2,
    speedBoost = 40,
    canFly = true, canSwim = false,
    robuxPrice = 1199, creditPrice = 0,
    modelId = 0,
    trailEffect = "PrismTrail",
    tier = "Legendary",
  },

  -- ==============================
  -- WATER VEHICLES
  -- ==============================
  {
    id = "marina_speedboat",
    displayName = "Marina Speedboat",
    vehicleClass = "Water",
    seats = 2,
    speedBoost = 22,
    canFly = false, canSwim = true,
    robuxPrice = 599, creditPrice = 0,
    modelId = 0,
    trailEffect = "WaterFoam",
    tier = "Standard",
  },
  {
    id = "canal_water_bus",
    displayName = "Canal Glass Water Bus",
    vehicleClass = "Water",
    seats = 10,
    speedBoost = 12,
    canFly = false, canSwim = true,
    robuxPrice = 999, creditPrice = 0,
    modelId = 0,
    trailEffect = "TealWake",
    tier = "Premium",
  },
  {
    id = "luxury_yacht_pod",
    displayName = "Luxury Yacht Pod",
    vehicleClass = "Water",
    seats = 6,
    speedBoost = 16,
    canFly = false, canSwim = true,
    robuxPrice = 1299, creditPrice = 0,
    modelId = 0,
    trailEffect = "GoldWave",
    tier = "Legendary",
  },

  -- ==============================
  -- LEGENDARY UNIQUE
  -- ==============================
  {
    id = "void_phantom_racer",
    displayName = "Void Phantom Racer",
    vehicleClass = "Personal",
    seats = 1,
    speedBoost = 50,
    canFly = false, canSwim = false,
    robuxPrice = 0, creditPrice = 50000,  -- credits-only, grind reward
    modelId = 0,
    trailEffect = "VoidShadow",
    tier = "Legendary",
  },
  {
    id = "eternal_sky_throne",
    displayName = "Eternal Sky Throne",
    vehicleClass = "Air",
    seats = 1,
    speedBoost = 35,
    canFly = true, canSwim = false,
    robuxPrice = 0, creditPrice = 100000,  -- endgame flex
    modelId = 0,
    trailEffect = "EternityAura",
    tier = "Legendary",
  },
}

-- Lookup helper
function VehicleConfig.getById(id: string): VehicleDef?
  for _, v in VehicleConfig.All do
    if v.id == id then return v end
  end
  return nil
end

return VehicleConfig
```

---

## MountConfig.luau

```lua
--!strict
-- MountConfig.luau
-- Legendary mounts — visual refs: white-gold fantasy creatures

export type MountDef = {
  id           : string,
  displayName  : string,
  mountType    : "Ground" | "Flying",
  speedBoost   : number,
  flyHeight    : number,    -- Y offset บน SkyAltitude (flying เท่านั้น, 0 = ground)
  robuxPrice   : number,
  creditPrice  : number,
  modelId      : number,    -- Roblox Asset ID (0 = placeholder)
  auraEffect   : string,
  rarity       : "Epic" | "Legendary" | "Mythic",
  loreDesc     : string,
}

local MountConfig = {}

MountConfig.All: {MountDef} = {

  -- ==============================
  -- GROUND MOUNTS
  -- ==============================
  {
    id = "white_timber_wolf",
    displayName = "White Timber Wolf",
    mountType = "Ground",
    speedBoost = 22,
    flyHeight = 0,
    robuxPrice = 799, creditPrice = 0,
    modelId = 0,
    auraEffect = "FrostBreath",
    rarity = "Epic",
    loreDesc = "สัตว์ผู้พิทักษ์แห่งป่า Prism เชื่องได้ด้วยผู้ที่มีความกล้าหาญ",
  },
  {
    id = "golden_lion_king",
    displayName = "Golden Lion King",
    mountType = "Ground",
    speedBoost = 26,
    flyHeight = 0,
    robuxPrice = 1299, creditPrice = 0,
    modelId = 0,
    auraEffect = "SolarMane",
    rarity = "Legendary",
    loreDesc = "ราชาแห่งสัตว์บนเมฆ ผู้สวมมงกุฎทองแห่ง Eternity City",
  },
  {
    id = "celestial_white_deer",
    displayName = "Celestial White Deer",
    mountType = "Ground",
    speedBoost = 20,
    flyHeight = 0,
    robuxPrice = 999, creditPrice = 0,
    modelId = 0,
    auraEffect = "StardustHoof",
    rarity = "Epic",
    loreDesc = "กวางศักดิ์สิทธิ์ที่โขลงมาจากเมฆ มีเขาทองคำจากแสงดาว",
  },

  -- ==============================
  -- FLYING MOUNTS
  -- ==============================
  {
    id = "red_gold_phoenix",
    displayName = "Red-Gold Phoenix",
    mountType = "Flying",
    speedBoost = 30,
    flyHeight = 50,
    robuxPrice = 1499, creditPrice = 0,
    modelId = 0,
    auraEffect = "FlameTail",
    rarity = "Legendary",
    loreDesc = "นกเพลิงที่ฟื้นจากเถ้าถ่านของ Hellbound ทุก 1000 ปี",
  },
  {
    id = "white_pegasus",
    displayName = "White Pegasus",
    mountType = "Flying",
    speedBoost = 28,
    flyHeight = 40,
    robuxPrice = 1399, creditPrice = 0,
    modelId = 0,
    auraEffect = "WindMane",
    rarity = "Legendary",
    loreDesc = "ม้าปีกขาวแห่งท้องฟ้า บรรพบุรุษของฝูงม้าที่โบยบินรอบ Aurora Spire",
  },
  {
    id = "prism_white_dragon",
    displayName = "Prism White Dragon",
    mountType = "Flying",
    speedBoost = 35,
    flyHeight = 60,
    robuxPrice = 0, creditPrice = 150000,  -- endgame unlock
    modelId = 0,
    auraEffect = "PrismScales",
    rarity = "Mythic",
    loreDesc = "มังกรแห่ง Prism Covenant ผู้เก็บรักษา Key #1 ไว้บนร่างกาย",
  },
  {
    id = "golden_griffin",
    displayName = "Golden Griffin",
    mountType = "Flying",
    speedBoost = 32,
    flyHeight = 55,
    robuxPrice = 1699, creditPrice = 0,
    modelId = 0,
    auraEffect = "RegalWing",
    rarity = "Mythic",
    loreDesc = "กริฟฟินสวมมงกุฎทองแห่งสกาย — ผู้พิทักษ์ท้องฟ้าของ Utopia",
  },
}

function MountConfig.getById(id: string): MountDef?
  for _, m in MountConfig.All do
    if m.id == id then return m end
  end
  return nil
end

return MountConfig
```

---

## VehicleMountService.server.luau

```lua
--!strict
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleConfig = require(ReplicatedStorage.Modules.VehicleConfig)
local MountConfig   = require(ReplicatedStorage.Modules.MountConfig)

-- DataStore key: "UtopiaVehicleMount_v1"
-- Schema: { ownedVehicles: {string}, ownedMounts: {string}, equippedVehicle: string?, equippedMount: string? }

local DataStoreService = game:GetService("DataStoreService")
local vmStore = DataStoreService:GetDataStore("UtopiaVehicleMount_v1")

local VehicleMountService = {}

-- In-memory cache
local playerData: {[number]: {
  ownedVehicles: {[string]: boolean},
  ownedMounts:   {[string]: boolean},
  equippedVehicle: string?,
  equippedMount:   string?,
}} = {}

-- Spawned model refs (cleanup on unequip)
local spawnedModels: {[number]: Model?} = {}

-- ── Load / Save ──────────────────────────────────────────────────────────────

function VehicleMountService.load(player: Player)
  local userId = player.UserId
  local ok, data = pcall(function()
    return vmStore:GetAsync("vm_" .. userId)
  end)
  if ok and data then
    playerData[userId] = data
  else
    playerData[userId] = {
      ownedVehicles  = {},
      ownedMounts    = {},
      equippedVehicle = nil,
      equippedMount   = nil,
    }
  end
end

function VehicleMountService.save(player: Player)
  local userId = player.UserId
  local d = playerData[userId]
  if not d then return end
  pcall(function()
    vmStore:SetAsync("vm_" .. userId, d)
  end)
end

-- ── Ownership ─────────────────────────────────────────────────────────────────

function VehicleMountService.grantVehicle(player: Player, vehicleId: string): boolean
  local d = playerData[player.UserId]
  if not d then return false end
  if not VehicleConfig.getById(vehicleId) then return false end
  d.ownedVehicles[vehicleId] = true
  VehicleMountService.save(player)
  return true
end

function VehicleMountService.grantMount(player: Player, mountId: string): boolean
  local d = playerData[player.UserId]
  if not d then return false end
  if not MountConfig.getById(mountId) then return false end
  d.ownedMounts[mountId] = true
  VehicleMountService.save(player)
  return true
end

function VehicleMountService.hasVehicle(player: Player, vehicleId: string): boolean
  local d = playerData[player.UserId]
  return d ~= nil and d.ownedVehicles[vehicleId] == true
end

function VehicleMountService.hasMount(player: Player, mountId: string): boolean
  local d = playerData[player.UserId]
  return d ~= nil and d.ownedMounts[mountId] == true
end

-- ── Equip / Unequip ───────────────────────────────────────────────────────────

local BASE_WALKSPEED  = 16
local BASE_JUMPPOWER  = 7.2

local function applySpeed(player: Player, boost: number, fly: boolean, flyHeight: number)
  local char = player.Character
  if not char then return end
  local hum = char:FindFirstChild("Humanoid") :: Humanoid?
  if not hum then return end
  hum.WalkSpeed = BASE_WALKSPEED + boost
  -- ลบ jump เพื่อ simplicity — เพิ่ม fly logic ทีหลัง
  -- Flying mount: set BodyVelocity หรือ VehicleSeat ใน workshop
end

local function removeSpeed(player: Player)
  local char = player.Character
  if not char then return end
  local hum = char:FindFirstChild("Humanoid") :: Humanoid?
  if not hum then return end
  hum.WalkSpeed = BASE_WALKSPEED
end

local function despawnModel(player: Player)
  local m = spawnedModels[player.UserId]
  if m then m:Destroy() end
  spawnedModels[player.UserId] = nil
end

local function spawnVehicleModel(player: Player, def: VehicleConfig.VehicleDef)
  -- TODO: ใส่ modelId จริง → InsertService:LoadAsset(def.modelId)
  -- ตอนนี้ spawn placeholder part
  local char = player.Character
  if not char then return end
  local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
  if not root then return end

  local box = Instance.new("Part")
  box.Name  = "VehiclePlaceholder_" .. def.id
  box.Size  = Vector3.new(6, 2.5, 12)
  box.Color = Color3.fromRGB(240, 230, 180)  -- pearl white
  box.Anchored = false
  box.CanCollide = false
  box.Parent = workspace

  local weld = Instance.new("WeldConstraint")
  weld.Part0 = root
  weld.Part1 = box
  weld.Parent = box
  box.CFrame = root.CFrame * CFrame.new(0, -2, 0)

  local m = Instance.new("Model")
  m.Name = "VehicleModel"
  box.Parent = m
  m.Parent = workspace

  spawnedModels[player.UserId] = m
end

local function spawnMountModel(player: Player, def: MountConfig.MountDef)
  local char = player.Character
  if not char then return end
  local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
  if not root then return end

  local box = Instance.new("Part")
  box.Name  = "MountPlaceholder_" .. def.id
  box.Size  = Vector3.new(4, 3, 5)
  box.Color = Color3.fromRGB(255, 255, 240)
  box.Anchored = false
  box.CanCollide = false
  box.Parent = workspace

  local weld = Instance.new("WeldConstraint")
  weld.Part0 = root
  weld.Part1 = box
  weld.Parent = box
  box.CFrame = root.CFrame * CFrame.new(0, -3, 0)

  local m = Instance.new("Model")
  m.Name = "MountModel"
  box.Parent = m
  m.Parent = workspace

  spawnedModels[player.UserId] = m
end

function VehicleMountService.equipVehicle(player: Player, vehicleId: string): (boolean, string)
  local d = playerData[player.UserId]
  if not d then return false, "not_loaded" end
  if not d.ownedVehicles[vehicleId] then return false, "not_owned" end
  local def = VehicleConfig.getById(vehicleId)
  if not def then return false, "invalid_id" end

  -- unequip old
  despawnModel(player)
  removeSpeed(player)
  d.equippedVehicle = nil
  d.equippedMount   = nil

  d.equippedVehicle = vehicleId
  applySpeed(player, def.speedBoost, def.canFly, 0)
  spawnVehicleModel(player, def)
  VehicleMountService.save(player)
  return true, "ok"
end

function VehicleMountService.equipMount(player: Player, mountId: string): (boolean, string)
  local d = playerData[player.UserId]
  if not d then return false, "not_loaded" end
  if not d.ownedMounts[mountId] then return false, "not_owned" end
  local def = MountConfig.getById(mountId)
  if not def then return false, "invalid_id" end

  despawnModel(player)
  removeSpeed(player)
  d.equippedVehicle = nil
  d.equippedMount   = nil

  d.equippedMount = mountId
  applySpeed(player, def.speedBoost, def.mountType == "Flying", def.flyHeight)
  spawnMountModel(player, def)
  VehicleMountService.save(player)
  return true, "ok"
end

function VehicleMountService.unequip(player: Player)
  local d = playerData[player.UserId]
  if not d then return end
  despawnModel(player)
  removeSpeed(player)
  d.equippedVehicle = nil
  d.equippedMount   = nil
  VehicleMountService.save(player)
end

function VehicleMountService.getState(player: Player)
  local d = playerData[player.UserId]
  if not d then return nil end
  return {
    ownedVehicles   = d.ownedVehicles,
    ownedMounts     = d.ownedMounts,
    equippedVehicle = d.equippedVehicle,
    equippedMount   = d.equippedMount,
  }
end

-- ── Lifecycle ────────────────────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(p)
  VehicleMountService.load(p)
  p.CharacterRemoving:Connect(function() despawnModel(p) end)
end)

Players.PlayerRemoving:Connect(function(p)
  despawnModel(p)
  VehicleMountService.save(p)
  playerData[p.UserId] = nil
end)

return VehicleMountService
```

---

## VehicleMountHandlers.server.luau

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VehicleMountService = require(
  game:GetService("ServerScriptService").Commerce.VehicleMountService
)

local CommerceRemotes = ReplicatedStorage:WaitForChild("CommerceRemotes")

-- Remote names
local GET_STATE_RF      = "GetVehicleMountState"
local EQUIP_VEHICLE_RE  = "EquipVehicle"
local EQUIP_MOUNT_RE    = "EquipMount"
local UNEQUIP_RE        = "UnequipVehicleMount"

-- RF: GetVehicleMountState
local getStateRF = Instance.new("RemoteFunction")
getStateRF.Name = GET_STATE_RF
getStateRF.Parent = CommerceRemotes
getStateRF.OnServerInvoke = function(player)
  return VehicleMountService.getState(player)
end

-- RE: EquipVehicle
local equipVehicleRE = Instance.new("RemoteEvent")
equipVehicleRE.Name = EQUIP_VEHICLE_RE
equipVehicleRE.Parent = CommerceRemotes
equipVehicleRE.OnServerEvent:Connect(function(player, vehicleId)
  if type(vehicleId) ~= "string" then return end
  VehicleMountService.equipVehicle(player, vehicleId)
end)

-- RE: EquipMount
local equipMountRE = Instance.new("RemoteEvent")
equipMountRE.Name = EQUIP_MOUNT_RE
equipMountRE.Parent = CommerceRemotes
equipMountRE.OnServerEvent:Connect(function(player, mountId)
  if type(mountId) ~= "string" then return end
  VehicleMountService.equipMount(player, mountId)
end)

-- RE: Unequip
local unequipRE = Instance.new("RemoteEvent")
unequipRE.Name = UNEQUIP_RE
unequipRE.Parent = CommerceRemotes
unequipRE.OnServerEvent:Connect(function(player)
  VehicleMountService.unequip(player)
end)
```

---

## VehicleMountClient.client.luau

```lua
--!strict
-- VehicleMountClient.client.luau
-- UI: Garage Panel — แท็บ Vehicles | Mounts

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommerceRemotes = ReplicatedStorage:WaitForChild("CommerceRemotes")
local getStateRF      = CommerceRemotes:WaitForChild("GetVehicleMountState") :: RemoteFunction
local equipVehicleRE  = CommerceRemotes:WaitForChild("EquipVehicle")         :: RemoteEvent
local equipMountRE    = CommerceRemotes:WaitForChild("EquipMount")           :: RemoteEvent
local unequipRE       = CommerceRemotes:WaitForChild("UnequipVehicleMount")  :: RemoteEvent

local VehicleConfig = require(ReplicatedStorage.Modules.VehicleConfig)
local MountConfig   = require(ReplicatedStorage.Modules.MountConfig)

local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui")

-- ── Build UI ──────────────────────────────────────────────────────────────────

local screen = Instance.new("ScreenGui")
screen.Name = "GarageUI"
screen.ResetOnSpawn = false
screen.Enabled = false
screen.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 560, 0, 420)
frame.Position = UDim2.new(0.5, -280, 0.5, -210)
frame.BackgroundColor3 = Color3.fromRGB(15, 10, 30)
frame.BorderSizePixel = 0
frame.Parent = screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundTransparency = 1
title.Text = "🚗  GARAGE"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 210, 100)
title.Parent = frame

-- Tab buttons
local tabVehicle = Instance.new("TextButton")
tabVehicle.Size = UDim2.new(0.5, -4, 0, 30)
tabVehicle.Position = UDim2.new(0, 4, 0, 38)
tabVehicle.Text = "⚙ Vehicles"
tabVehicle.Font = Enum.Font.GothamSemibold
tabVehicle.TextSize = 14
tabVehicle.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
tabVehicle.TextColor3 = Color3.fromRGB(10, 5, 20)
tabVehicle.Parent = frame

local tabMount = Instance.new("TextButton")
tabMount.Size = UDim2.new(0.5, -4, 0, 30)
tabMount.Position = UDim2.new(0.5, 0, 0, 38)
tabMount.Text = "🐲 Mounts"
tabMount.Font = Enum.Font.GothamSemibold
tabMount.TextSize = 14
tabMount.BackgroundColor3 = Color3.fromRGB(60, 40, 80)
tabMount.TextColor3 = Color3.fromRGB(200, 180, 255)
tabMount.Parent = frame

-- Scroll area
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -84)
scroll.Position = UDim2.new(0, 8, 0, 76)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = scroll

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 4)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = frame
Instance.new("UICorner").Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() screen.Enabled = false end)

-- ── Populate ──────────────────────────────────────────────────────────────────

local currentTab = "vehicle"

local function makeRow(name: string, subtitle: string, owned: boolean, equipped: boolean, onEquip: () -> ())
  local row = Instance.new("Frame")
  row.Size = UDim2.new(1, -8, 0, 52)
  row.BackgroundColor3 = equipped
    and Color3.fromRGB(60, 50, 10)
    or  Color3.fromRGB(25, 20, 40)
  row.BorderSizePixel = 0
  Instance.new("UICorner").Parent = row

  local lbl = Instance.new("TextLabel")
  lbl.Size = UDim2.new(0.6, 0, 0.55, 0)
  lbl.Position = UDim2.new(0, 10, 0, 4)
  lbl.BackgroundTransparency = 1
  lbl.Text = name
  lbl.Font = Enum.Font.GothamSemibold
  lbl.TextSize = 13
  lbl.TextColor3 = equipped and Color3.fromRGB(255, 220, 80) or Color3.fromRGB(220, 220, 255)
  lbl.TextXAlignment = Enum.TextXAlignment.Left
  lbl.Parent = row

  local sub = Instance.new("TextLabel")
  sub.Size = UDim2.new(0.6, 0, 0.4, 0)
  sub.Position = UDim2.new(0, 10, 0.55, 0)
  sub.BackgroundTransparency = 1
  sub.Text = subtitle
  sub.Font = Enum.Font.Gotham
  sub.TextSize = 11
  sub.TextColor3 = Color3.fromRGB(150, 140, 180)
  sub.TextXAlignment = Enum.TextXAlignment.Left
  sub.Parent = row

  local btn = Instance.new("TextButton")
  btn.Size = UDim2.new(0, 90, 0, 32)
  btn.Position = UDim2.new(1, -100, 0.5, -16)
  btn.Font = Enum.Font.GothamBold
  btn.TextSize = 12

  if equipped then
    btn.Text = "✓ ON"
    btn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.MouseButton1Click:Connect(function() unequipRE:FireServer(); refresh() end)
  elseif owned then
    btn.Text = "Equip"
    btn.BackgroundColor3 = Color3.fromRGB(80, 60, 160)
    btn.TextColor3 = Color3.fromRGB(220, 210, 255)
    btn.MouseButton1Click:Connect(function() onEquip(); task.delay(0.3, refresh) end)
  else
    btn.Text = "🔒 Buy"
    btn.BackgroundColor3 = Color3.fromRGB(50, 40, 70)
    btn.TextColor3 = Color3.fromRGB(160, 140, 200)
    -- TODO: open shop / Robux prompt
  end
  Instance.new("UICorner").Parent = btn
  btn.Parent = row
  return row
end

local state: any = nil

local function refresh()
  state = getStateRF:InvokeServer()
  for _, c in scroll:GetChildren() do
    if not c:IsA("UIListLayout") then c:Destroy() end
  end

  if currentTab == "vehicle" then
    for _, def in VehicleConfig.All do
      local owned    = state and state.ownedVehicles[def.id] == true
      local equipped = state and state.equippedVehicle == def.id
      local sub = def.vehicleClass .. " · " .. def.seats .. " seats · +" .. def.speedBoost .. " spd"
      local row = makeRow(def.displayName, sub, owned, equipped, function()
        equipVehicleRE:FireServer(def.id)
      end)
      row.Parent = scroll
    end
  else
    for _, def in MountConfig.All do
      local owned    = state and state.ownedMounts[def.id] == true
      local equipped = state and state.equippedMount == def.id
      local sub = def.mountType .. " · +" .. def.speedBoost .. " spd · " .. def.rarity
      local row = makeRow(def.displayName, sub, owned, equipped, function()
        equipMountRE:FireServer(def.id)
      end)
      row.Parent = scroll
    end
  end
end

tabVehicle.MouseButton1Click:Connect(function()
  currentTab = "vehicle"
  tabVehicle.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
  tabMount.BackgroundColor3   = Color3.fromRGB(60, 40, 80)
  refresh()
end)

tabMount.MouseButton1Click:Connect(function()
  currentTab = "mount"
  tabMount.BackgroundColor3   = Color3.fromRGB(255, 200, 50)
  tabVehicle.BackgroundColor3 = Color3.fromRGB(60, 40, 80)
  refresh()
end)

-- ── Open trigger (keybind G หรือ HUD button) ─────────────────────────────────
-- ปัจจุบัน: เปิดผ่าน BindableEvent "OpenGarage"
local openGarage = ReplicatedStorage:FindFirstChild("OpenGarage") :: BindableEvent?
if openGarage then
  openGarage.Event:Connect(function()
    screen.Enabled = not screen.Enabled
    if screen.Enabled then refresh() end
  end)
end
```

---

## default.project.json additions

```json
"VehicleConfig": {
  "$path": "src/ReplicatedStorage/Modules/VehicleConfig.luau"
},
"MountConfig": {
  "$path": "src/ReplicatedStorage/Modules/MountConfig.luau"
},
"VehicleMountService": {
  "$path": "src/ServerScriptService/Commerce/VehicleMountService.server.luau"
},
"VehicleMountHandlers": {
  "$path": "src/ServerScriptService/Commerce/VehicleMountHandlers.server.luau"
},
"VehicleMountClient": {
  "$path": "src/StarterPlayer/StarterPlayerScripts/VehicleMountClient.client.luau"
}
```

> เพิ่มใน `"ReplicatedStorage" > "Modules"` และ `"ServerScriptService" > "Commerce"` ตาม pattern เดิม

---

## HUD Button — เชื่อมปุ่ม Garage

ใน `src/StarterPlayer/StarterPlayerScripts/HUDClient.client.luau` (ถ้ามี) เพิ่มปุ่ม:

```lua
-- เพิ่มปุ่ม 🚗 Garage
local garageBtn = Instance.new("TextButton")
garageBtn.Text = "🚗"
garageBtn.Size = UDim2.new(0, 44, 0, 44)
-- วางต่อจากปุ่มล่าสุดใน HUD
garageBtn.MouseButton1Click:Connect(function()
  local openGarage = game:GetService("ReplicatedStorage"):FindFirstChild("OpenGarage")
  if openGarage then openGarage:Fire() end
end)
```

> สร้าง BindableEvent "OpenGarage" ใน ReplicatedStorage ตอน boot (GameBootstrap หรือ VehicleMountHandlers)

---

## Visual Ref → Asset Pipeline

Concept images ที่ Praphan ให้มา → save ที่:

```
docs/visual-ref/vehicles/
  ground-personal/
    eternity-roadster.jpg
    prism-motorcycle.jpg
    luxe-sedan-aurora.jpg
    cyber-hoverbike.jpg
  ground-group/
    gold-party-suv.jpg
    eternity-pickup.jpg
    city-glass-tram.jpg
  air/
    sky-hoverpod.jpg
    eternity-sky-shuttle.jpg
    prism-jet-solo.jpg
  water/
    marina-speedboat.jpg
    canal-water-bus.jpg
    luxury-yacht-pod.jpg
  legendary/
    void-phantom-racer.jpg
    eternal-sky-throne.jpg

docs/visual-ref/mounts/
    white-timber-wolf.jpg
    golden-lion-king.jpg
    celestial-white-deer.jpg
    red-gold-phoenix.jpg
    white-pegasus.jpg
    prism-white-dragon.jpg
    golden-griffin.jpg
```

---

## รายการ Assets (สรุป)

| # | ID | Type | Class | Seats | Speed | Price |
|---|-----|------|-------|-------|-------|-------|
| 1 | eternity_roadster | Vehicle | Personal | 2 | +20 | 399R |
| 2 | prism_motorcycle | Vehicle | Personal | 1 | +28 | 299R |
| 3 | luxe_sedan_aurora | Vehicle | Personal | 2 | +18 | 499R |
| 4 | cyber_hoverbike | Vehicle | Personal | 1 | +32 | 449R |
| 5 | gold_party_suv | Vehicle | Group | 6 | +14 | 799R |
| 6 | eternity_pickup | Vehicle | Group | 4 | +16 | 599R |
| 7 | city_glass_tram | Vehicle | Group | 12 | +10 | 999R |
| 8 | sky_hoverpod | Vehicle | Air | 4 | +24 | 899R |
| 9 | eternity_sky_shuttle | Vehicle | Air | 10 | +18 | 1499R |
| 10 | prism_jet_solo | Vehicle | Air | 2 | +40 | 1199R |
| 11 | marina_speedboat | Vehicle | Water | 2 | +22 | 599R |
| 12 | canal_water_bus | Vehicle | Water | 10 | +12 | 999R |
| 13 | luxury_yacht_pod | Vehicle | Water | 6 | +16 | 1299R |
| 14 | void_phantom_racer | Vehicle | Personal | 1 | +50 | 50k credits |
| 15 | eternal_sky_throne | Vehicle | Air | 1 | +35 | 100k credits |
| 16 | white_timber_wolf | Mount | Ground | — | +22 | 799R |
| 17 | golden_lion_king | Mount | Ground | — | +26 | 1299R |
| 18 | celestial_white_deer | Mount | Ground | — | +20 | 999R |
| 19 | red_gold_phoenix | Mount | Flying | — | +30 | 1499R |
| 20 | white_pegasus | Mount | Flying | — | +28 | 1399R |
| 21 | prism_white_dragon | Mount | Flying | — | +35 | 150k credits |
| 22 | golden_griffin | Mount | Flying | — | +32 | 1699R |

**รวม: 15 ยานพาหนะ + 7 legendary mounts = 22 assets**

---

## Git commit

```bash
git add src/ReplicatedStorage/Modules/VehicleConfig.luau
git add src/ReplicatedStorage/Modules/MountConfig.luau
git add src/ServerScriptService/Commerce/VehicleMountService.server.luau
git add src/ServerScriptService/Commerce/VehicleMountHandlers.server.luau
git add src/StarterPlayer/StarterPlayerScripts/VehicleMountClient.client.luau
git add default.project.json
git commit -m "feat(Garage): Vehicle + Legendary Mount system

VehicleConfig: 15 vehicles (Personal/Group/Air/Water, incl. 2 credit-only Legendary)
MountConfig: 7 legendary mounts (Ground x3 / Flying x4, incl. Prism Dragon Mythic)
VehicleMountService: DataStore UtopiaVehicleMount_v1, equip/unequip, speed boost
VehicleMountHandlers: CommerceRemotes (GetVehicleMountState RF, EquipVehicle/Mount/Unequip RE)
VehicleMountClient: Garage Panel tabbed UI with owned/equipped state
Visual refs: docs/visual-ref/vehicles/ + mounts/ (white-gold Eternity City aesthetic)"
```

## รายงานกลับ

- ✅/❌ BUILD strict · commit hash
- ยืนยัน: EquipVehicle → WalkSpeed เพิ่มขึ้น (Studio output)
- ยืนยัน: placeholder model ติด HumanoidRootPart เมื่อ equip
- ยืนยัน: DataStore save/load ผ่าน pcall ไม่ crash

## ขั้นตอนถัดไปหลัง commit
1. Cursor ใส่ modelId จริงจาก Roblox catalog ใน VehicleConfig/MountConfig
2. เปลี่ยน placeholder Part → InsertService:LoadAsset(def.modelId)
3. Flying mount: ใส่ BodyVelocity + Y drift สำหรับ canFly = true
4. Group vehicle: ผู้เล่นคนอื่น FireServer เพื่อ "hitch a ride" → VehicleSeat pattern
