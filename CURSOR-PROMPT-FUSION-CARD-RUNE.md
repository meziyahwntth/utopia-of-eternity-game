# CURSOR PROMPT — Fusion System + Card/Rune Socket (P4 ส่วนที่ 2)
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก Pet Drop (aa0df7f)
> Pattern อ้างอิง: CraftingService.luau (P4) · PlayerItemStore.luau · NpcDropService.luau

---

## บริบท

P4 Economy Core (b0856c4) มี Trading P2P + CurrencyService + Crafting/Grandeur แล้ว
ที่ขาดอยู่:
1. **Fusion** — ฟิวส์ไอเทมซ้ำ 2 ชิ้น → ชิ้นเดียวอัพเกรด (เรืองแสง)
2. **Card/Rune Socket** — card จากบอส ใส่ socket ของอาวุธ → สเตตบัฟ

**API ที่มีอยู่แล้ว:**
- `PlayerItemStore.getQty / removeItem / addItem` — `ServerScriptService/Progression/PlayerItemStore`
- `CurrencyService.getBalance / deductCredits` — `ServerScriptService/Commerce/CurrencyService`
- `ItemTierConfig.Items` — ItemDef ใน `ReplicatedStorage/Modules/ItemTierConfig`
- `NpcDropService.grantDrops` — drops cards จาก boss (NPC 5)
- `SocialRemotes` folder อยู่ใน ReplicatedStorage

---

## ไฟล์ที่ต้องสร้าง/แก้

| ไฟล์ | Action | Path |
|------|--------|------|
| `FusionConfig.luau` | สร้างใหม่ | `ReplicatedStorage/Modules/` |
| `CardConfig.luau` | สร้างใหม่ | `ReplicatedStorage/Modules/` |
| `CardStore.luau` | สร้างใหม่ | `ServerScriptService/Progression/` |
| `FusionService.luau` | สร้างใหม่ | `ServerScriptService/Progression/` |
| `CardService.luau` | สร้างใหม่ | `ServerScriptService/Progression/` |
| `FusionHandlers.server.luau` | สร้างใหม่ | `ServerScriptService/Progression/` |
| `CardHandlers.server.luau` | สร้างใหม่ | `ServerScriptService/Progression/` |
| `FusionCardClient.client.luau` | สร้างใหม่ | `StarterPlayerScripts/` |
| `NpcDropConfig.luau` | แก้: เพิ่ม card drop ให้ NPC 5 | `ReplicatedStorage/Modules/` |
| `ItemTierConfig.luau` | แก้: เพิ่ม items ใหม่ + sockets field | `ReplicatedStorage/Modules/` |
| `default.project.json` | แก้: +6 entries ใหม่ | root |

---

## 1. FusionConfig.luau

```lua
--!strict
-- ReplicatedStorage/Modules/FusionConfig.luau
-- ฟิวส์ไอเทมซ้ำ 2 ชิ้น → output อัพเกรด (เรืองแสง)

export type FusionRecipe = {
  inputItem  : string,   -- ไอเทมที่ฟิวส์ (2 ชิ้น)
  outputItem : string,   -- ผลลัพธ์
  creditCost : number,   -- ค่าใช้จ่าย credits
}

return {
  Recipes = {
    { inputItem="StoneFragment",  outputItem="IronOre",         creditCost=50  },
    { inputItem="IronOre",        outputItem="MagicCrystal",    creditCost=100 },
    { inputItem="StarSword2",     outputItem="StarSword3",      creditCost=300 },
    { inputItem="StarSword3",     outputItem="StarSword4",      creditCost=800 },
    { inputItem="CardCommon",     outputItem="CardRare",        creditCost=200 },
    { inputItem="CardRare",       outputItem="CardLegendary",   creditCost=500 },
  } :: { FusionRecipe },
}
```

---

## 2. CardConfig.luau

