# CURSOR PROMPT — MVP World Boss (P5)
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก Fusion/Card/Rune
> Pattern อ้างอิง: DeathValleyWeeklyBossService.luau · CombatService.luau · NpcDropService.luau

---

## บริบท

MVP World Boss คือ boss ที่สปอว์นใน Eternity City (Workspace ปัจจุบัน) ทุก 4 ชั่วโมง
- **ทุกคนร่วมตีได้** (ไม่จำกัดปาร์ตี้)
- ติดตาม **top contributor** (ผู้ตีดีล top 3)
- MVP (อันดับ 1) ได้รับ **Grail** (ไอเทมหายาก) + Card
- ผู้เข้าร่วมทุกคนได้ XP + credits

**API ที่มีอยู่แล้ว:**
- `CombatService` — `ServerScriptService/Combat/CombatService` (มี attackNpc pattern)
- `PlayerLevelService.addExp` — `ServerScriptService/Progression/PlayerLevelService`
- `CurrencyService.addCredits` — `ServerScriptService/Commerce/CurrencyService`
- `PlayerItemStore.addItem` — `ServerScriptService/Progression/PlayerItemStore`
- `SocialRemotes` folder ใน ReplicatedStorage
- DeathValleyWeeklyBossService เป็น pattern อ้างอิง (boss HP, participants, broadcast)

---

## ไฟล์ที่ต้องสร้าง

| ไฟล์ | Action | Path |
|------|--------|------|
| `MvpBossConfig.luau` | สร้างใหม่ | `ReplicatedStorage/Modules/` |
| `MvpBossService.luau` | สร้างใหม่ | `ServerScriptService/Combat/` |
| `MvpBossHandlers.server.luau` | สร้างใหม่ | `ServerScriptService/Combat/` |
| `MvpBossHUD.client.luau` | สร้างใหม่ | `StarterPlayerScripts/` |
| `default.project.json` | แก้: +4 entries | root |

---

## 1. MvpBossConfig.luau

```lua
--!strict
-- ReplicatedStorage/Modules/MvpBossConfig.luau

export type BossReward = {
  xp         : number,
  credits    : number,
  itemId     : string?,  -- ไอเทมที่ได้ (participants ทุกคน)
  mvpItemId  : string?,  -- ไอเทมพิเศษ MVP เท่านั้น
}

export type MvpBossDef = {
  id         : string,
  nameTH     : string,
  emoji      : string,
  baseHp     : number,   -- HP ตอนไม่มีผู้เล่น
  hpPerPlayer: number,   -- HP เพิ่มต่อผู้เล่น (scale)
  damagePerHit: number,  -- ดีลต่อครั้งที่กด Attack
  spawnPos   : Vector3,  -- ตำแหน่งสปอว์นใน Eternity City
  reward     : BossReward,
}

-- Eternity City: Y floor = 2004
local FLOOR_Y = 2004

return {
  -- หมุนเวียนทุก 4 ชั่วโมง (hash จาก timestamp)
  Bosses = {
    {
      id="void_colossus", nameTH="ยักษ์ว่างเปล่า", emoji="👁️",
      baseHp=5000, hpPerPlayer=500, damagePerHit=100,
      spawnPos=Vector3.new(0, FLOOR_Y + 10, 0),
      reward={
        xp=800, credits=300,
        itemId="MagicCrystal",
        mvpItemId="CardLegendary",
      },
    },
    {
      id="storm_titan", nameTH="ไทแทนพายุ", emoji="⚡",
      baseHp=7000, hpPerPlayer=700, damagePerHit=120,
      spawnPos=Vector3.new(100, FLOOR_Y + 10, -80),
      reward={
        xp=1000, credits=400,
        itemId="CardRare",
        mvpItemId="GrailFragment",
      },
    },
    {
      id="eternal_warden", nameTH="ผู้พิทักษ์นิรันดร์", emoji="⚔️",
      baseHp=10000, hpPerPlayer=1000, damagePerHit=80,
      spawnPos=Vector3.new(-80, FLOOR_Y + 10, 100),
      reward={
        xp=1500, credits=600,
        itemId="CardRare",
        mvpItemId="EternityGrail",
      },
    },
  } :: { MvpBossDef },

  SPAWN_INTERVAL_SECONDS = 4 * 60 * 60,  -- 4 ชั่วโมง
  MVP_TOP_N              = 3,             -- top 3 contributors
}
```

