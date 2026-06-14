# CURSOR PROMPT — P5 Clan War System
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก commit `b0856c4` (P4 Economy Core done)
> อ้างอิง: `docs/MASTER-BLUEPRINT.md` §11.2 + `docs/BLUEPRINT-V2-WORLD-PROGRESSION.md` §K

---

## บริบท

Clan/Guild ทำงานได้แล้ว (P3-B commit `2bb5128`) — มี GuildService, GuildStore, GuildClient
P4 Economy ทำงานได้แล้ว — มี TradingService, WeightService, ItemTierConfig
P5 ต้องการระบบ **ชิงเขต (Territory Siege)** + **เก็บภาษีแบบแบ่งสัดส่วน** + **Fort HP decay รายสัปดาห์**

---

## ไฟล์ที่ต้องสร้าง

| ไฟล์ | บทบาท | Path |
|------|------|------|
| `ClanWarConfig.luau` | ค่ากลาง: ตาราง maintenance, war schedule, fatigue rate, tax split | `ReplicatedStorage/Modules/` |
| `TerritoryStore.luau` | DataStore wrapper สำหรับ TerritoryData (pcall ครบทุก call) | `ServerScriptService/ClanWar/` |
| `ClanVaultStore.luau` | DataStore wrapper สำหรับ ClanVaultData | `ServerScriptService/ClanWar/` |
| `TaxDistributionService.luau` | รับ tax event → แบ่ง 50/30/20 → save stores | `ServerScriptService/ClanWar/` |
| `DefensiveFatigueService.luau` | weekly timer: ลด fortHp -5% ของ territory ที่มีเจ้าของ | `ServerScriptService/ClanWar/` |
| `ClanWarService.luau` | war scheduling, zone capture logic, winner determination | `ServerScriptService/ClanWar/` |
| `ClanWarHandlers.server.luau` | wire remotes → ClanWarService | `ServerScriptService/ClanWar/` |
| `ClanWarClient.client.luau` | zone status HUD, war countdown, Fort HP bar | `StarterPlayerScripts/` |

---

## 1. ClanWarConfig.luau

```lua
--!strict
-- ReplicatedStorage/Modules/ClanWarConfig.luau

return {
  -- Tax split ratios (must sum to 1.0)
  TaxSplit = {
    ClanVault   = 0.50,
    MemberShare = 0.30,
    ServerBuff  = 0.20,
  },

  -- Maintenance cost multiplier per tax rate (1–5%)
  MaintenanceMultiplier = {
    [1] = 1.0,
    [2] = 1.5,
    [3] = 2.5,
    [4] = 4.0,
    [5] = 6.5,
  },
  BaseMaintenanceCost = 100,  -- credits per week

  -- Defensive Fatigue
  FortHpDecayPerWeek = 5,     -- percent per week
  FortHpMinimum      = 40,    -- floor (never goes below this from decay alone)
  FortHpMax          = 100,

  -- War schedule (UTC+7 Thai time → UTC)
  WarDayOfWeek    = 7,        -- Saturday (os.date %w: 0=Sun … 6=Sat → ใช้ 6)
  WarStartHourUTC = 13,       -- 20:00 Thai = 13:00 UTC
  WarDurationSecs = 45 * 60,  -- 45 minutes

  -- Zones available for capture (เริ่ม 3 zones)
  Zones = {
    { id = "marina",   displayName = "Marina District" },
    { id = "aurora",   displayName = "Aurora Spire"   },
    { id = "canal",    displayName = "Canal Promenade" },
  },

  -- Minimum clan level to register for war
  MinClanLevelForWar = 3,

  -- Server Buff duration after tax distribution
  ServerBuffDurationDays = 7,
  ServerBuffDropRateBonus = 0.05,  -- +5% drop rate
}
```

---

## 2. TerritoryStore.luau