```lua
--!strict
-- ReplicatedStorage/Modules/CardConfig.luau
-- Card/Rune ใส่ socket ในอาวุธ → stat bonus

export type StatBonus = {
  atkBonus  : number?,   -- +% ATK
  defBonus  : number?,   -- +% DEF
  luckBonus : number?,   -- +% drop rate
  expBonus  : number?,   -- +% XP
}

export type CardDef = {
  id       : string,
  nameTH   : string,
  rarity   : "Common" | "Rare" | "Legendary",
  bonus    : StatBonus,
  iconText : string,     -- emoji icon สำหรับ UI
}

return {
  Cards = {
    CardCommon = {
      id="CardCommon", nameTH="การ์ดทองแดง", rarity="Common",
      bonus={ atkBonus=0.05, expBonus=0.05 },
      iconText="🃏",
    },
    CardRare = {
      id="CardRare", nameTH="การ์ดเงิน", rarity="Rare",
      bonus={ atkBonus=0.12, defBonus=0.08, luckBonus=0.05 },
      iconText="🃏",
    },
    CardLegendary = {
      id="CardLegendary", nameTH="การ์ดทอง", rarity="Legendary",
      bonus={ atkBonus=0.25, defBonus=0.20, luckBonus=0.15, expBonus=0.15 },
      iconText="✨",
    },
  } :: { [string]: CardDef },

  MAX_SOCKETS = 2,   -- ช่องใส่การ์ดต่อผู้เล่น (ขยายได้ตาม tier)
}
```

---

## 3. ItemTierConfig.luau — เพิ่ม items ใหม่

เพิ่มใน `ItemTierConfig.Items`:

```lua
StarSword4 = {
  id="StarSword4", name="★★★★ Sword (Fused)",
  requiredLevel=60, grandeurRank=4, weight=12,
  weaponType="Sword", tradeable=false,  -- fused items ไม่ trade ได้
},
CardCommon = {
  id="CardCommon", name="การ์ดทองแดง",
  requiredLevel=1, grandeurRank=0, weight=0.05,
  weaponType="None", tradeable=true,
},
CardRare = {
  id="CardRare", name="การ์ดเงิน",
  requiredLevel=20, grandeurRank=1, weight=0.05,
  weaponType="None", tradeable=true,
},
CardLegendary = {
  id="CardLegendary", name="การ์ดทอง",
  requiredLevel=40, grandeurRank=2, weight=0.05,
  weaponType="None", tradeable=true,
},
```

---

## 4. CardStore.luau

```lua
--!strict
-- ServerScriptService/Progression/CardStore.luau
-- DataStore สำหรับการ์ดที่ equip ใน socket

local DataStoreService = game:GetService("DataStoreService")
local store = DataStoreService:GetDataStore("UtopiaCard_v1")

export type CardData = {
  equippedCards: { string },   -- cardId ที่ใส่ใน slot (MAX 2)
}

local CardStore = {}

local DEFAULT: CardData = { equippedCards = {} }

function CardStore.load(userId: number): CardData
  local ok, data = pcall(function()
    return store:GetAsync("card_" .. userId)
  end)
  if ok and data then return data :: CardData end
  return table.clone(DEFAULT)
end

function CardStore.save(userId: number, data: CardData)
  local ok, err = pcall(function()
    store:SetAsync("card_" .. userId, data)
  end)
  if not ok then warn("[CardStore] save failed:", err) end
end

return CardStore
```

---

## 5. FusionService.luau

Pattern เดิมจาก `CraftingService.luau`:

