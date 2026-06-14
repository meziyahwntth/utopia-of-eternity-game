# CURSOR PROMPT — Crafting / Grandeur System
> สร้าง: 13 มิ.ย. 2026 · ต่อจาก NPC Item Drop (1538dba)
> อ้างอิง: `ItemCraftingConfig.Grandeur` (มีอยู่แล้ว), `PlayerItemStore`, `CurrencyService`

---

## บริบท

ระบบ Crafting แบบ "Grandeur Upgrade" — นำไอเทม base + วัตถุดิบ + credits → อัปเกรดเป็น output ที่ดีกว่า
เป็น material sink หลักของเกม (ป้องกัน inflation)

**API ที่มีอยู่แล้ว (ห้ามเขียนซ้ำ):**
- `ItemCraftingConfig.Grandeur` — recipes ใน `ReplicatedStorage/Modules/ItemCraftingConfig.luau`
  - `StarSword3`: baseItem=StarSword2, StoneFragment×500, IronOre×200, MagicCrystal×50, creditCost=1000
- `PlayerItemStore.getInventory/getQty/addItem/removeItem` — `ServerScriptService/Progression/PlayerItemStore`
- `CurrencyService.getBalance/deductCredits` — `ServerScriptService/Commerce/CurrencyService`
- Remotes อยู่ใน `ReplicatedStorage/SocialRemotes`

---

## ไฟล์ที่ต้องสร้าง

| ไฟล์ | Path |
|------|------|
| `CraftingService.luau` | `ServerScriptService/Progression/` |
| `CraftingHandlers.server.luau` | `ServerScriptService/Progression/` |
| `CraftingClient.client.luau` | `StarterPlayerScripts/` |

---

## 1. CraftingService.luau

```lua
--!strict
-- ServerScriptService/Progression/CraftingService.luau

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ItemCraftingConfig = require(ReplicatedStorage.Modules.ItemCraftingConfig)
local PlayerItemStore    = require(script.Parent.PlayerItemStore)

local function getCurrency()
  return require(ServerScriptService.Commerce.CurrencyService) :: any
end

local CraftingService = {}

export type CraftResult = {
  ok      : boolean,
  reason  : string,
  output  : string?,   -- outputItem ถ้าสำเร็จ
}

-- ตรวจสอบว่ามี recipe สำหรับ outputItem นี้ไหม
local function findRecipe(outputItem: string): ItemCraftingConfig.GrandeurRecipe?
  return ItemCraftingConfig.Grandeur[outputItem]
end

-- คืน true ถ้า player มี base item + materials + credits ครบ
function CraftingService.canCraft(player: Player, outputItem: string): (boolean, string)
  local recipe = findRecipe(outputItem)
  if not recipe then return false, "ไม่พบ recipe" end

  local uid = player.UserId

  -- ตรวจ base item
  if PlayerItemStore.getQty(uid, recipe.baseItem) < 1 then
    return false, "ต้องมี " .. recipe.baseItem
  end

  -- ตรวจวัตถุดิบ
  for _, mat in recipe.materials do
    local have = PlayerItemStore.getQty(uid, mat.id)
    if have < mat.qty then
      return false, string.format("ขาด %s (มี %d/%d)", mat.id, have, mat.qty)
    end
  end

  -- ตรวจ credits
  local balance = getCurrency().getBalance(uid)
  if balance < recipe.creditCost then
    return false, string.format("credits ไม่พอ (มี %d/%d)", balance, recipe.creditCost)
  end

  return true, "ok"
end

-- ทำการ craft จริง (server-authoritative)
function CraftingService.craft(player: Player, outputItem: string): CraftResult
  local ok, reason = CraftingService.canCraft(player, outputItem)
  if not ok then
    return { ok = false, reason = reason, output = nil }
  end

  local recipe = findRecipe(outputItem) :: ItemCraftingConfig.GrandeurRecipe
  local uid    = player.UserId

  -- ตัด base item
  local removedBase = PlayerItemStore.removeItem(uid, recipe.baseItem, 1)
  if not removedBase then
    return { ok = false, reason = "ตัด base item ล้มเหลว", output = nil }
  end

  -- ตัดวัตถุดิบ
  for _, mat in recipe.materials do
    local removedMat = PlayerItemStore.removeItem(uid, mat.id, mat.qty)
    if not removedMat then
      -- rollback base item (best-effort)
      PlayerItemStore.addItem(uid, recipe.baseItem, 1)
      return { ok = false, reason = "ตัด " .. mat.id .. " ล้มเหลว", output = nil }
    end
  end

  -- ตัด credits
  local deducted, errMsg = getCurrency().deductCredits(uid, recipe.creditCost)
  if not deducted then
    -- rollback items (best-effort)
    PlayerItemStore.addItem(uid, recipe.baseItem, 1)
    for _, mat in recipe.materials do
      PlayerItemStore.addItem(uid, mat.id, mat.qty)
    end
    return { ok = false, reason = "ตัด credits ล้มเหลว: " .. tostring(errMsg), output = nil }
  end

  -- มอบ output
  PlayerItemStore.addItem(uid, recipe.outputItem, 1)

  return { ok = true, reason = "สำเร็จ!", output = recipe.outputItem }
end

-- รายการ recipe ที่ craft ได้ทั้งหมด (สำหรับ client แสดง UI)
function CraftingService.getAllRecipes(): { [string]: ItemCraftingConfig.GrandeurRecipe }
  return ItemCraftingConfig.Grandeur
end

-- รายการที่ player craft ได้ตอนนี้ (กรองตาม inventory)
function CraftingService.getAvailableRecipes(player: Player): { string }
  local available: { string } = {}
  for outputItem in ItemCraftingConfig.Grandeur do
    local canDo, _ = CraftingService.canCraft(player, outputItem)
    if canDo then
      table.insert(available, outputItem)
    end
  end
  return available
end

return CraftingService
```

