# CURSOR PROMPT — P5+ Mercenary & Bounty System
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก commit `4c73819` (P5 Clan War done)
> อ้างอิง: `docs/MASTER-BLUEPRINT.md` §11.3 + `docs/BLUEPRINT-V2-WORLD-PROGRESSION.md` §L2

---

## บริบท

ระบบที่ใช้งานได้แล้ว:
- **CombatService** (P3-C+) — damage/rate-limit server-auth
- **TradingService** (P4) — 2-step confirm trade session
- **ClanWarService** (P5) — territory + score tracking
- **GuildService** (P3-B) — clan membership + ranks

P5+ เพิ่ม **อาชีพรับจ้าง (Mercenary)** และ **ระบบล่าหัว (Bounty)**:
- พ่อค้า/ผู้เล่นโพสต์งาน → Mercenary รับ → งานสำเร็จ → ได้ค่าจ้าง
- ผู้เล่นโพสต์ bounty บนศัตรู → Mercenary คนแรกที่จัดการ → ได้ค่าหัว

---

## ไฟล์ที่ต้องสร้าง

| ไฟล์ | บทบาท | Path |
|------|------|------|
| `MercenaryConfig.luau` | ค่ากลาง: timeout, pay range, bounty limits | `ReplicatedStorage/Modules/` |
| `MercenaryService.luau` | post/accept/complete/cancel escort job | `ServerScriptService/Mercenary/` |
| `BountyService.luau` | post/accept/claim/expire bounty | `ServerScriptService/Mercenary/` |
| `MercenaryHandlers.server.luau` | wire remotes → services | `ServerScriptService/Mercenary/` |
| `BountyBoardClient.client.luau` | NPC Board UI — รายการงาน + รับงาน | `StarterPlayerScripts/` |

---

## 1. MercenaryConfig.luau

```lua
--!strict
-- ReplicatedStorage/Modules/MercenaryConfig.luau

return {
  -- Escort jobs
  EscortTimeoutSecs  = 300,       -- 5 นาที: ยอมรับงานแล้วต้องเสร็จใน 5 นาที
  EscortMinPay       = 50,        -- credits ขั้นต่ำ
  EscortMaxPay       = 5000,
  MaxActiveEscorts   = 3,         -- งาน escort สูงสุดที่ผู้เล่นโพสต์ได้พร้อมกัน
  EscortProtectRadius = 30,       -- studs: Mercenary ต้องอยู่ใกล้ client ≤ radius นี้

  -- Bounty
  BountyMinAmount    = 100,
  BountyMaxAmount    = 50000,
  BountyExpiryDays   = 7,         -- หมดอายุหลัง 7 วัน
  MaxBountiesPerPlayer = 5,       -- bounty สูงสุดที่โพสต์บนผู้เล่นคนเดียว
  BountyKillProximity = 50,       -- studs: ต้องอยู่ใกล้เพื่อ claim kill credit
}
```

---

## 2. MercenaryService.luau