```lua
--!strict
-- ServerScriptService/Progression/FusionService.luau

local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local ServerScriptService  = game:GetService("ServerScriptService")

local FusionConfig   = require(ReplicatedStorage.Modules.FusionConfig)
local PlayerItemStore= require(script.Parent.PlayerItemStore)

local function getCurrency()
  return require(ServerScriptService.Commerce.CurrencyService) :: any
end

local FusionService = {}

export type FuseResult = { ok: boolean, reason: string, output: string? }

local function findRecipe(inputItem: string): FusionConfig.FusionRecipe?
  for _, r in FusionConfig.Recipes do
    if r.inputItem == inputItem then return r end
  end
  return nil
end

function FusionService.canFuse(player: Player, inputItem: string): (boolean, string)
  local recipe = findRecipe(inputItem)
  if not recipe then return false, "ไม่พบ recipe สำหรับ " .. inputItem end

  local uid = player.UserId
  if PlayerItemStore.getQty(uid, inputItem) < 2 then
    return false, string.format("ต้องมี %s อย่างน้อย 2 ชิ้น", inputItem)
  end
  local balance = getCurrency().getBalance(uid)
  if balance < recipe.creditCost then
    return false, string.format("credits ไม่พอ (มี %d/%d)", balance, recipe.creditCost)
  end
  return true, "ok"
end

function FusionService.fuse(player: Player, inputItem: string): FuseResult
  local ok, reason = FusionService.canFuse(player, inputItem)
  if not ok then return { ok=false, reason=reason, output=nil } end

  local recipe = findRecipe(inputItem) :: FusionConfig.FusionRecipe
  local uid = player.UserId

  -- ตัดวัตถุดิบ 2 ชิ้น
  if not PlayerItemStore.removeItem(uid, inputItem, 2) then
    return { ok=false, reason="ตัดไอเทมล้มเหลว", output=nil }
  end
  -- ตัด credits
  local deducted = getCurrency().deductCredits(uid, recipe.creditCost)
  if not deducted then
    -- rollback
    PlayerItemStore.addItem(uid, inputItem, 2)
    return { ok=false, reason="ตัด credits ล้มเหลว", output=nil }
  end
  -- ให้ output
  PlayerItemStore.addItem(uid, recipe.outputItem, 1)
  return { ok=true, reason="สำเร็จ", output=recipe.outputItem }
end

function FusionService.getAllRecipes(): { FusionConfig.FusionRecipe }
  return FusionConfig.Recipes
end

return FusionService
```

---

## 6. CardService.luau

```lua
--!strict
-- ServerScriptService/Progression/CardService.luau

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local Players             = game:GetService("Players")

local CardConfig  = require(ReplicatedStorage.Modules.CardConfig)
local CardStore   = require(script.Parent.CardStore)

local CardService = {}

local cache: { [number]: CardStore.CardData } = {}

local function getData(userId: number): CardStore.CardData
  if not cache[userId] then
    cache[userId] = CardStore.load(userId)
  end
  return cache[userId]
end

function CardService.init(player: Player)
  cache[player.UserId] = CardStore.load(player.UserId)
  CardService.applyBonuses(player)
end

function CardService.getEquipped(player: Player): { string }
  return table.clone(getData(player.UserId).equippedCards)
end

function CardService.equipCard(player: Player, cardId: string, slot: number): (boolean, string)
  if not CardConfig.Cards[cardId] then
    return false, "ไม่พบ card: " .. cardId
  end
  if slot < 1 or slot > CardConfig.MAX_SOCKETS then
    return false, "slot ไม่ถูกต้อง"
  end

  local data = getData(player.UserId)
  -- ถ้า slot เกินขนาด array ให้ขยาย
  while #data.equippedCards < slot do
    table.insert(data.equippedCards, "")
  end
  data.equippedCards[slot] = cardId
  task.spawn(function() CardStore.save(player.UserId, data) end)
  CardService.applyBonuses(player)
  return true, "equipped"
end

function CardService.unequipCard(player: Player, slot: number): (boolean, string)
  local data = getData(player.UserId)
  if slot < 1 or slot > #data.equippedCards then
    return false, "slot ว่างอยู่แล้ว"
  end
  data.equippedCards[slot] = ""
  task.spawn(function() CardStore.save(player.UserId, data) end)
  CardService.applyBonuses(player)
  return true, "unequipped"
end

-- รวม bonus จากทุก card ที่ equip แล้ว set เป็น Attribute บน player
function CardService.applyBonuses(player: Player)
  local data = getData(player.UserId)
  local totalAtk, totalDef, totalLuck, totalExp = 0, 0, 0, 0

  for _, cardId in data.equippedCards do
    local def = CardConfig.Cards[cardId]
    if def then
      totalAtk  += def.bonus.atkBonus  or 0
      totalDef  += def.bonus.defBonus  or 0
      totalLuck += def.bonus.luckBonus or 0
      totalExp  += def.bonus.expBonus  or 0
    end
  end

  player:SetAttribute("CardAtkBonus",  totalAtk)
  player:SetAttribute("CardDefBonus",  totalDef)
  player:SetAttribute("CardLuckBonus", totalLuck)
  player:SetAttribute("CardExpBonus",  totalExp)
end

Players.PlayerRemoving:Connect(function(p)
  cache[p.UserId] = nil
end)

return CardService
```

