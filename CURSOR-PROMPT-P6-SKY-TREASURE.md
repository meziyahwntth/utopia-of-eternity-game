# CURSOR PROMPT — P6 Sky Treasure RNG Event + CombatService Fix
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก commit `c68c6da` (P5+ Mercenary/Bounty done)
> อ้างอิง: `docs/MASTER-BLUEPRINT.md` §11.3 + `docs/BLUEPRINT-V2-WORLD-PROGRESSION.md` §L3

---

## Part A — Fix: LastAttackerUserId ใน CombatService (เล็ก, ทำก่อน)

**ปัญหา:** BountyService.onTargetKilled ตรวจ `Humanoid.LastAttackerUserId` แต่ CombatService ยังไม่ set ค่านี้

**แก้ไฟล์:** `src/ServerScriptService/Combat/CombatService.luau`

ในฟังก์ชัน `processAttack` หลังจาก `npc:TakeDamage(dmg)` ให้เพิ่ม:
```lua
-- Set LastAttackerUserId เพื่อให้ BountyService claim ได้เมื่อ NPC/Player ตาย
local humanoid = npc:FindFirstChildOfClass("Humanoid")
if humanoid then
  -- ใช้ Attribute แทน (Humanoid.LastAttackerUserId เป็น read-only บน Roblox)
  humanoid:SetAttribute("LastAttackerUserId", player.UserId)
end
```

**แก้ไฟล์:** `src/ServerScriptService/Mercenary/MercenaryHandlers.server.luau`

ใน Humanoid.Died handler เปลี่ยนจาก `Humanoid.LastAttackerUserId` เป็น:
```lua
humanoid.Died:Connect(function()
  local killerId = humanoid:GetAttribute("LastAttackerUserId")
  if killerId then
    BountyService.onTargetKilled(killerId :: number, targetUserId)
  end
end)
```

---

## Part B — P6 Sky Treasure RNG Event

### บริบท
ทุก 2 ชั่วโมง → สุ่ม 3 จุดใน Eternity City → ประกาศ server-wide → ผู้เล่นวิ่งแข่งยึด 3 นาที → rare item reward

---

## ไฟล์ที่ต้องสร้าง (Part B)

| ไฟล์ | บทบาท | Path |
|------|------|------|
| `SkyTreasureConfig.luau` | spawn points, rewards pool, interval, defend duration | `ReplicatedStorage/Modules/` |
| `CurrencyService.luau` | addCredits / deductCredits / getBalance (DataStore) | `ServerScriptService/Commerce/` |
| `SkyTreasureService.luau` | cron every 2hr, spawn chest, countdown, claim reward | `ServerScriptService/LiveOps/` |
| `SkyTreasureHandlers.server.luau` | wire remotes → SkyTreasureService | `ServerScriptService/LiveOps/` |
| `SkyTreasureClient.client.luau` | server announcement banner + minimap marker + 3min timer | `StarterPlayerScripts/` |

---

## 1. SkyTreasureConfig.luau

```lua
--!strict
-- ReplicatedStorage/Modules/SkyTreasureConfig.luau

return {
  IntervalSeconds  = 7200,   -- 2 ชั่วโมง
  DefendSeconds    = 180,    -- 3 นาที defend
  ChestsPerEvent   = 3,      -- จำนวนกล่องต่อรอบ
  ClaimRadius      = 20,     -- studs: รัศมียึดกล่อง

  -- จุด spawn ใน Eternity City (ปรับตาม landmark จริง)
  SpawnPoints = {
    { id = "marina_dock",    position = Vector3.new(120, 2010, -80),  displayName = "Marina Dock"     },
    { id = "aurora_plaza",   position = Vector3.new(-40, 2010, 200),  displayName = "Aurora Plaza"    },
    { id = "canal_bridge",   position = Vector3.new(60,  2010, 350),  displayName = "Canal Bridge"    },
    { id = "sky_rail_north", position = Vector3.new(-200, 2010, 0),   displayName = "Sky Rail North"  },
    { id = "market_square",  position = Vector3.new(0,   2010, -200), displayName = "Market Square"   },
  },

  -- Reward pool (สุ่ม 1 รายการต่อกล่อง)
  Rewards = {
    { type = "credits",  amount = 5000,  weight = 40, label = "💰 5,000 Credits"    },
    { type = "credits",  amount = 20000, weight = 20, label = "💰 20,000 Credits"   },
    { type = "item",     itemId = "GrandeurFragment", weight = 25, label = "✨ Grandeur Fragment" },
    { type = "item",     itemId = "RareKeyBundle",    weight = 10, label = "🔑 Rare Key Bundle"   },
    { type = "item",     itemId = "LuckyGoldCoin",    weight = 5,  label = "🪙 Lucky Gold Coin"   },
  },
}
```