```lua
--!strict
-- ServerScriptService/Mercenary/MercenaryService.luau

local DataStoreService  = game:GetService("DataStoreService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MercenaryConfig   = require(ReplicatedStorage.Modules.MercenaryConfig)

-- in-memory job registry (สำหรับ session — ไม่ต้อง persist, reset เมื่อเซิร์ฟเวอร์รีสตาร์ท)
type EscortJob = {
  jobId      : string,
  clientId   : number,   -- ผู้จ้าง userId
  mercId     : number?,  -- Mercenary userId (nil = รอรับ)
  pay        : number,
  postedAt   : number,
  acceptedAt : number?,
  status     : "open" | "active" | "done" | "cancelled",
  destination: string,   -- ชื่อ zone ปลายทาง
}

local jobs: { [string]: EscortJob } = {}
local jobCounter = 0

local MercenaryService = {}

local function makeJobId(): string
  jobCounter += 1
  return string.format("job_%d_%d", os.time(), jobCounter)
end

-- โพสต์งาน escort
function MercenaryService.postEscort(
  client: Player,
  pay: number,
  destination: string
): (boolean, string)
  if pay < MercenaryConfig.EscortMinPay or pay > MercenaryConfig.EscortMaxPay then
    return false, string.format("ค่าจ้างต้อง %d–%d credits",
      MercenaryConfig.EscortMinPay, MercenaryConfig.EscortMaxPay)
  end

  -- นับงานที่เปิดอยู่ของ client คนนี้
  local activeCount = 0
  for _, job in jobs do
    if job.clientId == client.UserId and job.status == "open" then
      activeCount += 1
    end
  end
  if activeCount >= MercenaryConfig.MaxActiveEscorts then
    return false, "โพสต์งานเกินจำนวนสูงสุด"
  end

  local jobId = makeJobId()
  jobs[jobId] = {
    jobId       = jobId,
    clientId    = client.UserId,
    mercId      = nil,
    pay         = pay,
    postedAt    = os.time(),
    acceptedAt  = nil,
    status      = "open",
    destination = destination,
  }
  return true, jobId
end

-- รับงาน escort
function MercenaryService.acceptEscort(merc: Player, jobId: string): (boolean, string)
  local job = jobs[jobId]
  if not job then return false, "ไม่พบงาน" end
  if job.status ~= "open" then return false, "งานถูกรับแล้ว" end
  if job.clientId == merc.UserId then return false, "ไม่สามารถรับงานตัวเองได้" end

  job.mercId     = merc.UserId
  job.acceptedAt = os.time()
  job.status     = "active"

  -- auto-cancel หากเกิน timeout
  task.delay(MercenaryConfig.EscortTimeoutSecs, function()
    if jobs[jobId] and jobs[jobId].status == "active" then
      jobs[jobId].status = "cancelled"
      warn("[Mercenary] job", jobId, "timed out")
    end
  end)

  return true, "รับงานสำเร็จ"
end

-- สำเร็จงาน (เรียกเมื่อ client ถึงปลายทาง + merc อยู่ใกล้)
function MercenaryService.completeEscort(client: Player, jobId: string): (boolean, string)
  local job = jobs[jobId]
  if not job then return false, "ไม่พบงาน" end
  if job.clientId ~= client.UserId then return false, "ไม่ใช่งานของคุณ" end
  if job.status ~= "active" then return false, "งานไม่ได้ active" end
  if not job.mercId then return false, "ไม่มี Mercenary" end

  -- ตรวจระยะห่าง client–merc
  local clientChar = client.Character
  local merc = Players:GetPlayerByUserId(job.mercId)
  local mercChar = merc and merc.Character
  if clientChar and mercChar then
    local dist = (clientChar.HumanoidRootPart.Position
                 - mercChar.HumanoidRootPart.Position).Magnitude
    if dist > MercenaryConfig.EscortProtectRadius then
      return false, string.format("Mercenary ห่างเกิน %d studs", MercenaryConfig.EscortProtectRadius)
    end
  end

  job.status = "done"
  jobs[jobId] = nil  -- cleanup

  -- TODO: โอนเครดิต job.pay ให้ merc (ต่อ CurrencyService)
  -- CurrencyService.addCredits(merc, job.pay)

  return true, string.format("งานเสร็จ — โอน %d credits ให้ Mercenary", job.pay)
end

-- ดูรายการงานที่เปิดอยู่ (สำหรับ BountyBoard UI)
function MercenaryService.getOpenJobs(): { EscortJob }
  local result: { EscortJob } = {}
  for _, job in jobs do
    if job.status == "open" then
      table.insert(result, job)
    end
  end
  return result
end

return MercenaryService
```

---

## 3. BountyService.luau