---

## 7. FusionHandlers.server.luau

```lua
--!strict
-- ServerScriptService/Progression/FusionHandlers.server.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FusionService     = require(script.Parent.FusionService)
local remotes           = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local function ensure(t: string, name: string)
  local r = remotes:FindFirstChild(name)
  if not r then
    r = Instance.new(t)
    r.Name = name
    r.Parent = remotes
  end
  return r
end

local GetAllFusionRecipesRF = ensure("RemoteFunction", "GetAllFusionRecipes")  :: RemoteFunction
local FuseItemRF            = ensure("RemoteFunction", "FuseItem")             :: RemoteFunction

GetAllFusionRecipesRF.OnServerInvoke = function(_player: Player)
  return FusionService.getAllRecipes()
end

FuseItemRF.OnServerInvoke = function(player: Player, inputItem: any)
  if typeof(inputItem) ~= "string" then
    return { ok=false, reason="invalid input", output=nil }
  end
  return FusionService.fuse(player, inputItem)
end
```

---

## 8. CardHandlers.server.luau

```lua
--!strict
-- ServerScriptService/Progression/CardHandlers.server.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CardService       = require(script.Parent.CardService)
local Players           = game:GetService("Players")
local remotes           = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local function ensure(t: string, name: string)
  local r = remotes:FindFirstChild(name)
  if not r then
    r = Instance.new(t)
    r.Name = name
    r.Parent = remotes
  end
  return r
end

local GetEquippedCardsRF = ensure("RemoteFunction", "GetEquippedCards") :: RemoteFunction
local EquipCardRF        = ensure("RemoteFunction", "EquipCard")        :: RemoteFunction
local UnequipCardRF      = ensure("RemoteFunction", "UnequipCard")      :: RemoteFunction

GetEquippedCardsRF.OnServerInvoke = function(player: Player)
  return CardService.getEquipped(player)
end

EquipCardRF.OnServerInvoke = function(player: Player, cardId: any, slot: any)
  if typeof(cardId) ~= "string" or typeof(slot) ~= "number" then
    return false, "invalid args"
  end
  return CardService.equipCard(player, cardId, math.floor(slot))
end

UnequipCardRF.OnServerInvoke = function(player: Player, slot: any)
  if typeof(slot) ~= "number" then return false, "invalid slot" end
  return CardService.unequipCard(player, math.floor(slot))
end

-- init card bonuses เมื่อ player join
Players.PlayerAdded:Connect(function(player)
  CardService.init(player)
end)
for _, p in Players:GetPlayers() do
  CardService.init(p)
end
```

---

## 9. FusionCardClient.client.luau

UI รวมใน panel เดียว (⚗️ Fusion + 🃏 Cards):