---

## 2. CurrencyService.luau

```lua
--!strict
-- ServerScriptService/Commerce/CurrencyService.luau
-- TODO placeholder ใน P5+ ตอนนี้ implement จริง

local DataStoreService = game:GetService("DataStoreService")
local ds = DataStoreService:GetDataStore("UtopiaCredits_v1")

local CurrencyService = {}

function CurrencyService.getBalance(userId: number): number
  local ok, result = pcall(function()
    return ds:GetAsync("credits_" .. userId)
  end)
  return (ok and result) and result :: number or 0
end

function CurrencyService.addCredits(userId: number, amount: number): boolean
  local ok, err = pcall(function()
    ds:UpdateAsync("credits_" .. userId, function(current)
      return (current or 0) + math.max(0, amount)
    end)
  end)
  if not ok then warn("[CurrencyService] addCredits failed:", err) end
  return ok
end

function CurrencyService.deductCredits(userId: number, amount: number): (boolean, string)
  local success = false
  local msg = ""
  local ok, err = pcall(function()
    ds:UpdateAsync("credits_" .. userId, function(current)
      local balance = current or 0
      if balance < amount then
        msg = string.format("ยอดไม่พอ (มี %d, ต้อง %d)", balance, amount)
        return nil  -- abort UpdateAsync
      end
      success = true
      return balance - amount
    end)
  end)
  if not ok then return false, tostring(err) end
  return success, msg
end

return CurrencyService
```

---

## 3. SkyTreasureService.luau