```lua
--!strict
-- ServerScriptService/Mercenary/BountyService.luau

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MercenaryConfig   = require(ReplicatedStorage.Modules.MercenaryConfig)

type Bounty = {
  bountyId   : string,
  posterId   : number,   -- ผู้โพสต์ userId
  targetId   : number,   -- เป้าหมาย userId
  amount     : number,
  postedAt   : number,
  expiresAt  : number,
  claimed    : boolean,
  claimedBy  : number?,
}

local bounties: { [string]: Bounty } = {}
local bountyCounter = 0

local BountyService = {}

local function makeBountyId(): string
  bountyCounter += 1
  return string.format("bounty_%d_%d", os.time(), bountyCounter)
end

-- โพสต์ bounty
function BountyService.post(
  poster: Player,
  targetId: number,
  amount: number
): (boolean, string)
  if poster.UserId == targetId then
    return false, "ไม่สามารถโพสต์ bounty บนตัวเองได้"
  end
  if amount < MercenaryConfig.BountyMinAmount or amount > MercenaryConfig.BountyMaxAmount then
    return false, string.format("จำนวน bounty ต้อง %d–%d",
      MercenaryConfig.BountyMinAmount, MercenaryConfig.BountyMaxAmount)
  end

  -- นับ bounty ที่มีอยู่บน target คนนี้
  local count = 0
  for _, b in bounties do
    if b.targetId == targetId and not b.claimed then
      count += 1
    end
  end
  if count >= MercenaryConfig.MaxBountiesPerPlayer then
    return false, "มี bounty บนผู้เล่นคนนี้เต็มแล้ว"
  end

  local id = makeBountyId()
  bounties[id] = {
    bountyId  = id,
    posterId  = poster.UserId,
    targetId  = targetId,
    amount    = amount,
    postedAt  = os.time(),
    expiresAt = os.time() + (MercenaryConfig.BountyExpiryDays * 86400),
    claimed   = false,
    claimedBy = nil,
  }

  -- auto-expire
  task.delay(MercenaryConfig.BountyExpiryDays * 86400, function()
    if bounties[id] and not bounties[id].claimed then
      bounties[id] = nil
      -- TODO: คืนเงินให้ poster
    end
  end)

  return true, id
end

-- claim bounty: เรียกเมื่อ hunter kill target (ผ่าน CombatService death callback)
function BountyService.onTargetKilled(killerId: number, targetId: number)
  local killer = Players:GetPlayerByUserId(killerId)
  if not killer then return end

  -- ตรวจว่า killer อยู่ใกล้ target ณ เวลาที่ตาย
  -- (ควรเรียกจาก CombatService ซึ่งรู้ตำแหน่งอยู่แล้ว)

  local totalReward = 0
  for id, bounty in bounties do
    if bounty.targetId == targetId and not bounty.claimed
       and os.time() < bounty.expiresAt then
      bounty.claimed   = true
      bounty.claimedBy = killerId
      totalReward += bounty.amount
      bounties[id] = bounty
    end
  end

  if totalReward > 0 then
    -- TODO: CurrencyService.addCredits(killer, totalReward)
    print(string.format("[Bounty] %s claimed %d credits on target %d",
      killer.Name, totalReward, targetId))
  end
end

-- ดู bounty ที่ active (สำหรับ Board UI)
function BountyService.getActiveBounties(): { Bounty }
  local result: { Bounty } = {}
  local now = os.time()
  for _, b in bounties do
    if not b.claimed and now < b.expiresAt then
      table.insert(result, b)
    end
  end
  return result
end

-- ดู bounty บน target คนเดียว (สำหรับ Interaction menu)
function BountyService.getBountiesOnTarget(targetId: number): number
  local total = 0
  local now = os.time()
  for _, b in bounties do
    if b.targetId == targetId and not b.claimed and now < b.expiresAt then
      total += b.amount
    end
  end
  return total
end

return BountyService
```

---

## 4. MercenaryHandlers.server.luau

```lua
--!strict
-- ServerScriptService/Mercenary/MercenaryHandlers.server.luau

local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MercenaryService   = require(script.Parent.MercenaryService)
local BountyService      = require(script.Parent.BountyService)

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local function ensure(className: string, name: string): Instance
  local existing = remotes:FindFirstChild(name)
  if existing then return existing end
  local inst = Instance.new(className)
  inst.Name   = name
  inst.Parent = remotes
  return inst
end

-- Mercenary remotes
local postEscortRF    = ensure("RemoteFunction", "PostEscort")    :: RemoteFunction
local acceptEscortRF  = ensure("RemoteFunction", "AcceptEscort")  :: RemoteFunction
local completeEscortRF= ensure("RemoteFunction", "CompleteEscort"):: RemoteFunction
local getJobsRF       = ensure("RemoteFunction", "GetEscortJobs") :: RemoteFunction

-- Bounty remotes
local postBountyRF    = ensure("RemoteFunction", "PostBounty")    :: RemoteFunction
local getBountiesRF   = ensure("RemoteFunction", "GetBounties")   :: RemoteFunction
local getBountyOnRF   = ensure("RemoteFunction", "GetBountyOn")   :: RemoteFunction

-- Wire Mercenary
postEscortRF.OnServerInvoke = function(player, pay, destination)
  return MercenaryService.postEscort(player, pay :: number, destination :: string)
end

acceptEscortRF.OnServerInvoke = function(player, jobId)
  return MercenaryService.acceptEscort(player, jobId :: string)
end

completeEscortRF.OnServerInvoke = function(player, jobId)
  return MercenaryService.completeEscort(player, jobId :: string)
end

getJobsRF.OnServerInvoke = function(_player)
  return MercenaryService.getOpenJobs()
end

-- Wire Bounty
postBountyRF.OnServerInvoke = function(player, targetId, amount)
  return BountyService.post(player, targetId :: number, amount :: number)
end

getBountiesRF.OnServerInvoke = function(_player)
  return BountyService.getActiveBounties()
end

getBountyOnRF.OnServerInvoke = function(_player, targetId)
  return BountyService.getBountiesOnTarget(targetId :: number)
end
```

