# CURSOR PROMPT — Daily Quest / Mission System
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก PlayerLevelService Full (1f1233a)
> อ้างอิง: `docs/MASTER-BLUEPRINT.md` §4 Retention Loop

---

## บริบท

ระบบ Quest รายวันที่รีเซ็ตทุกเที่ยงคืน UTC+7 (17:00 UTC)
- ผู้เล่นได้รับ Quest ประจำวัน 3 ข้อ สุ่มจาก pool
- reward: XP (ผ่าน `addExp`), Credits (ผ่าน `CurrencyService.addCredits`), หรือ Item (ผ่าน `PlayerItemStore.addItem`)
- Progress ติดตามฝั่ง server — client แค่แสดง HUD

**API ที่มีอยู่แล้ว (ห้ามเขียนซ้ำ):**
- `PlayerLevelService.addExp(player, amount)` — `ServerScriptService/Progression/PlayerLevelService`
- `CurrencyService.addCredits(userId, amount)` — `ServerScriptService/Commerce/CurrencyService`
- `PlayerItemStore.addItem(userId, itemId, qty)` — `ServerScriptService/Progression/PlayerItemStore`
- Remotes อยู่ใน `ReplicatedStorage/SocialRemotes`

---

## ไฟล์ที่ต้องสร้าง

| ไฟล์ | Path |
|------|------|
| `QuestConfig.luau` | `ReplicatedStorage/Modules/` |
| `QuestStore.luau` | `ServerScriptService/Progression/` |
| `QuestService.luau` | `ServerScriptService/Progression/` |
| `QuestHandlers.server.luau` | `ServerScriptService/Progression/` |
| `QuestHUDClient.client.luau` | `StarterPlayerScripts/` |

---

## 1. QuestConfig.luau

```lua
--!strict
-- ReplicatedStorage/Modules/QuestConfig.luau

export type RewardType = "xp" | "credits" | "item"

export type QuestReward = {
  rewardType : RewardType,
  amount     : number,     -- XP หรือ credits
  itemId     : string?,    -- ถ้า rewardType == "item"
  itemQty    : number?,
}

export type QuestObjective = "kill_npc" | "use_emote" | "visit_zone" | "send_chat" | "equip_pet" | "trade_complete"

export type QuestTemplate = {
  id         : string,
  nameTH     : string,
  descTH     : string,        -- "สังหาร NPC 10 ตัว"
  objective  : QuestObjective,
  targetCount: number,        -- จำนวนที่ต้องทำ
  reward     : QuestReward,
}

-- pool quest ทั้งหมด (สุ่ม 3 ข้อต่อวัน)
return {
  Templates = {
    {
      id="kill10", nameTH="นักล่าเริ่มต้น",
      descTH="สังหาร NPC 10 ตัว",
      objective="kill_npc", targetCount=10,
      reward={ rewardType="xp", amount=500 },
    },
    {
      id="kill30", nameTH="นักล่าชั้นสอง",
      descTH="สังหาร NPC 30 ตัว",
      objective="kill_npc", targetCount=30,
      reward={ rewardType="xp", amount=1500 },
    },
    {
      id="emote3", nameTH="จิตวิญญาณสังคม",
      descTH="ใช้ Emote 3 ครั้ง",
      objective="use_emote", targetCount=3,
      reward={ rewardType="credits", amount=100 },
    },
    {
      id="chat10", nameTH="นักพูด",
      descTH="ส่งข้อความแชท 10 ข้อความ",
      objective="send_chat", targetCount=10,
      reward={ rewardType="credits", amount=80 },
    },
    {
      id="visit_marina", nameTH="นักท่องเที่ยว",
      descTH="ไปที่ Marina District",
      objective="visit_zone", targetCount=1,
      reward={ rewardType="xp", amount=200 },
    },
    {
      id="equip_pet", nameTH="เจ้าของสัตว์เลี้ยง",
      descTH="สวม Pet 1 ตัว",
      objective="equip_pet", targetCount=1,
      reward={ rewardType="credits", amount=50 },
    },
    {
      id="trade1", nameTH="พ่อค้า",
      descTH="ทำการซื้อขาย 1 ครั้ง",
      objective="trade_complete", targetCount=1,
      reward={ rewardType="xp", amount=300 },
    },
    {
      id="kill50", nameTH="นักสังหาร",
      descTH="สังหาร NPC 50 ตัว",
      objective="kill_npc", targetCount=50,
      reward={ rewardType="item", amount=0, itemId="stone_fragment", itemQty=30 },
    },
  } :: { QuestTemplate },
  DAILY_QUEST_COUNT = 3,
  -- รีเซ็ตทุก 17:00 UTC = เที่ยงคืน UTC+7
  RESET_HOUR_UTC = 17,
}
```