```lua
--!strict
-- StarterPlayerScripts/FusionCardClient.client.luau

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui") :: PlayerGui
local remotes     = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local getFusionRecipesRF = remotes:WaitForChild("GetAllFusionRecipes") :: RemoteFunction
local fuseItemRF         = remotes:WaitForChild("FuseItem")            :: RemoteFunction
local getEquippedRF      = remotes:WaitForChild("GetEquippedCards")    :: RemoteFunction
local equipCardRF        = remotes:WaitForChild("EquipCard")           :: RemoteFunction
local unequipCardRF      = remotes:WaitForChild("UnequipCard")         :: RemoteFunction

-- ========= Shared UI helpers =========
local DARK    = Color3.fromRGB(10, 15, 30)
local ACCENT  = Color3.fromRGB(80, 200, 255)
local GOLD    = Color3.fromRGB(255, 200, 50)
local SUCCESS = Color3.fromRGB(80, 220, 120)
local FAIL    = Color3.fromRGB(220, 80, 80)

local function makeLabel(parent: Instance, text: string, size: UDim2, pos: UDim2, color: Color3?): TextLabel
  local l = Instance.new("TextLabel")
  l.Size = size
  l.Position = pos
  l.BackgroundTransparency = 1
  l.Text = text
  l.TextColor3 = color or Color3.new(1,1,1)
  l.Font = Enum.Font.GothamBold
  l.TextSize = 13
  l.TextXAlignment = Enum.TextXAlignment.Left
  l.Parent = parent
  return l
end

local function makeBtn(parent: Instance, text: string, size: UDim2, pos: UDim2, color: Color3): TextButton
  local b = Instance.new("TextButton")
  b.Size = size
  b.Position = pos
  b.BackgroundColor3 = color
  b.BorderSizePixel = 0
  b.Text = text
  b.TextColor3 = Color3.new(1,1,1)
  b.Font = Enum.Font.GothamBold
  b.TextSize = 13
  b.Parent = parent
  Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
  return b
end

-- ========= Main ScreenGui =========
local sg = Instance.new("ScreenGui")
sg.Name = "FusionCardGui"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = playerGui

-- Toggle button (bottom bar)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromOffset(100, 36)
toggleBtn.Position = UDim2.new(0, 8, 1, -88)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 120)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "⚗️ Fusion"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
toggleBtn.Parent = sg
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,8)

-- Main Panel
local panel = Instance.new("Frame")
panel.Name = "FusionCardPanel"
panel.Size = UDim2.fromOffset(440, 380)
panel.Position = UDim2.new(0.5, -220, 0.5, -190)
panel.BackgroundColor3 = DARK
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = sg
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,10)

-- Header
local header = makeLabel(panel, "⚗️ Fusion & 🃏 Cards", UDim2.new(1,-80,0,32), UDim2.fromOffset(12,8), ACCENT)
header.TextSize = 15

local closeBtn = makeBtn(panel, "✕", UDim2.fromOffset(32,32), UDim2.new(1,-40,0,8), Color3.fromRGB(160,40,40))
closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)

-- Tab buttons
local tabFusion = makeBtn(panel, "⚗️ Fusion", UDim2.fromOffset(100,28), UDim2.fromOffset(12,48), Color3.fromRGB(60,100,160))
local tabCards  = makeBtn(panel, "🃏 Cards",  UDim2.fromOffset(100,28), UDim2.fromOffset(120,48), Color3.fromRGB(80,50,120))

-- Status label
local statusLabel = makeLabel(panel, "", UDim2.new(1,-16,0,20), UDim2.fromOffset(8,358), SUCCESS)
statusLabel.TextXAlignment = Enum.TextXAlignment.Center

-- ======= Fusion Tab =======
local fusionFrame = Instance.new("Frame")
fusionFrame.Size = UDim2.new(1,-16,0,290)
fusionFrame.Position = UDim2.fromOffset(8,82)
fusionFrame.BackgroundTransparency = 1
fusionFrame.Parent = panel

local fusionList = Instance.new("ScrollingFrame")
fusionList.Size = UDim2.fromScale(1,1)
fusionList.BackgroundTransparency = 1
fusionList.ScrollBarThickness = 4
fusionList.Parent = fusionFrame
Instance.new("UIListLayout", fusionList).Padding = UDim.new(0,6)

-- ======= Card Tab =======
local cardFrame = Instance.new("Frame")
cardFrame.Size = UDim2.new(1,-16,0,290)
cardFrame.Position = UDim2.fromOffset(8,82)
cardFrame.BackgroundTransparency = 1
cardFrame.Visible = false
cardFrame.Parent = panel

-- Socket labels (2 slots)
local slotLabels: { TextLabel } = {}
local slotBtns:  { TextButton } = {}
for i = 1, 2 do
  local y = (i-1)*80 + 10
  local slotBg = Instance.new("Frame")
  slotBg.Size = UDim2.fromOffset(420,70)
  slotBg.Position = UDim2.fromOffset(0, y)
  slotBg.BackgroundColor3 = Color3.fromRGB(20,30,55)
  slotBg.BorderSizePixel = 0
  slotBg.Parent = cardFrame
  Instance.new("UICorner", slotBg).CornerRadius = UDim.new(0,6)

  local lbl = makeLabel(slotBg, "Socket "..i..": (ว่าง)", UDim2.fromOffset(300,70), UDim2.fromOffset(8,0), GOLD)
  lbl.TextYAlignment = Enum.TextYAlignment.Center
  table.insert(slotLabels, lbl)

  local unBtn = makeBtn(slotBg, "ถอด", UDim2.fromOffset(60,30), UDim2.new(1,-70,0,20), FAIL)
  table.insert(slotBtns, unBtn)

  local slot = i
  unBtn.MouseButton1Click:Connect(function()
    local ok, msg = pcall(function() return unequipCardRF:InvokeServer(slot) end)
    statusLabel.Text = if ok then "✅ ถอดการ์ด slot "..slot else "❌ "..tostring(msg)
    statusLabel.TextColor3 = if ok then SUCCESS else FAIL
    refreshCards()
  end)
end

-- card inventory list
local cardInventoryList = Instance.new("Frame")
cardInventoryList.Size = UDim2.fromOffset(420,140)
cardInventoryList.Position = UDim2.fromOffset(0,170)
cardInventoryList.BackgroundTransparency = 1
cardInventoryList.Parent = cardFrame
Instance.new("UIListLayout", cardInventoryList).Padding = UDim.new(0,4)

-- ======= Tab switching =======
tabFusion.MouseButton1Click:Connect(function()
  fusionFrame.Visible = true
  cardFrame.Visible = false
  tabFusion.BackgroundColor3 = Color3.fromRGB(60,100,160)
  tabCards.BackgroundColor3  = Color3.fromRGB(80,50,120)
end)
tabCards.MouseButton1Click:Connect(function()
  fusionFrame.Visible = false
  cardFrame.Visible = true
  tabFusion.BackgroundColor3 = Color3.fromRGB(40,60,110)
  tabCards.BackgroundColor3  = Color3.fromRGB(100,70,150)
  refreshCards()
end)

-- ======= Refresh Fusion List =======
local function refreshFusion()
  for _, c in fusionList:GetChildren() do
    if c:IsA("Frame") then c:Destroy() end
  end
  local ok, recipes = pcall(function() return getFusionRecipesRF:InvokeServer() end)
  if not ok or not recipes then return end

  for _, recipe in (recipes :: { any }) do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,44)
    row.BackgroundColor3 = Color3.fromRGB(18,26,48)
    row.BorderSizePixel = 0
    row.Parent = fusionList
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)

    makeLabel(row,
      string.format("⚗️  %s × 2  →  %s  (💰%d)", recipe.inputItem, recipe.outputItem, recipe.creditCost),
      UDim2.fromOffset(300,44), UDim2.fromOffset(8,0))

    local fuseBtn = makeBtn(row, "Fuse", UDim2.fromOffset(70,30), UDim2.new(1,-80,0,7), ACCENT)
    fuseBtn.TextColor3 = DARK
    local inp = recipe.inputItem
    fuseBtn.MouseButton1Click:Connect(function()
      local res: any = pcall(function() return fuseItemRF:InvokeServer(inp) end)
      if type(res) == "table" then
        statusLabel.Text = if res.ok then "✅ ได้ "..tostring(res.output) else "❌ "..tostring(res.reason)
        statusLabel.TextColor3 = if res.ok then SUCCESS else FAIL
      end
    end)
  end
end

-- ======= Refresh Card Slots =======
function refreshCards()
  local ok, cards = pcall(function() return getEquippedRF:InvokeServer() end)
  if not ok or not cards then return end
  for i, lbl in slotLabels do
    local cardId: string = (cards :: { string })[i] or ""
    lbl.Text = string.format("Socket %d: %s", i, if cardId ~= "" then cardId else "(ว่าง)")
  end
end

-- Toggle open/close
toggleBtn.MouseButton1Click:Connect(function()
  panel.Visible = not panel.Visible
  if panel.Visible then
    refreshFusion()
  end
end)
```