---

## 2. CraftingHandlers.server.luau

```lua
--!strict
-- ServerScriptService/Progression/CraftingHandlers.server.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CraftingService   = require(script.Parent.CraftingService)

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local function ensure(cls: string, name: string)
  if not remotes:FindFirstChild(name) then
    local i = Instance.new(cls); i.Name = name; i.Parent = remotes
  end
end
ensure("RemoteFunction", "GetAllRecipes")
ensure("RemoteFunction", "CraftItem")
ensure("RemoteFunction", "GetInventory")

local getAllRecipesRF = remotes:WaitForChild("GetAllRecipes") :: RemoteFunction
local craftItemRF    = remotes:WaitForChild("CraftItem")     :: RemoteFunction
local getInventoryRF = remotes:WaitForChild("GetInventory")  :: RemoteFunction

local PlayerItemStore = require(
  game:GetService("ServerScriptService").Progression.PlayerItemStore
)

getAllRecipesRF.OnServerInvoke = function(_player)
  return CraftingService.getAllRecipes()
end

craftItemRF.OnServerInvoke = function(player, outputItem)
  return CraftingService.craft(player, outputItem :: string)
end

-- ให้ client ดู inventory ผ่าน RF (ปลอดภัยกว่า attribute)
getInventoryRF.OnServerInvoke = function(player)
  return PlayerItemStore.getInventory(player.UserId)
end
```

---

## 3. CraftingClient.client.luau