---

## 2. MvpBossService.luau

Pattern จาก DeathValleyWeeklyBossService:

```lua
--!strict
-- ServerScriptService/Combat/MvpBossService.luau

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local MvpBossConfig     = require(ReplicatedStorage.Modules.MvpBossConfig)

local MvpBossService = {}

-- ======= state =======
local bossActive   = false
local currentBoss: MvpBossConfig.MvpBossDef? = nil
local bossHp       = 0
local bossMaxHp    = 0
local bossModel: Model? = nil

-- { [userId]: damage dealt }
local damageBoard: { [number]: number } = {}

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

-- ======= lazy requires =======
local function getLevelService()
  return require(game:GetService("ServerScriptService").Progression.PlayerLevelService) :: any
end
local function getCurrency()
  return require(game:GetService("ServerScriptService").Commerce.CurrencyService) :: any
end
local function getItemStore()
  return require(game:GetService("ServerScriptService").Progression.PlayerItemStore) :: any
end

-- ======= helpers =======
local function getBossDefByTime(): MvpBossConfig.MvpBossDef
  local bosses = MvpBossConfig.Bosses
  local idx = math.floor(os.time() / MvpBossConfig.SPAWN_INTERVAL_SECONDS) % #bosses + 1
  return bosses[idx]
end

local function buildPublicState(): { [string]: any }
  local boss = currentBoss or getBossDefByTime()
  local nextSpawn = MvpBossConfig.SPAWN_INTERVAL_SECONDS
    - (os.time() % MvpBossConfig.SPAWN_INTERVAL_SECONDS)
  return {
    bossActive   = bossActive,
    bossId       = boss.id,
    bossName     = boss.nameTH,
    bossEmoji    = boss.emoji,
    bossHp       = bossHp,
    bossMaxHp    = bossMaxHp,
    nextSpawnSec = nextSpawn,
  }
end

local function broadcast()
  local evName = "MvpBossStateChanged"
  local ev = remotes:FindFirstChild(evName) :: RemoteEvent?
  if ev then ev:FireAllClients(buildPublicState()) end
end

-- ======= spawn model (greybox) =======
local function spawnBossModel(boss: MvpBossConfig.MvpBossDef)
  if bossModel then bossModel:Destroy() end
  local m = Instance.new("Model")
  m.Name = "MvpBoss_" .. boss.id

  local body = Instance.new("Part")
  body.Name = "HumanoidRootPart"
  body.Size = Vector3.new(8, 12, 8)
  body.Position = boss.spawnPos
  body.Anchored = true
  body.BrickColor = BrickColor.new("Crimson")
  body.Material = Enum.Material.Neon
  body.Parent = m

  -- Boss name billboard
  local bb = Instance.new("BillboardGui")
  bb.Size = UDim2.fromOffset(200, 50)
  bb.StudsOffset = Vector3.new(0, 8, 0)
  bb.AlwaysOnTop = true
  bb.Parent = body
  local nameLabel = Instance.new("TextLabel")
  nameLabel.Size = UDim2.fromScale(1,0.6)
  nameLabel.BackgroundTransparency = 1
  nameLabel.Text = boss.emoji .. " " .. boss.nameTH
  nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
  nameLabel.Font = Enum.Font.GothamBold
  nameLabel.TextScaled = true
  nameLabel.Parent = bb
  local hpLabel = Instance.new("TextLabel")
  hpLabel.Name = "HpLabel"
  hpLabel.Size = UDim2.new(1,0,0.4,0)
  hpLabel.Position = UDim2.fromScale(0,0.6)
  hpLabel.BackgroundTransparency = 1
  hpLabel.Text = string.format("HP: %d / %d", bossHp, bossMaxHp)
  hpLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
  hpLabel.Font = Enum.Font.Gotham
  hpLabel.TextScaled = true
  hpLabel.Parent = bb

  m.PrimaryPart = body
  m.Parent = workspace
  bossModel = m
end

local function updateBossHpLabel()
  if not bossModel then return end
  local hrp = bossModel:FindFirstChild("HumanoidRootPart") :: BasePart?
  if not hrp then return end
  local bb = hrp:FindFirstChild("BillboardGui") :: BillboardGui?
  if not bb then return end
  local lbl = bb:FindFirstChild("HpLabel") :: TextLabel?
  if lbl then
    lbl.Text = string.format("HP: %d / %d", bossHp, bossMaxHp)
  end
end

-- ======= reward on defeat =======
local function grantRewards(boss: MvpBossConfig.MvpBossDef)
  -- Sort contributors by damage
  type Entry = { userId: number, dmg: number }
  local sorted: { Entry } = {}
  for uid, dmg in damageBoard do
    table.insert(sorted, { userId=uid, dmg=dmg })
  end
  table.sort(sorted, function(a, b) return a.dmg > b.dmg end)

  local lvSvc  = getLevelService()
  local curSvc = getCurrency()
  local itmSvc = getItemStore()
  local reward = boss.reward

  for rank, entry in sorted do
    local player = Players:GetPlayerByUserId(entry.userId)
    if not player then continue end

    -- ทุกคน
    lvSvc.addExp(player, reward.xp)
    curSvc.addCredits(entry.userId, reward.credits)
    if reward.itemId then
      itmSvc.addItem(entry.userId, reward.itemId, 1)
    end

    -- MVP (rank 1) ได้พิเศษ
    if rank == 1 and reward.mvpItemId then
      itmSvc.addItem(entry.userId, reward.mvpItemId, 1)
      -- แจ้ง client MVP
      local mvpEv = remotes:FindFirstChild("MvpAnnounce") :: RemoteEvent?
      if mvpEv then
        mvpEv:FireClient(player, boss.nameTH, reward.mvpItemId)
      end
    end
  end
end

-- ======= public API =======
function MvpBossService.getPublicState(): { [string]: any }
  return buildPublicState()
end

function MvpBossService.attack(player: Player): (boolean, string)
  if not bossActive or not currentBoss then
    return false, "ไม่มี boss active อยู่ตอนนี้"
  end

  local boss = currentBoss
  local dmg  = boss.damagePerHit
  bossHp = math.max(0, bossHp - dmg)

  -- บันทึก damage board
  local uid = player.UserId
  damageBoard[uid] = (damageBoard[uid] or 0) + dmg

  updateBossHpLabel()
  broadcast()

  if bossHp <= 0 then
    bossActive = false
    local defeatedBoss = currentBoss
    currentBoss = nil
    if bossModel then bossModel:Destroy(); bossModel = nil end

    if defeatedBoss then
      grantRewards(defeatedBoss)
      -- แจ้งทุกคน
      local defEv = remotes:FindFirstChild("MvpBossDefeated") :: RemoteEvent?
      if defEv then defEv:FireAllClients(defeatedBoss.nameTH) end
    end
    return true, "Boss พ่ายแล้ว!"
  end

  return true, string.format("%s — %d HP เหลือ", boss.nameTH, bossHp)
end

-- ======= spawn loop =======
local function trySpawn()
  if bossActive then return end
  local boss = getBossDefByTime()
  local playerCount = math.max(1, #Players:GetPlayers())
  bossMaxHp = boss.baseHp + boss.hpPerPlayer * playerCount
  bossHp    = bossMaxHp
  bossActive = true
  currentBoss = boss
  table.clear(damageBoard)

  spawnBossModel(boss)
  broadcast()

  -- แจ้งทุกคน
  local spawnEv = remotes:FindFirstChild("MvpBossSpawned") :: RemoteEvent?
  if spawnEv then spawnEv:FireAllClients(boss.nameTH, boss.emoji) end
  print(string.format("[MvpBoss] %s spawned — HP %d", boss.nameTH, bossMaxHp))
end

-- ตรวจทุก 60 วิ ว่าถึงเวลา spawn ใหม่ไหม
task.spawn(function()
  task.wait(10)  -- รอ boot
  while true do
    local sec = os.time() % MvpBossConfig.SPAWN_INTERVAL_SECONDS
    -- spawn เมื่อเข้าช่วงต้นของ interval (60 วิแรก)
    if sec < 60 and not bossActive then
      trySpawn()
    end
    task.wait(60)
  end
end)

return MvpBossService
```