---

## 10. NpcDropConfig.luau — เพิ่ม card drop จาก Boss (NPC 5)

เพิ่มต่อท้าย dropTable ของ NPC 5:

```lua
{ dropType="item", itemId="CardCommon",    petId=nil, minQty=1, maxQty=1, chance=0.15 },
{ dropType="item", itemId="CardRare",      petId=nil, minQty=1, maxQty=1, chance=0.05 },
{ dropType="item", itemId="CardLegendary", petId=nil, minQty=1, maxQty=1, chance=0.01 },
-- Boss: 15% CardCommon, 5% CardRare, 1% CardLegendary
```

---

## 11. default.project.json — เพิ่ม 6 entries

```json
"FusionConfig":       { "$path": "src/ReplicatedStorage/Modules/FusionConfig.luau" },
"CardConfig":         { "$path": "src/ReplicatedStorage/Modules/CardConfig.luau" },
"CardStore":          { "$path": "src/ServerScriptService/Progression/CardStore.luau" },
"FusionService":      { "$path": "src/ServerScriptService/Progression/FusionService.luau" },
"CardService":        { "$path": "src/ServerScriptService/Progression/CardService.luau" },
"FusionHandlers":     { "$path": "src/ServerScriptService/Progression/FusionHandlers.server.luau" },
"CardHandlers":       { "$path": "src/ServerScriptService/Progression/CardHandlers.server.luau" },
"FusionCardClient":   { "$path": "src/StarterPlayer/StarterPlayerScripts/FusionCardClient.client.luau" }
```