```lua
--!strict
-- ServerScriptService/ClanWar/TerritoryStore.luau

local DataStoreService = game:GetService("DataStoreService")
local ds = DataStoreService:GetDataStore("UtopiaTerritory_v1")

export type MemberDividends = { [string]: number }

export type TerritoryData = {
  ownerClanId     : string,
  taxRate         : number,           -- 1..5
  maintenanceCost : number,
  fortHp          : number,           -- 0..100
  weeksClaimed    : number,
  lastWarCycleId  : string,
  clanVaultBalance: number,
  memberDividends : MemberDividends,
  serverBuffActive: boolean,
  lastDistributedAt: number,
}

local function defaultTerritory(zoneId: string): TerritoryData
  return {
    ownerClanId      = "",
    taxRate          = 1,
    maintenanceCost  = 100,
    fortHp           = 100,
    weeksClaimed     = 0,
    lastWarCycleId   = "",
    clanVaultBalance = 0,
    memberDividends  = {},
    serverBuffActive = false,
    lastDistributedAt= os.time(),
  }
end

local TerritoryStore = {}

function TerritoryStore.get(zoneId: string): TerritoryData
  local ok, result = pcall(function()
    return ds:GetAsync("territory_" .. zoneId)
  end)
  if ok and result then
    return result :: TerritoryData
  end
  return defaultTerritory(zoneId)
end

function TerritoryStore.save(zoneId: string, data: TerritoryData)
  local ok, err = pcall(function()
    ds:SetAsync("territory_" .. zoneId, data)
  end)
  if not ok then
    warn("[TerritoryStore] save failed:", err)
  end
end

return TerritoryStore
```

---

## 3. ClanVaultStore.luau

```lua
--!strict
-- ServerScriptService/ClanWar/ClanVaultStore.luau

local DataStoreService = game:GetService("DataStoreService")
local ds = DataStoreService:GetDataStore("UtopiaVault_v1")

export type ClanVaultData = {
  balance          : number,
  npcGuardSlots    : number,
  barrierLevel     : number,
  lastWithdrawnBy  : string,
  lastUpdatedAt    : number,
}

local function defaultVault(): ClanVaultData
  return {
    balance        = 0,
    npcGuardSlots  = 0,
    barrierLevel   = 1,
    lastWithdrawnBy= "",
    lastUpdatedAt  = os.time(),
  }
end

local ClanVaultStore = {}

function ClanVaultStore.get(clanId: string): ClanVaultData
  local ok, result = pcall(function()
    return ds:GetAsync("vault_" .. clanId)
  end)
  if ok and result then return result :: ClanVaultData end
  return defaultVault()
end

function ClanVaultStore.save(clanId: string, data: ClanVaultData)
  local ok, err = pcall(function()
    ds:SetAsync("vault_" .. clanId, data)
  end)
  if not ok then warn("[ClanVaultStore] save failed:", err) end
end

function ClanVaultStore.deposit(clanId: string, amount: number)
  local vault = ClanVaultStore.get(clanId)
  vault.balance += amount
  vault.lastUpdatedAt = os.time()
  ClanVaultStore.save(clanId, vault)
end

return ClanVaultStore
```

---

## 4. TaxDistributionService.luau

```lua
--!strict
-- ServerScriptService/ClanWar/TaxDistributionService.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuildService = require(script.Parent.Parent.Social.GuildService)
local TerritoryStore = require(script.Parent.TerritoryStore)
local ClanVaultStore = require(script.Parent.ClanVaultStore)
local ClanWarConfig  = require(ReplicatedStorage.Modules.ClanWarConfig)

local TaxDistributionService = {}

-- เรียกจาก ShopRentalService / TradingService เมื่อมีรายการจ่ายภาษีในเขต
function TaxDistributionService.onTaxCollected(zoneId: string, amount: number)
  local territory = TerritoryStore.get(zoneId)
  if territory.ownerClanId == "" then return end  -- ไม่มีเจ้าของ

  local split = ClanWarConfig.TaxSplit
  local vaultAmt  = math.floor(amount * split.ClanVault)
  local memberAmt = amount * split.MemberShare
  local buffAmt   = amount * split.ServerBuff  -- ใช้แค่ track (buff apply แยก)

  -- 50% → Clan Vault
  ClanVaultStore.deposit(territory.ownerClanId, vaultAmt)

  -- 30% → แบ่งให้สมาชิกระดับ Veteran+
  local guild = GuildService.getById(territory.ownerClanId)
  if guild then
    local eligibleMembers: { string } = {}
    for userId, rank in guild.members do
      if rank == "Leader" or rank == "Officer" or rank == "Veteran" then
        table.insert(eligibleMembers, userId)
      end
    end
    if #eligibleMembers > 0 then
      local share = math.floor(memberAmt / #eligibleMembers)
      for _, userId in eligibleMembers do
        territory.memberDividends[userId] =
          (territory.memberDividends[userId] or 0) + share
      end
    end
  end

  -- 20% → Server Buff (mark active; ClanWarService applies buff on game loop)
  territory.serverBuffActive = true
  territory.lastDistributedAt = os.time()
  TerritoryStore.save(zoneId, territory)
end

-- ผู้เล่น claim เงินปันผลของตัวเอง
function TaxDistributionService.claimDividend(player: Player, zoneId: string): number
  local territory = TerritoryStore.get(zoneId)
  local uid = tostring(player.UserId)
  local amount = territory.memberDividends[uid] or 0
  if amount > 0 then
    territory.memberDividends[uid] = 0
    TerritoryStore.save(zoneId, territory)
    -- TODO: เพิ่มเครดิตให้ผู้เล่น (ต่อ CurrencyService)
  end
  return amount
end

return TaxDistributionService
```