```lua
--!strict
-- ServerScriptService/LiveOps/SkyTreasureService.luau

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService  = game:GetService("MessagingService")
local SkyTreasureConfig = require(ReplicatedStorage.Modules.SkyTreasureConfig)
local CurrencyService   = require(script.Parent.Parent.Commerce.CurrencyService)

type ChestSession = {
  id         : string,
  spawnPoint : { id: string, position: Vector3, displayName: string },
  reward     : { type: string, amount: number?, itemId: string?, label: string },
  startsAt   : number,
  endsAt     : number,
  claimedBy  : number?,
  model      : Model?,
}

local activeChests: { [string]: ChestSession } = {}
local remotes: Folder

local SkyTreasureService = {}

-- Weighted random reward
local function pickReward()
  local pool = SkyTreasureConfig.Rewards
  local totalWeight = 0
  for _, r in pool do totalWeight += r.weight end
  local roll = math.random(1, totalWeight)
  local cumulative = 0
  for _, r in pool do
    cumulative += r.weight
    if roll <= cumulative then return r end
  end
  return pool[1]
end

-- สุ่มจุด spawn (ไม่ซ้ำกัน)
local function pickSpawnPoints(count: number)
  local pool = {}
  for _, pt in SkyTreasureConfig.SpawnPoints do
    table.insert(pool, pt)
  end
  -- Fisher-Yates shuffle
  for i = #pool, 2, -1 do
    local j = math.random(1, i)
    pool[i], pool[j] = pool[j], pool[i]
  end
  local result = {}
  for i = 1, math.min(count, #pool) do
    table.insert(result, pool[i])
  end
  return result
end

-- สร้าง chest model ใน workspace
local function spawnChestModel(position: Vector3): Model
  local model = Instance.new("Model")
  model.Name = "SkyTreasureChest"
  local part = Instance.new("Part")
  part.Size     = Vector3.new(4, 4, 4)
  part.Position = position
  part.Anchored = true
  part.BrickColor = BrickColor.new("Bright yellow")
  part.Material = Enum.Material.SmoothPlastic
  part.Name = "ChestPart"
  part.Parent = model
  -- glow
  local light = Instance.new("PointLight")
  light.Brightness = 5
  light.Color = Color3.fromRGB(255, 220, 80)
  light.Range = 30
  light.Parent = part

  model.PrimaryPart = part
  model.Parent = workspace
  return model
end

-- เริ่ม event รอบใหม่
function SkyTreasureService.startEvent()
  local now = os.time()
  local chosen = pickSpawnPoints(SkyTreasureConfig.ChestsPerEvent)

  -- แจ้ง client ทุกคน
  if remotes then
    local announce = remotes:FindFirstChild("SkyTreasureAnnounce") :: RemoteEvent?
    if announce then
      local zoneNames = {}
      for _, pt in chosen do table.insert(zoneNames, pt.displayName) end
      announce:FireAllClients(zoneNames, now + SkyTreasureConfig.DefendSeconds)
    end
  end

  for i, spawnPt in chosen do
    local reward = pickReward()
    local chestId = string.format("chest_%d_%d", now, i)
    local model = spawnChestModel(spawnPt.position)

    local session: ChestSession = {
      id         = chestId,
      spawnPoint = spawnPt,
      reward     = reward,
      startsAt   = now,
      endsAt     = now + SkyTreasureConfig.DefendSeconds,
      claimedBy  = nil,
      model      = model,
    }
    activeChests[chestId] = session

    -- auto-despawn หลัง DefendSeconds
    task.delay(SkyTreasureConfig.DefendSeconds, function()
      if activeChests[chestId] and not activeChests[chestId].claimedBy then
        if model and model.Parent then model:Destroy() end
        activeChests[chestId] = nil
        print(string.format("[SkyTreasure] %s expired unclaimed", chestId))
      end
    end)
  end
end

-- ผู้เล่นยึดกล่อง
function SkyTreasureService.claimChest(player: Player, chestId: string): (boolean, string)
  local session = activeChests[chestId]
  if not session then return false, "กล่องไม่มีอยู่" end
  if session.claimedBy then return false, "ถูกยึดไปแล้ว" end
  if os.time() > session.endsAt then return false, "หมดเวลา" end

  -- ตรวจระยะ
  local char = player.Character
  if not char then return false, "ไม่พบตัวละคร" end
  local chestPart = session.model and session.model:FindFirstChild("ChestPart") :: BasePart?
  if chestPart then
    local dist = (char.HumanoidRootPart.Position - chestPart.Position).Magnitude
    if dist > SkyTreasureConfig.ClaimRadius then
      return false, string.format("ห่างเกิน %d studs", SkyTreasureConfig.ClaimRadius)
    end
  end

  session.claimedBy = player.UserId
  if session.model and session.model.Parent then
    session.model:Destroy()
  end
  activeChests[chestId] = nil

  -- ให้ reward
  local reward = session.reward
  if reward.type == "credits" and reward.amount then
    CurrencyService.addCredits(player.UserId, reward.amount)
  elseif reward.type == "item" and reward.itemId then
    -- TODO: ItemService.grantItem(player, reward.itemId)
    print(string.format("[SkyTreasure] grant item %s to %s", reward.itemId, player.Name))
  end

  -- แจ้ง client ทุกคน
  if remotes then
    local claimed = remotes:FindFirstChild("SkyTreasureClaimed") :: RemoteEvent?
    if claimed then
      claimed:FireAllClients(player.Name, session.spawnPoint.displayName, reward.label)
    end
  end

  return true, string.format("🎁 %s", reward.label)
end

-- scheduler loop
function SkyTreasureService.init(remotesFolder: Folder)
  remotes = remotesFolder
  local function scheduleNext()
    task.delay(SkyTreasureConfig.IntervalSeconds, function()
      SkyTreasureService.startEvent()
      scheduleNext()
    end)
  end
  scheduleNext()
  print(string.format("[SkyTreasure] initialized — next event in %ds",
    SkyTreasureConfig.IntervalSeconds))
end

return SkyTreasureService
```