---

## 5. BountyBoardClient.client.luau (โครงสร้างหลัก)

```lua
--!strict
-- StarterPlayerScripts/BountyBoardClient.client.luau

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes      = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local getJobsRF    = remotes:WaitForChild("GetEscortJobs")  :: RemoteFunction
local acceptEscortRF = remotes:WaitForChild("AcceptEscort") :: RemoteFunction
local getBountiesRF  = remotes:WaitForChild("GetBounties")  :: RemoteFunction
local postBountyRF   = remotes:WaitForChild("PostBounty")   :: RemoteFunction

-- Board UI (Scale-based, เปิด/ปิดด้วย ProximityPrompt บน NPC)
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "BountyBoardGui"
screenGui.ResetOnSpawn   = false
screenGui.Enabled        = false
screenGui.Parent         = Players.LocalPlayer.PlayerGui

local frame = Instance.new("Frame")
frame.Size              = UDim2.fromScale(0.5, 0.7)
frame.Position          = UDim2.fromScale(0.25, 0.15)
frame.BackgroundColor3  = Color3.fromRGB(20, 20, 35)
frame.BackgroundTransparency = 0.1
frame.Parent            = screenGui

-- แท็บ: Escort Jobs / Bounties
local tabEscort = Instance.new("TextButton")
tabEscort.Size  = UDim2.fromScale(0.5, 0.08)
tabEscort.Position = UDim2.fromScale(0, 0)
tabEscort.Text  = "📦 Escort Jobs"
tabEscort.TextScaled = true
tabEscort.Parent = frame

local tabBounty = Instance.new("TextButton")
tabBounty.Size  = UDim2.fromScale(0.5, 0.08)
tabBounty.Position = UDim2.fromScale(0.5, 0)
tabBounty.Text  = "🏴‍☠️ Bounties"
tabBounty.TextScaled = true
tabBounty.Parent = frame

local listFrame = Instance.new("ScrollingFrame")
listFrame.Size  = UDim2.fromScale(1, 0.85)
listFrame.Position = UDim2.fromScale(0, 0.1)
listFrame.BackgroundTransparency = 1
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.CanvasSize = UDim2.new()
listFrame.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = listFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromScale(0.1, 0.07)
closeBtn.Position = UDim2.fromScale(0.9, 0)
closeBtn.Text = "✕"
closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.Parent = frame
closeBtn.MouseButton1Click:Connect(function()
  screenGui.Enabled = false
end)

local function clearList()
  for _, child in listFrame:GetChildren() do
    if child:IsA("Frame") then child:Destroy() end
  end
end

local function addRow(text: string, btnText: string, onAccept: () -> ())
  local row = Instance.new("Frame")
  row.Size = UDim2.new(1, 0, 0, 50)
  row.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
  row.Parent = listFrame

  local lbl = Instance.new("TextLabel")
  lbl.Size = UDim2.fromScale(0.75, 1)
  lbl.BackgroundTransparency = 1
  lbl.TextColor3 = Color3.new(1,1,1)
  lbl.TextScaled = true
  lbl.Text = text
  lbl.TextXAlignment = Enum.TextXAlignment.Left
  lbl.Parent = row

  local btn = Instance.new("TextButton")
  btn.Size = UDim2.fromScale(0.22, 0.8)
  btn.Position = UDim2.fromScale(0.77, 0.1)
  btn.BackgroundColor3 = Color3.fromRGB(60, 160, 80)
  btn.TextScaled = true
  btn.Text = btnText
  btn.Parent = row
  btn.MouseButton1Click:Connect(onAccept)
end

local currentTab = "escort"

local function loadEscortJobs()
  clearList()
  local ok, jobs = pcall(function()
    return getJobsRF:InvokeServer()
  end)
  if not ok or not jobs then return end
  for _, job in jobs :: { any } do
    local j = job :: { jobId: string, pay: number, destination: string }
    addRow(
      string.format("📦 → %s | 💰 %d credits", j.destination, j.pay),
      "รับงาน",
      function()
        local s, msg = acceptEscortRF:InvokeServer(j.jobId)
        print(s, msg)
        loadEscortJobs()
      end
    )
  end
end

local function loadBounties()
  clearList()
  local ok, bList = pcall(function()
    return getBountiesRF:InvokeServer()
  end)
  if not ok or not bList then return end
  for _, b in bList :: { any } do
    local bData = b :: { targetId: number, amount: number }
    local target = Players:GetPlayerByUserId(bData.targetId)
    local targetName = target and target.Name or ("UserId:" .. bData.targetId)
    addRow(
      string.format("🏴‍☠️ %s | 💰 %d credits", targetName, bData.amount),
      "ล่า",
      function()
        -- เปิด InteractionClient ไปหา target หรือ mark บน minimap
        print("Hunting:", targetName)
      end
    )
  end
end

tabEscort.MouseButton1Click:Connect(function()
  currentTab = "escort"
  loadEscortJobs()
end)
tabBounty.MouseButton1Click:Connect(function()
  currentTab = "bounty"
  loadBounties()
end)

-- เปิด Board ผ่าน ProximityPrompt บน NPC "Bounty Master"
-- NPC ต้องมี ProximityPrompt → Triggered → เปิด screenGui
-- (ตัวอย่าง: workspace.BountyMasterNPC.ProximityPrompt.Triggered:Connect)
local function openBoard()
  screenGui.Enabled = true
  if currentTab == "escort" then
    loadEscortJobs()
  else
    loadBounties()
  end
end

-- expose สำหรับ NPC trigger (BindableEvent)
local openBountyBoard = Instance.new("BindableEvent")
openBountyBoard.Name   = "OpenBountyBoard"
openBountyBoard.Parent = game:GetService("ReplicatedStorage")
openBountyBoard.Event:Connect(openBoard)
```