---

## 3. MvpBossHandlers.server.luau

```lua
--!strict
-- ServerScriptService/Combat/MvpBossHandlers.server.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MvpBossService    = require(script.Parent.MvpBossService)

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

ensure("RemoteEvent",   "MvpBossStateChanged")
ensure("RemoteEvent",   "MvpBossSpawned")
ensure("RemoteEvent",   "MvpBossDefeated")
ensure("RemoteEvent",   "MvpAnnounce")
local GetMvpStateRF  = ensure("RemoteFunction", "GetMvpBossState")   :: RemoteFunction
local AttackMvpRF    = ensure("RemoteFunction", "AttackMvpBoss")     :: RemoteFunction

GetMvpStateRF.OnServerInvoke = function(_player: Player)
  return MvpBossService.getPublicState()
end

-- Rate limit: 1 attack per player per 0.5s
local lastAttack: { [number]: number } = {}
AttackMvpRF.OnServerInvoke = function(player: Player)
  local now = os.clock()
  local last = lastAttack[player.UserId] or 0
  if now - last < 0.5 then
    return false, "ช้าลงหน่อย"
  end
  lastAttack[player.UserId] = now
  return MvpBossService.attack(player)
end
```

---

## 4. MvpBossHUD.client.luau

```lua
--!strict
-- StarterPlayerScripts/MvpBossHUD.client.luau

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui") :: PlayerGui
local remotes     = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local getMvpStateRF  = remotes:WaitForChild("GetMvpBossState") :: RemoteFunction
local attackMvpRF    = remotes:WaitForChild("AttackMvpBoss")   :: RemoteFunction
local stateChangedEv = remotes:WaitForChild("MvpBossStateChanged") :: RemoteEvent
local spawnedEv      = remotes:WaitForChild("MvpBossSpawned")      :: RemoteEvent
local defeatedEv     = remotes:WaitForChild("MvpBossDefeated")     :: RemoteEvent
local mvpAnnounceEv  = remotes:WaitForChild("MvpAnnounce")         :: RemoteEvent

-- ========= UI =========
local sg = Instance.new("ScreenGui")
sg.Name = "MvpBossHUD"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = playerGui

-- HP Bar frame (top center, hidden when no boss)
local hpFrame = Instance.new("Frame")
hpFrame.Name = "BossHpFrame"
hpFrame.Size = UDim2.fromOffset(400, 60)
hpFrame.Position = UDim2.new(0.5, -200, 0, 12)
hpFrame.BackgroundColor3 = Color3.fromRGB(10,15,30)
hpFrame.BorderSizePixel = 0
hpFrame.Visible = false
hpFrame.Parent = sg
Instance.new("UICorner", hpFrame).CornerRadius = UDim.new(0,8)

local bossNameLabel = Instance.new("TextLabel")
bossNameLabel.Size = UDim2.new(1,0,0.5,0)
bossNameLabel.BackgroundTransparency = 1
bossNameLabel.Text = ""
bossNameLabel.TextColor3 = Color3.fromRGB(255,80,80)
bossNameLabel.Font = Enum.Font.GothamBold
bossNameLabel.TextSize = 14
bossNameLabel.Parent = hpFrame

local hpBar = Instance.new("Frame")
hpBar.Name = "HpBar"
hpBar.Size = UDim2.new(1,-16,0,12)
hpBar.Position = UDim2.new(0,8,0.6,0)
hpBar.BackgroundColor3 = Color3.fromRGB(200,40,40)
hpBar.BorderSizePixel = 0
hpBar.Parent = hpFrame
Instance.new("UICorner", hpBar).CornerRadius = UDim.new(0,4)

local hpFill = Instance.new("Frame")
hpFill.Name = "Fill"
hpFill.Size = UDim2.fromScale(1,1)
hpFill.BackgroundColor3 = Color3.fromRGB(200,40,40)
hpFill.BorderSizePixel = 0
hpFill.Parent = hpBar
Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0,4)

-- Attack button (แสดงเฉพาะตอน boss active)
local attackBtn = Instance.new("TextButton")
attackBtn.Size = UDim2.fromOffset(120, 40)
attackBtn.Position = UDim2.new(0.5,-60,0,78)
attackBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
attackBtn.BorderSizePixel = 0
attackBtn.Text = "⚔️ โจมตี MVP"
attackBtn.TextColor3 = Color3.new(1,1,1)
attackBtn.Font = Enum.Font.GothamBold
attackBtn.TextSize = 13
attackBtn.Visible = false
attackBtn.Parent = sg
Instance.new("UICorner", attackBtn).CornerRadius = UDim.new(0,8)

-- Timer label (next spawn)
local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.fromOffset(220,24)
timerLabel.Position = UDim2.new(0.5,-110,0,78)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = ""
timerLabel.TextColor3 = Color3.fromRGB(180,180,180)
timerLabel.Font = Enum.Font.Gotham
timerLabel.TextSize = 12
timerLabel.Visible = false
timerLabel.Parent = sg

-- Announce banner
local announceBanner = Instance.new("Frame")
announceBanner.Size = UDim2.fromOffset(500, 60)
announceBanner.Position = UDim2.new(0.5,-250,0.4,-30)
announceBanner.BackgroundColor3 = Color3.fromRGB(180,40,40)
announceBanner.BorderSizePixel = 0
announceBanner.Visible = false
announceBanner.Parent = sg
Instance.new("UICorner", announceBanner).CornerRadius = UDim.new(0,10)
local announceLabel = Instance.new("TextLabel")
announceLabel.Size = UDim2.fromScale(1,1)
announceLabel.BackgroundTransparency = 1
announceLabel.TextColor3 = Color3.new(1,1,1)
announceLabel.Font = Enum.Font.GothamBold
announceLabel.TextSize = 16
announceLabel.Parent = announceBanner

local function showAnnounce(text: string, color: Color3)
  announceLabel.Text = text
  announceBanner.BackgroundColor3 = color
  announceBanner.Visible = true
  task.delay(4, function() announceBanner.Visible = false end)
end

-- ========= update UI =========
local function updateHUD(state: { [string]: any })
  local active: boolean = state.bossActive == true
  hpFrame.Visible   = active
  attackBtn.Visible = active
  timerLabel.Visible = not active

  if active then
    bossNameLabel.Text = string.format("%s %s", tostring(state.bossEmoji), tostring(state.bossName))
    local pct = if (state.bossMaxHp or 0) > 0
      then (state.bossHp or 0) / (state.bossMaxHp or 1)
      else 0
    TweenService:Create(hpFill, TweenInfo.new(0.3), { Size = UDim2.fromScale(pct, 1) }):Play()
  else
    local secs: number = state.nextSpawnSec or 0
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    timerLabel.Text = string.format("⏰ MVP Boss ถัดไปใน %dh %dm", h, m)
  end
end

-- ========= events =========
stateChangedEv.OnClientEvent:Connect(updateHUD)

spawnedEv.OnClientEvent:Connect(function(bossName: string, emoji: string)
  showAnnounce(string.format("⚠️ %s %s ปรากฏแล้ว! รีบไปสู้!", emoji, bossName),
    Color3.fromRGB(180,40,40))
end)

defeatedEv.OnClientEvent:Connect(function(bossName: string)
  showAnnounce(string.format("🏆 %s พ่ายแล้ว! ขอบคุณทุกคน!", bossName),
    Color3.fromRGB(40,160,80))
end)

mvpAnnounceEv.OnClientEvent:Connect(function(bossName: string, itemId: string)
  showAnnounce(string.format("👑 MVP! คุณได้ %s จาก %s!", itemId, bossName),
    Color3.fromRGB(200,150,20))
end)

attackBtn.MouseButton1Click:Connect(function()
  attackBtn.Active = false
  local ok, msg = pcall(function() return attackMvpRF:InvokeServer() end)
  if not ok then
    showAnnounce("❌ " .. tostring(msg), Color3.fromRGB(160,40,40))
  end
  task.delay(0.5, function() attackBtn.Active = true end)
end)

-- ========= init =========
task.spawn(function()
  local ok, state = pcall(function() return getMvpStateRF:InvokeServer() end)
  if ok and state then updateHUD(state :: { [string]: any }) end
end)
```