---

## 4. SkyTreasureHandlers.server.luau

```lua
--!strict
-- ServerScriptService/LiveOps/SkyTreasureHandlers.server.luau

local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local SkyTreasureService   = require(script.Parent.SkyTreasureService)

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local function ensure(className: string, name: string): Instance
  local existing = remotes:FindFirstChild(name)
  if existing then return existing end
  local inst = Instance.new(className)
  inst.Name   = name
  inst.Parent = remotes
  return inst
end

ensure("RemoteEvent",   "SkyTreasureAnnounce")  -- Server→All: zoneNames[], endsAt
ensure("RemoteEvent",   "SkyTreasureClaimed")   -- Server→All: winnerName, zoneName, rewardLabel
ensure("RemoteFunction","ClaimChest")           -- Client→Server: chestId → (bool, msg)

local claimChest = remotes:WaitForChild("ClaimChest") :: RemoteFunction
claimChest.OnServerInvoke = function(player, chestId)
  return SkyTreasureService.claimChest(player, chestId :: string)
end

SkyTreasureService.init(remotes)
```

---

## 5. SkyTreasureClient.client.luau

```lua
--!strict
-- StarterPlayerScripts/SkyTreasureClient.client.luau

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local remotes       = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local announce      = remotes:WaitForChild("SkyTreasureAnnounce")  :: RemoteEvent
local claimed       = remotes:WaitForChild("SkyTreasureClaimed")   :: RemoteEvent
local claimChestRF  = remotes:WaitForChild("ClaimChest")           :: RemoteFunction

-- Announcement banner (top-center, Scale-based)
local screenGui = Instance.new("ScreenGui")
screenGui.Name          = "SkyTreasureHUD"
screenGui.ResetOnSpawn  = false
screenGui.ZIndexBehavior= Enum.ZIndexBehavior.Sibling
screenGui.Parent        = Players.LocalPlayer.PlayerGui

local banner = Instance.new("Frame")
banner.Size             = UDim2.fromScale(0.6, 0.1)
banner.Position         = UDim2.fromScale(0.2, -0.12)  -- เริ่มนอกจอ
banner.BackgroundColor3 = Color3.fromRGB(180, 140, 20)
banner.BackgroundTransparency = 0.1
banner.BorderSizePixel  = 0
banner.Parent           = screenGui

local bannerText = Instance.new("TextLabel")
bannerText.Size         = UDim2.fromScale(1, 0.6)
bannerText.Position     = UDim2.fromScale(0, 0)
bannerText.BackgroundTransparency = 1
bannerText.TextColor3   = Color3.new(1,1,1)
bannerText.TextScaled   = true
bannerText.Font         = Enum.Font.GothamBold
bannerText.Text         = ""
bannerText.Parent       = banner

local timerText = Instance.new("TextLabel")
timerText.Size          = UDim2.fromScale(1, 0.4)
timerText.Position      = UDim2.fromScale(0, 0.6)
timerText.BackgroundTransparency = 1
timerText.TextColor3    = Color3.fromRGB(255, 240, 160)
timerText.TextScaled    = true
timerText.Text          = ""
timerText.Parent        = banner

local function showBanner(text: string)
  bannerText.Text = text
  -- slide in
  TweenService:Create(banner, TweenInfo.new(0.4), {
    Position = UDim2.fromScale(0.2, 0.02)
  }):Play()
  -- slide out หลัง 8 วินาที
  task.delay(8, function()
    TweenService:Create(banner, TweenInfo.new(0.4), {
      Position = UDim2.fromScale(0.2, -0.12)
    }):Play()
  end)
end

local chestEndsAt: number? = nil

game:GetService("RunService").Heartbeat:Connect(function()
  if chestEndsAt then
    local remaining = math.max(0, chestEndsAt - os.time())
    timerText.Text = string.format("⏱ %d:%02d", math.floor(remaining/60), remaining%60)
    if remaining == 0 then
      chestEndsAt = nil
      timerText.Text = ""
    end
  end
end)

announce:Connect(function(zoneNames, endsAt)
  chestEndsAt = endsAt :: number
  local zones = table.concat(zoneNames :: { string }, " · ")
  showBanner(string.format("🎁 กล่องสมบัติลอยฟ้าตกที่ %s!", zones))
end)

claimed:Connect(function(winnerName, zoneName, rewardLabel)
  chestEndsAt = nil
  timerText.Text = ""
  showBanner(string.format("🏆 %s ยึด %s ได้ %s!", winnerName, zoneName, rewardLabel))
end)

-- ตรวจ chest ใกล้ด้วย ProximityPrompt (ใส่ใน chest model ฝั่ง server)
-- เมื่อผู้เล่นกด Prompt → ClaimChest:InvokeServer(chestId)
-- (Server จะ attach ProximityPrompt ไว้ใน spawnChestModel แล้ว wire ผ่าน SkyTreasureHandlers)
```