---

## สิ่งที่รู้ล่วงหน้า

| ประเด็น | รายละเอียด |
|---------|-----------|
| CardExpBonus Attribute | CardService.applyBonuses() set `CardExpBonus` → PlayerLevelService.addExp() ควร `* (1 + player:GetAttribute("CardExpBonus") or 0)` — optional follow-up |
| CardLuckBonus | PlayerItemStore.addItem() แล้วมี PetLuckBonus pattern → เพิ่ม CardLuckBonus stack ได้ |
| Fusion StarSword4 | tradeable=false เพราะ fused item ไม่ควรเข้า P2P market ง่ายเกิน |
| CardStore DataStore | ใช้ `UtopiaCard_v1` แยกจาก `UtopiaLevel_v1` / `UtopiaQuest_v1` |
| dropType ใน NPC 5 card entries | ใช้ `dropType="item"` (cards เป็น item ปกติ ไม่ใช่ pet) |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-fusion-card.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ReplicatedStorage/Modules/FusionConfig.luau \
  src/ReplicatedStorage/Modules/CardConfig.luau \
  src/ServerScriptService/Progression/CardStore.luau \
  src/ServerScriptService/Progression/FusionService.luau \
  src/ServerScriptService/Progression/CardService.luau \
  src/ServerScriptService/Progression/FusionHandlers.server.luau \
  src/ServerScriptService/Progression/CardHandlers.server.luau \
  src/StarterPlayer/StarterPlayerScripts/FusionCardClient.client.luau
```

## ทดสอบใน Studio

```lua
-- Server console: fuse StarSword2 × 2
local FS = require(game.ServerScriptService.Progression.FusionService)
local IS = require(game.ServerScriptService.Progression.PlayerItemStore)
local p = game.Players:GetPlayers()[1]
IS.addItem(p.UserId, "StarSword2", 2)
print(FS.fuse(p, "StarSword2"))  -- { ok=true, output="StarSword3" }

-- เพิ่ม card แล้ว equip
IS.addItem(p.UserId, "CardRare", 1)
local CS = require(game.ServerScriptService.Progression.CardService)
print(CS.equipCard(p, "CardRare", 1))  -- true, "equipped"
print(p:GetAttribute("CardAtkBonus"))   -- 0.12
```

## Git commit

```bash
git add -A
git commit -m "feat(P4): Fusion system + Card/Rune socket

- FusionConfig: 6 fusion recipes (item×2→upgrade, creditCost)
- CardConfig: 3 card tiers (Common/Rare/Legendary) with stat bonuses
- CardStore: DataStore UtopiaCard_v1 for equipped slots
- FusionService: canFuse + fuse (best-effort rollback)
- CardService: equipCard/unequipCard + applyBonuses (Attributes)
- FusionHandlers + CardHandlers: SocialRemotes RF
- FusionCardClient: ⚗️ Fusion tab + 🃏 Cards tab in one panel
- NpcDropConfig NPC5: +CardCommon 15% / CardRare 5% / CardLegendary 1%"
```

## รายงานกลับ

- ✅/❌ BUILD · ✅/❌ STRICT CLEAN · commit hash
- ทดสอบ: fuse StarSword2 → ได้ StarSword3 ไหม / equip CardRare → CardAtkBonus=0.12 ไหม