---

## 2. QuestStore.luau

```lua
--!strict
-- ServerScriptService/Progression/QuestStore.luau

local DataStoreService = game:GetService("DataStoreService")
local ds = DataStoreService:GetDataStore("UtopiaQuest_v1")

export type QuestProgress = {
  questId   : string,
  progress  : number,      -- จำนวนที่ทำแล้ว
  completed : boolean,
  claimed   : boolean,     -- รับรางวัลแล้ว
}

export type PlayerQuestData = {
  dateKey  : string,       -- "2026-06-13" (UTC+7)
  quests   : { QuestProgress },
}

local function emptyData(): PlayerQuestData
  return { dateKey = "", quests = {} }
end

local QuestStore = {}

function QuestStore.get(userId: number): PlayerQuestData
  local ok, result = pcall(function()
    return ds:GetAsync("quest_" .. userId)
  end)
  if ok and result then return result :: PlayerQuestData end
  return emptyData()
end

function QuestStore.save(userId: number, data: PlayerQuestData)
  local ok, err = pcall(function()
    ds:SetAsync("quest_" .. userId, data)
  end)
  if not ok then warn("[QuestStore] save failed:", err) end
end

return QuestStore
```

---

## 3. QuestService.luau

```lua
--!strict
-- ServerScriptService/Progression/QuestService.luau

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local QuestConfig  = require(ReplicatedStorage.Modules.QuestConfig)
local QuestStore   = require(script.Parent.QuestStore)

-- lazy-require เพื่อหลีก circular dependency
local function getLevelService()
  return require(script.Parent.PlayerLevelService) :: any
end
local function getCurrencyService()
  return require(ServerScriptService.Commerce.CurrencyService) :: any
end
local function getItemStore()
  return require(script.Parent.PlayerItemStore) :: any
end

-- cache ใน memory: userId → PlayerQuestData
local cache: { [number]: QuestStore.PlayerQuestData } = {}
local remotes: Folder

-- dateKey = วันที่ UTC+7 format "YYYY-MM-DD"
local function getDateKeyUTC7(): string
  local utc7Offset = 7 * 3600
  local now = os.time() + utc7Offset
  local t = os.date("!*t", now) :: any
  return string.format("%04d-%02d-%02d", t.year, t.month, t.day)
end

-- สุ่ม 3 quest จาก pool (Fisher-Yates)
local function pickDailyQuests(): { QuestStore.QuestProgress }
  local pool = {}
  for i, tmpl in QuestConfig.Templates do
    pool[i] = tmpl
  end
  -- shuffle
  for i = #pool, 2, -1 do
    local j = math.random(1, i)
    pool[i], pool[j] = pool[j], pool[i]
  end
  local result: { QuestStore.QuestProgress } = {}
  for i = 1, math.min(QuestConfig.DAILY_QUEST_COUNT, #pool) do
    table.insert(result, {
      questId   = pool[i].id,
      progress  = 0,
      completed = false,
      claimed   = false,
    })
  end
  return result
end

-- ดึง (หรือสร้าง) quest ประจำวันของผู้เล่น
local function ensureDailyQuests(userId: number): QuestStore.PlayerQuestData
  local data = cache[userId] or QuestStore.get(userId)
  local today = getDateKeyUTC7()
  if data.dateKey ~= today then
    -- รีเซ็ต
    data = { dateKey = today, quests = pickDailyQuests() }
    QuestStore.save(userId, data)
  end
  cache[userId] = data
  return data
end

-- หา template จาก id
local function findTemplate(questId: string): QuestConfig.QuestTemplate?
  for _, tmpl in QuestConfig.Templates do
    if tmpl.id == questId then return tmpl end
  end
  return nil
end

-- แจ้ง client อัปเดต
local function fireUpdate(player: Player)
  local data = cache[player.UserId]
  if not data then return end
  local ev = remotes:FindFirstChild("QuestUpdate") :: RemoteEvent?
  if ev then ev:FireClient(player, data.quests) end
end

-- บันทึก progress async
local function saveAsync(userId: number)
  local data = cache[userId]
  if data then
    task.spawn(function() QuestStore.save(userId, data) end)
  end
end

-- ============ Public API ============

local QuestService = {}

-- เรียกเมื่อ objective เกิดขึ้น (จาก handlers)
function QuestService.recordProgress(player: Player, objective: QuestConfig.QuestObjective, count: number?)
  count = count or 1
  local data = cache[player.UserId]
  if not data then return end

  local changed = false
  for _, q in data.quests do
    if q.completed then continue end
    local tmpl = findTemplate(q.questId)
    if not tmpl or tmpl.objective ~= objective then continue end

    q.progress = math.min(q.progress + count, tmpl.targetCount)
    if q.progress >= tmpl.targetCount then
      q.completed = true
      -- แจ้ง client ว่า quest สำเร็จ
      local ev = remotes:FindFirstChild("QuestCompleted") :: RemoteEvent?
      if ev then ev:FireClient(player, q.questId) end
    end
    changed = true
  end

  if changed then
    saveAsync(player.UserId)
    fireUpdate(player)
  end
end

-- รับรางวัล
function QuestService.claimReward(player: Player, questId: string): (boolean, string)
  local data = cache[player.UserId]
  if not data then return false, "ไม่มีข้อมูล" end

  for _, q in data.quests do
    if q.questId ~= questId then continue end
    if not q.completed then return false, "ยังไม่เสร็จ" end
    if q.claimed     then return false, "รับแล้ว" end

    local tmpl = findTemplate(questId)
    if not tmpl then return false, "ไม่พบ quest" end

    q.claimed = true
    local rw = tmpl.reward

    if rw.rewardType == "xp" then
      getLevelService().addExp(player, rw.amount)
    elseif rw.rewardType == "credits" then
      getCurrencyService().addCredits(player.UserId, rw.amount)
    elseif rw.rewardType == "item" and rw.itemId then
      getItemStore().addItem(player.UserId, rw.itemId, rw.itemQty or 1)
    end

    saveAsync(player.UserId)
    fireUpdate(player)
    return true, "รับรางวัลแล้ว!"
  end

  return false, "ไม่พบ quest นี้"
end

-- ดูรายการ quest ปัจจุบัน (RF)
function QuestService.getQuests(player: Player): { QuestStore.QuestProgress }
  return ensureDailyQuests(player.UserId).quests
end

function QuestService.init(remotesFolder: Folder)
  remotes = remotesFolder
  local function ensure(cls: string, name: string)
    if not remotes:FindFirstChild(name) then
      local i = Instance.new(cls); i.Name = name; i.Parent = remotes
    end
  end
  ensure("RemoteFunction", "GetDailyQuests")
  ensure("RemoteFunction", "ClaimQuestReward")
  ensure("RemoteEvent",    "QuestUpdate")
  ensure("RemoteEvent",    "QuestCompleted")

  Players.PlayerAdded:Connect(function(player)
    ensureDailyQuests(player.UserId)
    task.wait(2)  -- รอ character load
    fireUpdate(player)
  end)

  Players.PlayerRemoving:Connect(function(player)
    local data = cache[player.UserId]
    if data then QuestStore.save(player.UserId, data) end
    cache[player.UserId] = nil
  end)
end

return QuestService
```