---

## 6. default.project.json — เพิ่ม LiveOps/ + Commerce/CurrencyService

```json
"LiveOps": {
  "$className": "Folder",
  "SkyTreasureService": { "$path": "src/ServerScriptService/LiveOps/SkyTreasureService.luau" },
  "SkyTreasureHandlers": { "$path": "src/ServerScriptService/LiveOps/SkyTreasureHandlers.server.luau" }
},
```
ใน Commerce/ เพิ่ม:
```json
"CurrencyService": { "$path": "src/ServerScriptService/Commerce/CurrencyService.luau" }
```
ใน Modules/ เพิ่ม:
```json
"SkyTreasureConfig": { "$path": "src/ReplicatedStorage/Modules/SkyTreasureConfig.luau" }
```
ใน StarterPlayerScripts เพิ่ม:
```json
"SkyTreasureClient": { "$path": "src/StarterPlayer/StarterPlayerScripts/SkyTreasureClient.client.luau" }
```

---

## สิ่งที่รู้ล่วงหน้า

| ประเด็น | วิธีแก้ |
|---------|---------|
| `Humanoid:SetAttribute` เป็น string key | ใช้ `"LastAttackerUserId"` ให้ตรงกับ MercenaryHandlers |
| `session.model` อาจ nil ก่อน destroy | มี guard `if model and model.Parent then` แล้ว |
| `SkyTreasureConfig.SpawnPoints` positions | ปรับ Y ให้ตรงกับ `SkyAltitude` จริงของ EternityCity (ประมาณ +2000) |
| ProximityPrompt บน chest | เพิ่มใน `spawnChestModel()`: `local pp = Instance.new("ProximityPrompt"); pp.ActionText="ยึดกล่อง"; pp.Parent=part` แล้ว wire `.Triggered` → `ClaimChest:InvokeServer(chestId)` ฝั่ง client |
| ItemService.grantItem | ยัง TODO — log ไปก่อน (P7) |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-p6.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ReplicatedStorage/Modules/SkyTreasureConfig.luau \
  src/ServerScriptService/Commerce/CurrencyService.luau \
  src/ServerScriptService/LiveOps/SkyTreasureService.luau \
  src/ServerScriptService/LiveOps/SkyTreasureHandlers.server.luau \
  src/StarterPlayer/StarterPlayerScripts/SkyTreasureClient.client.luau \
  src/ServerScriptService/Combat/CombatService.luau \
  src/ServerScriptService/Mercenary/MercenaryHandlers.server.luau
```

## Git commit (ถ้า clean)

```bash
git add -A
git commit -m "feat(P6): Sky Treasure RNG Event + CurrencyService + Bounty kill fix

- SkyTreasureConfig: 5 spawn points, 5-reward pool (weighted), 2hr interval
- SkyTreasureService: weighted random reward, chest spawn/despawn, 3min claim
- SkyTreasureClient: slide-in banner + countdown timer
- CurrencyService: DataStore credits (addCredits/deductCredits/getBalance)
- Fix: CombatService sets LastAttackerUserId attribute for bounty kill chain
- Fix: MercenaryHandlers reads attribute instead of Humanoid property"
```

## รายงานกลับ
- ✅/❌ BUILD
- ✅/❌ STRICT CLEAN (error+line)
- commit hash