---

## 5. DefensiveFatigueService.luau

```lua
--!strict
-- ServerScriptService/ClanWar/DefensiveFatigueService.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TerritoryStore = require(script.Parent.TerritoryStore)
local ClanWarConfig  = require(ReplicatedStorage.Modules.ClanWarConfig)

local WEEK_SECONDS  = 7 * 24 * 60 * 60
local DefensiveFatigueService = {}

-- เรียกตอน server start + ทุกสัปดาห์
function DefensiveFatigueService.runDecay()
  for _, zone in ClanWarConfig.Zones do
    local territory = TerritoryStore.get(zone.id)
    if territory.ownerClanId ~= "" then
      local newHp = math.max(
        ClanWarConfig.FortHpMinimum,
        territory.fortHp - ClanWarConfig.FortHpDecayPerWeek
      )
      territory.fortHp = newHp
      territory.weeksClaimed += 1
      TerritoryStore.save(zone.id, territory)
      print(string.format("[DefensiveFatigue] %s: fortHp → %d (week %d)",
        zone.id, newHp, territory.weeksClaimed))
    end
  end
end

-- เรียก loop ทุกสัปดาห์ (ใช้ task.delay ไม่ใช่ while true wait)
function DefensiveFatigueService.init()
  -- รัน decay ครั้งแรก delay 7 วัน
  local function scheduleNext()
    task.delay(WEEK_SECONDS, function()
      DefensiveFatigueService.runDecay()
      scheduleNext()
    end)
  end
  scheduleNext()
end

return DefensiveFatigueService
```

---

## 6. ClanWarService.luau (โครงสร้างหลัก)

```lua
--!strict
-- ServerScriptService/ClanWar/ClanWarService.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TerritoryStore = require(script.Parent.TerritoryStore)
local DefensiveFatigueService = require(script.Parent.DefensiveFatigueService)
local ClanWarConfig  = require(ReplicatedStorage.Modules.ClanWarConfig)
local GuildService   = require(script.Parent.Parent.Social.GuildService)

type WarSession = {
  zoneId    : string,
  startedAt : number,
  endsAt    : number,
  attackers : { [string]: number },  -- {clanId: score}
  defender  : string,               -- ownerClanId
  active    : boolean,
}

local activeSessions: { [string]: WarSession } = {}
local remotes: Folder

local ClanWarService = {}

-- ลงทะเบียนแคลนเข้าร่วมสงคราม
function ClanWarService.registerClan(player: Player, zoneId: string): (boolean, string)
  local guild = GuildService.getByPlayer(player)
  if not guild then return false, "ไม่ได้อยู่ในแคลน" end
  if guild.level < ClanWarConfig.MinClanLevelForWar then
    return false, string.format("แคลนต้องระดับ %d+ (ปัจจุบัน %d)",
      ClanWarConfig.MinClanLevelForWar, guild.level)
  end
  local session = activeSessions[zoneId]
  if not session or not session.active then
    return false, "สงครามยังไม่เริ่ม"
  end
  session.attackers[guild.id] = session.attackers[guild.id] or 0
  return true, "ลงทะเบียนสำเร็จ"
end

-- เพิ่มคะแนนให้แคลน (เรียกจาก combat / objective capture)
function ClanWarService.addScore(clanId: string, zoneId: string, points: number)
  local session = activeSessions[zoneId]
  if not session or not session.active then return end
  session.attackers[clanId] = (session.attackers[clanId] or 0) + points
end

-- สิ้นสุดสงคราม → หาผู้ชนะ → อัปเดต territory
local function endWar(zoneId: string)
  local session = activeSessions[zoneId]
  if not session then return end
  session.active = false

  -- หาแคลนที่มีคะแนนสูงสุด
  local winnerId = session.defender
  local topScore = 0
  for clanId, score in session.attackers do
    if score > topScore then
      topScore = score
      winnerId = clanId
    end
  end

  -- อัปเดต territory
  local territory = TerritoryStore.get(zoneId)
  if winnerId ~= territory.ownerClanId then
    -- เจ้าของเปลี่ยน → รีเซ็ต Fort HP, weeksClaimed
    territory.ownerClanId  = winnerId
    territory.fortHp       = ClanWarConfig.FortHpMax
    territory.weeksClaimed = 0
  end
  territory.lastWarCycleId = tostring(os.time())
  TerritoryStore.save(zoneId, territory)

  -- แจ้ง client ทุกคน
  if remotes then
    local warResult = remotes:FindFirstChild("WarResult") :: RemoteEvent?
    if warResult then
      warResult:FireAllClients(zoneId, winnerId)
    end
  end

  activeSessions[zoneId] = nil
  print(string.format("[ClanWar] %s ended — winner: %s", zoneId, winnerId))
end

-- เริ่มสงคราม
function ClanWarService.startWar(zoneId: string)
  if activeSessions[zoneId] then return end
  local territory = TerritoryStore.get(zoneId)
  local session: WarSession = {
    zoneId    = zoneId,
    startedAt = os.time(),
    endsAt    = os.time() + ClanWarConfig.WarDurationSecs,
    attackers = {},
    defender  = territory.ownerClanId,
    active    = true,
  }
  activeSessions[zoneId] = session

  if remotes then
    local warStarted = remotes:FindFirstChild("WarStarted") :: RemoteEvent?
    if warStarted then warStarted:FireAllClients(zoneId, session.endsAt) end
  end

  -- auto-end หลัง 45 นาที
  task.delay(ClanWarConfig.WarDurationSecs, function()
    endWar(zoneId)
  end)
end

function ClanWarService.init(remotesFolder: Folder)
  remotes = remotesFolder
  DefensiveFatigueService.init()
end

return ClanWarService
```