---

## 4. QuestHandlers.server.luau

```lua
--!strict
-- ServerScriptService/Progression/QuestHandlers.server.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestService      = require(script.Parent.QuestService)

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
QuestService.init(remotes)

local getQuestsRF   = remotes:WaitForChild("GetDailyQuests")   :: RemoteFunction
local claimRewardRF = remotes:WaitForChild("ClaimQuestReward") :: RemoteFunction

getQuestsRF.OnServerInvoke = function(player)
  return QuestService.getQuests(player)
end

claimRewardRF.OnServerInvoke = function(player, questId)
  return QuestService.claimReward(player, questId :: string)
end

-- ============ Progress hooks ============
-- hook kill_npc: ฟัง CombatService → BindableEvent (สร้างใน CombatService ด้วย)
local npcKillBindable = game:GetService("ReplicatedStorage"):FindFirstChild("NpcKillEvent") :: BindableEvent?
if npcKillBindable then
  npcKillBindable.Event:Connect(function(player: Player)
    QuestService.recordProgress(player, "kill_npc", 1)
  end)
end

-- hook use_emote: ฟัง EmotePlayed RemoteEvent ที่ส่งจาก EmoteService (server)
local emotePlayed = remotes:FindFirstChild("EmotePlayed") :: RemoteEvent?
if emotePlayed then
  emotePlayed.OnServerEvent:Connect(function(player)
    QuestService.recordProgress(player, "use_emote", 1)
  end)
end

-- hook send_chat: ฟัง ChatSent RemoteEvent
local chatSent = remotes:FindFirstChild("ChatSent") :: RemoteEvent?
if chatSent then
  chatSent.OnServerEvent:Connect(function(player)
    QuestService.recordProgress(player, "send_chat", 1)
  end)
end

-- hook equip_pet: ฟัง PetEquipped RemoteEvent (server fires this to client — need server event)
-- เพิ่มใน PetHandlers: เมื่อ equipPetRF ถูกเรียก → fire bindable หรือเรียก QuestService โดยตรง
-- (ทำใน PetHandlers.server.luau)

-- hook trade_complete: ฟัง TradingService BindableEvent
local tradeComplete = game:GetService("ReplicatedStorage"):FindFirstChild("TradeCompleteEvent") :: BindableEvent?
if tradeComplete then
  tradeComplete.Event:Connect(function(player: Player)
    QuestService.recordProgress(player, "trade_complete", 1)
  end)
end
```