```lua
--!strict
-- StarterPlayerScripts/CraftingClient.client.luau

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local localPlayer    = Players.LocalPlayer
local remotes        = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local getAllRF        = remotes:WaitForChild("GetAllRecipes") :: RemoteFunction
local craftRF        = remotes:WaitForChild("CraftItem")     :: RemoteFunction
local getInventoryRF = remotes:WaitForChild("GetInventory")  :: RemoteFunction

local screenGui = Instance.new("ScreenGui")
screenGui.Name         = "CraftingUI"
screenGui.ResetOnSpawn = false
screenGui.Parent       = localPlayer.PlayerGui

-- ปุ่มเปิด (มุมขวาบน ใต้ Quest panel)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size     = UDim2.fromScale(0.07, 0.05)
toggleBtn.Position = UDim2.fromScale(0.92, 0.145)
toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 20)
toggleBtn.TextScaled= true
toggleBtn.Text     = "⚒"
toggleBtn.Parent   = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0.2, 0)

-- Main panel
local panel = Instance.new("Frame")
panel.Size     = UDim2.fromScale(0.38, 0.55)
panel.Position = UDim2.fromScale(0.61, 0.08)
panel.BackgroundColor3 = Color3.fromRGB(22, 18, 12)
panel.BackgroundTransparency = 0.05
panel.Visible  = false
panel.Parent   = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0.02, 0)

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.fromScale(1, 0.1)
titleBar.BackgroundColor3 = Color3.fromRGB(80, 50, 20)
titleBar.Parent = panel
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0.04, 0)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.fromScale(0.85, 1)
titleLbl.BackgroundTransparency = 1
titleLbl.TextColor3 = Color3.new(1, 0.9, 0.6)
titleLbl.TextScaled = true
titleLbl.Font = Enum.Font.GothamBold
titleLbl.Text = "⚒ Crafting — Grandeur Upgrade"
titleLbl.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size  = UDim2.fromScale(0.1, 0.8)
closeBtn.Position = UDim2.fromScale(0.89, 0.1)
closeBtn.Text  = "✕"
closeBtn.TextScaled = true
closeBtn.BackgroundTransparency = 1
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)

-- Left: recipe list scroll
local recipeScroll = Instance.new("ScrollingFrame")
recipeScroll.Size             = UDim2.fromScale(0.4, 0.87)
recipeScroll.Position         = UDim2.fromScale(0.01, 0.12)
recipeScroll.BackgroundColor3 = Color3.fromRGB(15, 12, 8)
recipeScroll.ScrollBarThickness = 4
recipeScroll.CanvasSize       = UDim2.fromScale(0, 0)
recipeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
recipeScroll.Parent           = panel
Instance.new("UIListLayout", recipeScroll).Padding = UDim.new(0, 3)

-- Right: detail panel
local detailPanel = Instance.new("Frame")
detailPanel.Size     = UDim2.fromScale(0.56, 0.87)
detailPanel.Position = UDim2.fromScale(0.43, 0.12)
detailPanel.BackgroundColor3 = Color3.fromRGB(18, 15, 10)
detailPanel.Parent   = panel
Instance.new("UICorner", detailPanel).CornerRadius = UDim.new(0.03, 0)

local detailTitle = Instance.new("TextLabel")
detailTitle.Size = UDim2.fromScale(1, 0.12)
detailTitle.BackgroundTransparency = 1
detailTitle.TextColor3 = Color3.new(1, 0.9, 0.5)
detailTitle.TextScaled = true
detailTitle.Font = Enum.Font.GothamBold
detailTitle.Text = "เลือก recipe"
detailTitle.Parent = detailPanel

local materialsLbl = Instance.new("TextLabel")
materialsLbl.Size     = UDim2.fromScale(1, 0.55)
materialsLbl.Position = UDim2.fromScale(0, 0.13)
materialsLbl.BackgroundTransparency = 1
materialsLbl.TextColor3 = Color3.fromRGB(200, 200, 180)
materialsLbl.TextScaled = false
materialsLbl.TextSize   = 13
materialsLbl.Font       = Enum.Font.Gotham
materialsLbl.TextXAlignment = Enum.TextXAlignment.Left
materialsLbl.TextYAlignment = Enum.TextYAlignment.Top
materialsLbl.TextWrapped    = true
Instance.new("UIPadding", materialsLbl).PaddingLeft = UDim.new(0.03, 0)
materialsLbl.Text = ""
materialsLbl.Parent = detailPanel

local craftBtn = Instance.new("TextButton")
craftBtn.Size     = UDim2.fromScale(0.85, 0.13)
craftBtn.Position = UDim2.fromScale(0.075, 0.84)
craftBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 10)
craftBtn.TextColor3 = Color3.fromRGB(200, 180, 100)
craftBtn.TextScaled = true
craftBtn.Font = Enum.Font.GothamBold
craftBtn.Text = "Craft"
craftBtn.Parent = detailPanel
Instance.new("UICorner", craftBtn).CornerRadius = UDim.new(0.2, 0)

-- Status label
local statusLbl = Instance.new("TextLabel")
statusLbl.Size     = UDim2.fromScale(1, 0.1)
statusLbl.Position = UDim2.fromScale(0, 0.7)
statusLbl.BackgroundTransparency = 1
statusLbl.TextColor3 = Color3.fromRGB(100, 255, 120)
statusLbl.TextScaled = false
statusLbl.TextSize   = 13
statusLbl.Text = ""
statusLbl.Parent = detailPanel

local selectedOutputItem: string? = nil

-- types ที่รับจาก server (mirror ของ GrandeurRecipe)
type MaterialReq = { id: string, qty: number }
type GrandeurRecipe = {
  baseItem: string, materials: { MaterialReq },
  creditCost: number, outputItem: string
}

local function buildMaterialText(recipe: GrandeurRecipe, inventory: { [string]: number }): string
  local lines = { "📦 Base: " .. recipe.baseItem
    .. "  (มี " .. tostring(inventory[recipe.baseItem] or 0) .. ")" }
  for _, mat in recipe.materials do
    local have = inventory[mat.id] or 0
    local tick = if have >= mat.qty then "✅" else "❌"
    table.insert(lines, string.format("%s %s ×%d (มี %d)", tick, mat.id, mat.qty, have))
  end
  local balance = inventory["__credits__"] or 0
  local creditTick = if balance >= recipe.creditCost then "✅" else "❌"
  table.insert(lines, string.format("%s Credits: %d (มี %d)", creditTick, recipe.creditCost, balance))
  return table.concat(lines, "\n")
end

local function showDetail(outputItem: string, recipe: GrandeurRecipe, inventory: { [string]: number })
  selectedOutputItem = outputItem
  detailTitle.Text   = "⚔ → " .. outputItem
  materialsLbl.Text  = buildMaterialText(recipe, inventory)
  statusLbl.Text     = ""
end

local function showStatus(msg: string, success: boolean)
  statusLbl.Text       = msg
  statusLbl.TextColor3 = if success then Color3.fromRGB(80,255,100) else Color3.fromRGB(255,80,80)
  task.delay(3, function() statusLbl.Text = "" end)
end

local function buildRecipeList(recipes: { [string]: GrandeurRecipe }, inventory: { [string]: number })
  for _, c in recipeScroll:GetChildren() do
    if c:IsA("TextButton") then c:Destroy() end
  end
  for outputItem, recipe in recipes do
    local have = inventory[recipe.baseItem] or 0
    local canCraft = have >= 1
    local btn = Instance.new("TextButton")
    btn.Size   = UDim2.fromScale(0.96, 0)
    btn.AutomaticSize = Enum.AutomaticSize.Y
    btn.BackgroundColor3 = if canCraft then Color3.fromRGB(50,35,15) else Color3.fromRGB(30,30,30)
    btn.TextColor3 = if canCraft then Color3.new(1,0.9,0.5) else Color3.fromRGB(120,120,120)
    btn.TextScaled = false
    btn.TextSize   = 13
    btn.Font       = Enum.Font.GothamBold
    btn.Text       = (if canCraft then "⚒ " else "🔒 ") .. outputItem
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0.05, 0)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0.1, 0)
    btn.Parent = recipeScroll
    btn.MouseButton1Click:Connect(function()
      showDetail(outputItem, recipe, inventory)
    end)
  end
end

local function refreshUI()
  local okR, recipes = pcall(function() return getAllRF:InvokeServer() end)
  local okI, inventory = pcall(function() return getInventoryRF:InvokeServer() end)
  if not okR or not okI then return end

  -- inject credits สำหรับ display
  local inv = inventory :: { [string]: number }
  local creditBalance = localPlayer:GetAttribute("PlayerCredits")
  inv["__credits__"] = if typeof(creditBalance) == "number" then creditBalance else 0

  buildRecipeList(recipes :: { [string]: GrandeurRecipe }, inv)
  if selectedOutputItem then
    local r = (recipes :: { [string]: GrandeurRecipe })[selectedOutputItem]
    if r then showDetail(selectedOutputItem, r, inv) end
  end
end

toggleBtn.MouseButton1Click:Connect(function()
  panel.Visible = not panel.Visible
  if panel.Visible then refreshUI() end
end)

craftBtn.MouseButton1Click:Connect(function()
  if not selectedOutputItem then return end
  craftBtn.Active = false
  craftBtn.Text   = "กำลัง Craft..."

  local ok, result = pcall(function()
    return craftRF:InvokeServer(selectedOutputItem)
  end)

  craftBtn.Active = true
  craftBtn.Text   = "Craft"

  if ok and result then
    local res = result :: { ok: boolean, reason: string, output: string? }
    showStatus(if res.ok then "✨ ได้รับ " .. tostring(res.output) .. "!" else "❌ " .. res.reason, res.ok)
    if res.ok then
      task.wait(0.5)
      refreshUI()
    end
  else
    showStatus("❌ เชื่อมต่อล้มเหลว", false)
  end
end)
```