---

## 5. ItemTierConfig.luau — เพิ่ม Grail items

```lua
GrailFragment = {
  id="GrailFragment", name="เศษจอกศักดิ์สิทธิ์",
  requiredLevel=40, grandeurRank=3, weight=0.5,
  weaponType="None", tradeable=false,
},
EternityGrail = {
  id="EternityGrail", name="จอกนิรันดร์",
  requiredLevel=80, grandeurRank=5, weight=1,
  weaponType="None", tradeable=false,
},
```

---

## 6. default.project.json — เพิ่ม 4 entries

```json
"MvpBossConfig":    { "$path": "src/ReplicatedStorage/Modules/MvpBossConfig.luau" },
"MvpBossService":   { "$path": "src/ServerScriptService/Combat/MvpBossService.luau" },
"MvpBossHandlers":  { "$path": "src/ServerScriptService/Combat/MvpBossHandlers.server.luau" },
"MvpBossHUD":       { "$path": "src/StarterPlayer/StarterPlayerScripts/MvpBossHUD.client.luau" }
```

---

## สิ่งที่รู้ล่วงหน้า

| ประเด็น | รายละเอียด |
|---------|-----------|
| Spawn interval | `os.time() % 14400` (4h) — ในช่วง 60 วิแรกของทุก interval จะ spawn ใหม่ |
| Boss rotation | hash จาก `math.floor(os.time()/SPAWN_INTERVAL) % #Bosses` — หมุนวนทั้ง 3 boss |
| HP scale | `baseHp + hpPerPlayer × playerCount` คล้าย DV Weekly Boss |
| EternityGrail tradeable=false | Grail เป็น progression item ไม่ควรซื้อขายได้ |
| Rate limit 0.5s | ป้องกัน spam click บน AttackMvpBoss RF |
| MvpBossSpawned ลาย Studio | ถ้าทดสอบใน Studio (PlaceId==0) จะสปอว์นตาม SimulatePlaceKey = "EternityCity" |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-mvpboss.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ReplicatedStorage/Modules/MvpBossConfig.luau \
  src/ServerScriptService/Combat/MvpBossService.luau \
  src/ServerScriptService/Combat/MvpBossHandlers.server.luau \
  src/StarterPlayer/StarterPlayerScripts/MvpBossHUD.client.luau