---

## 5. แก้ CombatService.luau — เพิ่ม NpcKillEvent

ใน `grantKillExp` (หลังจาก addExp แล้ว) เพิ่ม:

```lua
-- fire NpcKillEvent สำหรับ Quest system
local killBindable = game:GetService("ReplicatedStorage"):FindFirstChild("NpcKillEvent") :: BindableEvent?
if killBindable then
  killBindable:Fire(player)
end
```

และสร้าง BindableEvent ใน `ReplicatedStorage` (ชื่อ `NpcKillEvent`) ใน `GameBootstrap` หรือ `QuestHandlers`:

```lua
-- ใน QuestHandlers.server.luau ก่อน init (สร้างถ้าไม่มี)
if not game:GetService("ReplicatedStorage"):FindFirstChild("NpcKillEvent") then
  local b = Instance.new("BindableEvent")
  b.Name   = "NpcKillEvent"
  b.Parent = game:GetService("ReplicatedStorage")
end
```

---

## 6. แก้ PetHandlers.server.luau — hook equip_pet quest

หลังจาก `equipPetRF.OnServerInvoke` สำเร็จ:

```lua
-- เพิ่มบรรทัดนี้หลัง equipPetRF handler
local QuestService = require(game:GetService("ServerScriptService").Progression.QuestService)

equipPetRF.OnServerInvoke = function(player, petId)
  local ok, msg = PetService.equipPet(player, petId :: string)
  if ok then
    QuestService.recordProgress(player, "equip_pet", 1)
  end
  return ok, msg
end
```

---

## 7. QuestHUDClient.client.luau