---

## 4. ItemCraftingConfig.luau — เพิ่ม recipes ทดสอบ

เพิ่มใน `ItemCraftingConfig.Grandeur` นอกจาก StarSword3:

```lua
["StarSword2"] = {
  baseItem = "StarSword1",
  materials = {
    { id = "StoneFragment", qty = 100 },
    { id = "IronOre",       qty = 30 },
  },
  creditCost = 200,
  outputItem = "StarSword2",
},
["IronArmor1"] = {
  baseItem = "LeatherArmor",
  materials = {
    { id = "IronOre",       qty = 50 },
    { id = "StoneFragment", qty = 20 },
  },
  creditCost = 150,
  outputItem = "IronArmor1",
},
```

---

## 5. default.project.json — เพิ่ม entries

```json
"CraftingService":    { "$path": "src/ServerScriptService/Progression/CraftingService.luau" },
"CraftingHandlers":   { "$path": "src/ServerScriptService/Progression/CraftingHandlers.server.luau" },
"CraftingClient":     { "$path": "src/StarterPlayer/StarterPlayerScripts/CraftingClient.client.luau" }
```

---

## สิ่งที่รู้ล่วงหน้า

| ประเด็น | รายละเอียด |
|---------|-----------|
| Rollback partial | removeItem เรียกทีละ material — ถ้า fail กลางทาง จะ addItem คืน (best-effort, ไม่ใช่ transaction) |
| `__credits__` key ใน inventory | ใช้เฉพาะ client display — ไม่เขียนลง DataStore |
| `PlayerCredits` attribute | ถ้า CurrencyService เขียน attribute นี้บน player → ใช้ได้เลย; ถ้าไม่มีให้ query ผ่าน RF แยก |
| StarSword1 / LeatherArmor | ยังไม่ต้องมีจริงใน inventory — craft จะ fail ที่ canCraft() อย่างถูกต้อง |
| `getInventoryRF` | ให้ client เห็น inventory ผ่าน server เท่านั้น — ไม่ expose DataStore key โดยตรง |