---

## 7. ClanWarHandlers.server.luau

```lua
--!strict
-- ServerScriptService/ClanWar/ClanWarHandlers.server.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClanWarService = require(script.Parent.ClanWarService)

local remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
ClanWarService.init(remotes)

-- ลงทะเบียนเข้าร่วมสงคราม
local warRegister = remotes:WaitForChild("WarRegister") :: RemoteFunction
warRegister.OnServerInvoke = function(player, zoneId)
  return ClanWarService.registerClan(player, zoneId :: string)
end
```

---

## 8. SocialRemoteSetup — เพิ่ม Clan War remotes

เพิ่มต่อท้ายไฟล์ `SocialRemoteSetup.server.luau`:
```lua
-- Clan War remotes (P5)
ensure("RemoteFunction", "WarRegister")        -- Client ลงทะเบียน
ensure("RemoteEvent",   "WarStarted")          -- Server แจ้งเริ่ม war (zoneId, endsAt)
ensure("RemoteEvent",   "WarResult")           -- Server แจ้งผล (zoneId, winnerId)
ensure("RemoteEvent",   "TerritoryUpdate")     -- Server แจ้ง territory เปลี่ยน (HUD)
ensure("RemoteFunction","ClaimDividend")       -- Client ขอรับเงินปันผล
ensure("RemoteFunction","SetTaxRate")          -- Leader ตั้งอัตราภาษี
ensure("RemoteFunction","GetTerritoryStatus")  -- Client ดูสถานะ territory
```

---

## 9. ClanWarClient.client.luau (โครงสร้างหลัก)

```lua
--!strict
-- StarterPlayerScripts/ClanWarClient.client.luau
-- HUD: zone status, war countdown timer, Fort HP bar

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local warStarted    = remotes:WaitForChild("WarStarted")    :: RemoteEvent
local warResult     = remotes:WaitForChild("WarResult")     :: RemoteEvent
local territoryUpdate = remotes:WaitForChild("TerritoryUpdate") :: RemoteEvent

-- สร้าง HUD (Scale-based)
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "ClanWarHUD"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = Players.LocalPlayer.PlayerGui

-- Zone status label (top-left)
local zoneLabel = Instance.new("TextLabel")
zoneLabel.Size            = UDim2.fromScale(0.3, 0.05)
zoneLabel.Position        = UDim2.fromScale(0.01, 0.01)
zoneLabel.BackgroundTransparency = 0.4
zoneLabel.BackgroundColor3= Color3.fromRGB(20, 20, 40)
zoneLabel.TextColor3      = Color3.new(1,1,1)
zoneLabel.TextScaled      = true
zoneLabel.Text            = "Territory: —"
zoneLabel.Parent          = screenGui

-- War countdown (แสดงเมื่อ war active)
local countdownLabel = Instance.new("TextLabel")
countdownLabel.Size     = UDim2.fromScale(0.2, 0.06)
countdownLabel.Position = UDim2.fromScale(0.4, 0.01)
countdownLabel.BackgroundTransparency = 0.3
countdownLabel.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
countdownLabel.TextColor3 = Color3.new(1,1,1)
countdownLabel.TextScaled = true
countdownLabel.Text     = ""
countdownLabel.Visible  = false
countdownLabel.Parent   = screenGui

-- Countdown loop
local warEndsAt: number? = nil
game:GetService("RunService").Heartbeat:Connect(function()
  if warEndsAt then
    local remaining = math.max(0, warEndsAt - os.time())
    local m = math.floor(remaining / 60)
    local s = remaining % 60
    countdownLabel.Text = string.format("⚔ War: %02d:%02d", m, s)
    if remaining == 0 then
      warEndsAt = nil
      countdownLabel.Visible = false
    end
  end
end)

warStarted:Connect(function(zoneId, endsAt)
  warEndsAt = endsAt :: number
  countdownLabel.Visible = true
  zoneLabel.Text = "⚔ WAR: " .. tostring(zoneId)
end)

warResult:Connect(function(zoneId, winnerId)
  countdownLabel.Visible = false
  zoneLabel.Text = string.format("🏆 %s → %s", tostring(zoneId), tostring(winnerId))
end)

territoryUpdate:Connect(function(zoneId, ownerName, taxRate)
  zoneLabel.Text = string.format("🏛 %s | %s | Tax %d%%",
    tostring(zoneId), tostring(ownerName), taxRate :: number)
end)
```