```lua
--!strict
-- StarterPlayerScripts/QuestHUDClient.client.luau

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local QuestConfig       = require(ReplicatedStorage.Modules.QuestConfig)

local localPlayer = Players.LocalPlayer
local remotes     = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local getQuestsRF    = remotes:WaitForChild("GetDailyQuests")   :: RemoteFunction
local claimRewardRF  = remotes:WaitForChild("ClaimQuestReward") :: RemoteFunction
local questUpdateEv  = remotes:WaitForChild("QuestUpdate")      :: RemoteEvent
local questDoneEv    = remotes:WaitForChild("QuestCompleted")   :: RemoteEvent

local screenGui = Instance.new("ScreenGui")
screenGui.Name         = "QuestHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent       = localPlayer.PlayerGui

-- ปุ่มเปิด panel (มุมขวาบน ใต้ toggle camera)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size     = UDim2.fromScale(0.07, 0.05)
toggleBtn.Position = UDim2.fromScale(0.92, 0.08)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
toggleBtn.TextScaled= true
toggleBtn.Text     = "📋"
toggleBtn.Parent   = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0.2, 0)

-- Quest panel
local panel = Instance.new("Frame")
panel.Size     = UDim2.fromScale(0.3, 0.45)
panel.Position = UDim2.fromScale(0.69, 0.08)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
panel.BackgroundTransparency = 0.05
panel.Visible  = false
panel.Parent   = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0.03, 0)

local title = Instance.new("TextLabel")
title.Size   = UDim2.fromScale(1, 0.12)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true
title.Text   = "📋 ภารกิจประจำวัน"
title.Font   = Enum.Font.GothamBold
title.Parent = panel
Instance.new("UICorner", title).CornerRadius = UDim.new(0.05, 0)

local closeBtn = Instance.new("TextButton")
closeBtn.Size  = UDim2.fromScale(0.12, 0.1)
closeBtn.Position = UDim2.fromScale(0.87, 0.01)
closeBtn.Text  = "✕"
closeBtn.TextScaled = true
closeBtn.BackgroundTransparency = 1
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.ZIndex = 2
closeBtn.Parent = panel
closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)

-- scroll สำหรับ quest items
local scroll = Instance.new("ScrollingFrame")
scroll.Size             = UDim2.fromScale(1, 0.86)
scroll.Position         = UDim2.fromScale(0, 0.13)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.CanvasSize       = UDim2.fromScale(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent           = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding    = UDim.new(0, 4)
listLayout.Parent     = scroll
Instance.new("UIPadding", scroll).PaddingLeft = UDim.new(0.02, 0)

-- notification banner
local notif = Instance.new("TextLabel")
notif.Size     = UDim2.fromScale(0.5, 0.07)
notif.Position = UDim2.fromScale(0.25, -0.1)
notif.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
notif.BackgroundTransparency = 0.1
notif.TextColor3 = Color3.new(1,1,1)
notif.TextScaled = true
notif.Font  = Enum.Font.GothamBold
notif.Text  = ""
notif.Visible = false
notif.ZIndex  = 20
notif.Parent  = screenGui
Instance.new("UICorner", notif).CornerRadius = UDim.new(0.2, 0)

local function showNotif(text: string)
  notif.Text    = text
  notif.Visible = true
  TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    { Position = UDim2.fromScale(0.25, 0.06) }):Play()
  task.delay(2.5, function()
    TweenService:Create(notif, TweenInfo.new(0.3),
      { Position = UDim2.fromScale(0.25, -0.1) }):Play()
    task.wait(0.35)
    notif.Visible = false
  end)
end

local rewardColor = {
  xp      = Color3.fromRGB(80, 220, 120),
  credits = Color3.fromRGB(255, 200, 50),
  item    = Color3.fromRGB(160, 120, 255),
}

local function buildQuestRow(q: QuestStore.QuestProgress, tmpl: QuestConfig.QuestTemplate)
  local row = Instance.new("Frame")
  row.Name   = q.questId
  row.Size   = UDim2.fromScale(0.96, 0)
  row.AutomaticSize = Enum.AutomaticSize.Y
  row.BackgroundColor3 = if q.claimed then Color3.fromRGB(30,40,30)
    elseif q.completed then Color3.fromRGB(30,50,30)
    else Color3.fromRGB(30,30,45)
  row.BorderSizePixel = 0
  Instance.new("UICorner", row).CornerRadius = UDim.new(0.05, 0)

  local nameLabel = Instance.new("TextLabel")
  nameLabel.Size   = UDim2.fromScale(1, 0)
  nameLabel.AutomaticSize = Enum.AutomaticSize.Y
  nameLabel.BackgroundTransparency = 1
  nameLabel.TextColor3 = Color3.new(1,1,1)
  nameLabel.TextScaled = false
  nameLabel.TextSize   = 14
  nameLabel.Text       = (if q.completed then "✅ " else "⬜ ") .. tmpl.nameTH
  nameLabel.Font       = Enum.Font.GothamBold
  nameLabel.TextXAlignment = Enum.TextXAlignment.Left
  Instance.new("UIPadding", nameLabel).PaddingLeft = UDim.new(0.03, 0)
  nameLabel.Parent = row

  local desc = Instance.new("TextLabel")
  desc.Size   = UDim2.fromScale(1, 0)
  desc.AutomaticSize = Enum.AutomaticSize.Y
  desc.Position = UDim2.fromScale(0, 0.5)
  desc.BackgroundTransparency = 1
  desc.TextColor3 = Color3.fromRGB(180,180,180)
  desc.TextScaled = false
  desc.TextSize   = 12
  desc.Text = string.format("%s (%d/%d)", tmpl.descTH, q.progress, tmpl.targetCount)
  desc.TextXAlignment = Enum.TextXAlignment.Left
  Instance.new("UIPadding", desc).PaddingLeft = UDim.new(0.03, 0)
  desc.Parent = row

  -- reward chip
  local rw = tmpl.reward
  local rwText = if rw.rewardType == "xp" then "+" .. rw.amount .. " XP"
    elseif rw.rewardType == "credits" then "+" .. rw.amount .. " 💰"
    else "+" .. (rw.itemQty or 1) .. " " .. (rw.itemId or "item")
  local chip = Instance.new("TextLabel")
  chip.Size     = UDim2.fromScale(0.4, 0)
  chip.AutomaticSize = Enum.AutomaticSize.Y
  chip.Position = UDim2.fromScale(0.57, 0.6)
  chip.BackgroundColor3 = rewardColor[rw.rewardType] or Color3.fromRGB(100,100,100)
  chip.BackgroundTransparency = 0.4
  chip.TextColor3 = Color3.new(1,1,1)
  chip.TextScaled = false
  chip.TextSize   = 12
  chip.Text = rwText
  chip.Font = Enum.Font.GothamBold
  Instance.new("UICorner", chip).CornerRadius = UDim.new(0.3, 0)
  chip.Parent = row

  -- claim button
  if q.completed and not q.claimed then
    local claimBtn = Instance.new("TextButton")
    claimBtn.Size   = UDim2.fromScale(0.35, 0)
    claimBtn.AutomaticSize = Enum.AutomaticSize.Y
    claimBtn.Position = UDim2.fromScale(0.62, 0.05)
    claimBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 80)
    claimBtn.TextColor3 = Color3.new(1,1,1)
    claimBtn.TextScaled = false
    claimBtn.TextSize   = 13
    claimBtn.Text = "รับรางวัล"
    claimBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0.2, 0)
    claimBtn.Parent = row
    claimBtn.MouseButton1Click:Connect(function()
      local ok, msg = claimRewardRF:InvokeServer(q.questId)
      if ok then
        showNotif("🎁 " .. rwText)
      else
        showNotif("❌ " .. tostring(msg))
      end
    end)
  end

  return row
end

-- ฟัง type ที่มีใน QuestStore (client ไม่มี require ตรง)
type QuestProgress = { questId: string, progress: number, completed: boolean, claimed: boolean }

local function refreshPanel(quests: { QuestProgress })
  for _, c in scroll:GetChildren() do
    if c:IsA("Frame") then c:Destroy() end
  end
  for _, q in quests do
    local tmpl: QuestConfig.QuestTemplate? = nil
    for _, t in QuestConfig.Templates do
      if t.id == q.questId then tmpl = t; break end
    end
    if tmpl then
      buildQuestRow(q :: any, tmpl).Parent = scroll
    end
  end
end

toggleBtn.MouseButton1Click:Connect(function()
  panel.Visible = not panel.Visible
  if panel.Visible then
    local ok, quests = pcall(function() return getQuestsRF:InvokeServer() end)
    if ok and quests then refreshPanel(quests :: { QuestProgress }) end
  end
end)

questUpdateEv:Connect(function(quests)
  if panel.Visible then
    refreshPanel(quests :: { QuestProgress })
  end
end)

questDoneEv:Connect(function(questId)
  -- หา name จาก template
  for _, tmpl in QuestConfig.Templates do
    if tmpl.id == questId then
      showNotif("🎯 ภารกิจสำเร็จ: " .. tmpl.nameTH)
      break
    end
  end
end)
```