---

## คำสั่ง Verify

```bash
cd ~/Desktop/Utopia\ of\ Eternity/utopia-of-eternity-game
rojo build default.project.json --output /tmp/utopia-craft.rbxlx

luau-lsp analyze --definitions=roblox.d.luau \
  src/ReplicatedStorage/Modules/ItemCraftingConfig.luau \
  src/ServerScriptService/Progression/CraftingService.luau \
  src/ServerScriptService/Progression/CraftingHandlers.server.luau \
  src/StarterPlayer/StarterPlayerScripts/CraftingClient.client.luau
```

## ทดสอบใน Studio (Server console)

```lua
-- ให้วัตถุดิบครบแล้วทดสอบ craft
local IS  = require(game.ServerScriptService.Progression.PlayerItemStore)
local CS  = require(game.ServerScriptService.Progression.CraftingService)
local CU  = require(game.ServerScriptService.Commerce.CurrencyService)
local p   = game.Players:GetPlayers()[1]

IS.addItem(p.UserId, "StarSword1", 1)
IS.addItem(p.UserId, "StoneFragment", 100)
IS.addItem(p.UserId, "IronOre", 30)
CU.addCredits(p.UserId, 500)

local result = CS.craft(p, "StarSword2")
print(result.ok, result.reason, result.output)
-- ควรได้ true, "สำเร็จ!", "StarSword2"
print(IS.getInventory(p.UserId))
```

## Git commit (ถ้า clean)

```bash
git add -A
git commit -m "feat(Crafting): Grandeur Upgrade system

- CraftingService: canCraft(), craft() with rollback, getAllRecipes()
- CraftingHandlers: GetAllRecipes/CraftItem/GetInventory RF via SocialRemotes
- CraftingClient: ⚒ panel (recipe list + detail + material check + craft btn)
- ItemCraftingConfig: +StarSword2, +IronArmor1 test recipes"
```

## รายงานกลับ

- ✅/❌ BUILD · ✅/❌ STRICT CLEAN (error+line) · commit hash
- craft StarSword2 สำเร็จไหม + inventory หลัง craft