---

## 6. default.project.json — เพิ่ม Mercenary/ folder

เพิ่มใน `ServerScriptService` section:
```json
"Mercenary": {
  "$className": "Folder",
  "MercenaryService": { "$path": "src/ServerScriptService/Mercenary/MercenaryService.luau" },
  "BountyService": { "$path": "src/ServerScriptService/Mercenary/BountyService.luau" },
  "MercenaryHandlers": { "$path": "src/ServerScriptService/Mercenary/MercenaryHandlers.server.luau" }
}
```
เพิ่มใน `ReplicatedStorage/Modules`:
```json
"MercenaryConfig": { "$path": "src/ReplicatedStorage/Modules/MercenaryConfig.luau" }
```
เพิ่มใน `StarterPlayerScripts`:
```json
"BountyBoardClient": { "$path": "src/StarterPlayer/StarterPlayerScripts/BountyBoardClient.client.luau" }
```

---

## สิ่งที่รู้ล่วงหน้า (luau-lsp อาจ flag)

| ประเด็น | วิธีแก้ |
|---------|---------|
| `job :: { jobId: string, ... }` cast | เพิ่ม explicit type assertion ในลูป |
| `Players:GetPlayerByUserId()` อาจ return nil | มี `if not killer then return end` guard แล้ว |
| `CurrencyService` ยังไม่มี | ใส่ `-- TODO:` comment ไปก่อน (ทำใน P6) |
| `OpenBountyBoard` BindableEvent | ต้องสร้างก่อน NPC ProximityPrompt trigger ใช้ |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-p5plus.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ReplicatedStorage/Modules/MercenaryConfig.luau \
  src/ServerScriptService/Mercenary/MercenaryService.luau \
  src/ServerScriptService/Mercenary/BountyService.luau \
  src/ServerScriptService/Mercenary/MercenaryHandlers.server.luau \
  src/StarterPlayer/StarterPlayerScripts/BountyBoardClient.client.luau
```

## Git commit (ถ้า clean)

```bash
git add -A
git commit -m "feat(P5+): Mercenary escort + Bounty hunt system

- MercenaryConfig: timeout 5min, pay 50-5000, bounty 100-50000, expiry 7d
- MercenaryService: post/accept/complete escort (proximity + timeout check)
- BountyService: post/claim/expire bounty (onTargetKilled callback)
- MercenaryHandlers: wire 7 remotes via SocialRemotes
- BountyBoardClient: NPC board UI (Escort/Bounty tabs, Scale-based)"
```

## รายงานกลับ
- ✅/❌ BUILD
- ✅/❌ STRICT CLEAN (error+line)
- commit hash