---

## 8. default.project.json — เพิ่ม entries

```json
"QuestConfig":       { "$path": "src/ReplicatedStorage/Modules/QuestConfig.luau" },
"QuestStore":        { "$path": "src/ServerScriptService/Progression/QuestStore.luau" },
"QuestService":      { "$path": "src/ServerScriptService/Progression/QuestService.luau" },
"QuestHandlers":     { "$path": "src/ServerScriptService/Progression/QuestHandlers.server.luau" },
"QuestHUDClient":    { "$path": "src/StarterPlayer/StarterPlayerScripts/QuestHUDClient.client.luau" }
```

---

## สิ่งที่รู้ล่วงหน้า

| ประเด็น | รายละเอียด |
|---------|-----------|
| `visit_zone` quest | progress trigger ยังไม่มี hook — ต้องเพิ่ม proximity zone check ใน client หรือ CharacterAdded (out of scope นี้, progress=0 safe) |
| BindableEvent `NpcKillEvent` | สร้างใน `ReplicatedStorage` โดย QuestHandlers ก่อน CombatService fire |
| `EmotePlayed` จาก EmoteService | server fire ไปที่ client — QuestHandlers ฟัง server-side ไม่ได้ผ่าน `OnServerEvent`; ต้องให้ EmoteService เรียก `QuestService.recordProgress` โดยตรง หรือใช้ BindableEvent แยก |
| `ChatSent` RemoteEvent | ต้องสร้างใน SocialRemoteSetup ด้วย หรือตรวจ `if chatSent` safe อยู่แล้ว |
| `trade_complete` | TradingService ต้อง fire `TradeCompleteEvent` BindableEvent หลัง execute |
| รางวัล `stone_fragment` | ใช้ itemId เดียวกับ `ItemCraftingConfig` ที่มีอยู่แล้ว |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-quest.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ReplicatedStorage/Modules/QuestConfig.luau \
  src/ServerScriptService/Progression/QuestStore.luau \
  src/ServerScriptService/Progression/QuestService.luau \
  src/ServerScriptService/Progression/QuestHandlers.server.luau \
  src/StarterPlayer/StarterPlayerScripts/QuestHUDClient.client.luau
```

## ทดสอบใน Studio (Server console)

```lua
-- จำลอง kill 10 ตัว
local QS = require(game.ServerScriptService.Progression.QuestService)
local p = game.Players:GetPlayers()[1]
for i = 1, 10 do QS.recordProgress(p, "kill_npc", 1) end
-- ดู quest panel ใน client → ควรเห็น ✅ นักล่าเริ่มต้น
```

## Git commit (ถ้า clean)

```bash
git add -A
git commit -m "feat(Quest): Daily Quest / Mission system

- QuestConfig: 8 quest templates (kill/emote/chat/visit/pet/trade), 3/day
- QuestStore: DataStore UtopiaQuest_v1, date-keyed reset UTC+7
- QuestService: daily roll (Fisher-Yates), recordProgress(), claimReward()
- QuestHandlers: wire GetDailyQuests/ClaimQuestReward RF + hook kill/emote/chat/trade
- QuestHUDClient: 📋 panel, progress bars, claim button, notif banner
- CombatService: fire NpcKillEvent BindableEvent after kill"
```

## รายงานกลับ

- ✅/❌ BUILD · ✅/❌ STRICT CLEAN (error+line) · commit hash
- quest roll ใช้งานได้ไหม (server console test)