```

## ทดสอบใน Studio

```lua
-- Server console: spawn boss ทันที
local MB = require(game.ServerScriptService.Combat.MvpBossService)
-- ใช้ internal trySpawn ผ่าน debug
MB._debugSpawn = function()
  local boss = MB._getBossDef and MB._getBossDef() or require(game.ReplicatedStorage.Modules.MvpBossConfig).Bosses[1]
  print("Spawning:", boss.nameTH)
end

-- ทดสอบ attack
local p = game.Players:GetPlayers()[1]
print(MB.attack(p))  -- true, "ยักษ์ว่างเปล่า — XXXX HP เหลือ"
```

## Git commit

```bash
git add -A
git commit -m "feat(P5): MVP World Boss system

- MvpBossConfig: 3 rotating bosses (void_colossus/storm_titan/eternal_warden)
  spawn every 4h, scale HP by player count
- MvpBossService: attack tracking, damage board, MVP reward (Grail/Card)
- MvpBossHandlers: GetMvpBossState RF + AttackMvpBoss RF (0.5s rate limit)
- MvpBossHUD: HP bar + ⚔️ attack button + announce banners (spawn/defeat/MVP)
- ItemTierConfig: +GrailFragment +EternityGrail (non-tradeable)"
```

## รายงานกลับ

- ✅/❌ BUILD · ✅/❌ STRICT CLEAN · commit hash
- ทดสอบ: attack boss → HP ลดไหม / boss defeated → reward ได้ไหม