---

## 10. default.project.json — เพิ่ม ClanWar folder

เพิ่มใน `ServerScriptService` section:
```json
"ClanWar": {
  "$className": "Folder",
  "ClanWarConfig": { "$path": "src/ReplicatedStorage/Modules/ClanWarConfig.luau" },
  "TerritoryStore": { "$path": "src/ServerScriptService/ClanWar/TerritoryStore.luau" },
  "ClanVaultStore": { "$path": "src/ServerScriptService/ClanWar/ClanVaultStore.luau" },
  "TaxDistributionService": { "$path": "src/ServerScriptService/ClanWar/TaxDistributionService.luau" },
  "DefensiveFatigueService": { "$path": "src/ServerScriptService/ClanWar/DefensiveFatigueService.luau" },
  "ClanWarService": { "$path": "src/ServerScriptService/ClanWar/ClanWarService.luau" },
  "ClanWarHandlers": { "$path": "src/ServerScriptService/ClanWar/ClanWarHandlers.server.luau" }
}
```
และใน `StarterPlayerScripts`:
```json
"ClanWarClient": { "$path": "src/StarterPlayer/StarterPlayerScripts/ClanWarClient.client.luau" }
```

---

## สิ่งที่รู้ล่วงหน้า (luau-lsp อาจ flag)

| ประเด็น | วิธีแก้ |
|---------|---------|
| `GuildService.getById()` ยังไม่มี | เพิ่ม export ใน GuildService.luau: `function GuildService.getById(id: string): GuildData?` |
| `GuildService.getByPlayer()` ยังไม่มี | เพิ่ม export: `function GuildService.getByPlayer(player: Player): GuildData?` |
| `os.time()` ใน countdown | ใช้ `tick()` แทนถ้า luau-lsp complaint |
| `territory.memberDividends[uid]` nil-safety | ใช้ `or 0` pattern (แล้วในโค้ด) |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-p5.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ReplicatedStorage/Modules/ClanWarConfig.luau \
  src/ServerScriptService/ClanWar/TerritoryStore.luau \
  src/ServerScriptService/ClanWar/ClanVaultStore.luau \
  src/ServerScriptService/ClanWar/TaxDistributionService.luau \
  src/ServerScriptService/ClanWar/DefensiveFatigueService.luau \
  src/ServerScriptService/ClanWar/ClanWarService.luau \
  src/ServerScriptService/ClanWar/ClanWarHandlers.server.luau \
  src/StarterPlayer/StarterPlayerScripts/ClanWarClient.client.luau
```

## Git commit (ถ้า clean)

```bash
git add -A
git commit -m "feat(P5): Clan War territory siege + progressive tax distribution

- ClanWarConfig: tax split 50/30/20, maintenance exponential, fatigue rate
- TerritoryStore + ClanVaultStore: DataStore wrappers (pcall)
- TaxDistributionService: 50% Vault / 30% Veteran+ dividends / 20% ServerBuff
- DefensiveFatigueService: weekly Fort HP -5% decay (min 40%)
- ClanWarService: war session, score tracking, winner→territory capture
- ClanWarClient: HUD zone status + war countdown + result banner
- SocialRemoteSetup: +7 new ClanWar remotes"
```

## รายงานกลับ
- ✅/❌ BUILD
- ✅/❌ STRICT CLEAN (error+line)
- commit hash
