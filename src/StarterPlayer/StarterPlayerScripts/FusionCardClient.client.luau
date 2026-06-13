--!strict
--[[
	FusionCardClient — ⚗️ Fusion + 🃏 Cards panel
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui
local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local getFusionRecipesRF = remotes:WaitForChild("GetAllFusionRecipes") :: RemoteFunction
local fuseItemRF = remotes:WaitForChild("FuseItem") :: RemoteFunction
local getEquippedRF = remotes:WaitForChild("GetEquippedCards") :: RemoteFunction
local equipCardRF = remotes:WaitForChild("EquipCard") :: RemoteFunction
local unequipCardRF = remotes:WaitForChild("UnequipCard") :: RemoteFunction
local getInventoryRF = remotes:WaitForChild("GetInventory") :: RemoteFunction

local DARK = Color3.fromRGB(10, 15, 30)
local ACCENT = Color3.fromRGB(80, 200, 255)
local GOLD = Color3.fromRGB(255, 200, 50)
local SUCCESS = Color3.fromRGB(80, 220, 120)
local FAIL = Color3.fromRGB(220, 80, 80)

local CARD_IDS = { "CardCommon", "CardRare", "CardLegendary" }

local function makeLabel(parent: Instance, text: string, size: UDim2, pos: UDim2, color: Color3?): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color or Color3.new(1, 1, 1)
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
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = b
	return b
end

local sg = Instance.new("ScreenGui")
sg.Name = "FusionCardGui"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = playerGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromOffset(100, 36)
toggleBtn.Position = UDim2.new(0, 8, 1, -88)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 120)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "⚗️ Fusion"
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
toggleBtn.Parent = sg
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleBtn

local panel = Instance.new("Frame")
panel.Name = "FusionCardPanel"
panel.Size = UDim2.fromOffset(440, 380)
panel.Position = UDim2.new(0.5, -220, 0.5, -190)
panel.BackgroundColor3 = DARK
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = sg
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local header = makeLabel(panel, "⚗️ Fusion & 🃏 Cards", UDim2.new(1, -80, 0, 32), UDim2.fromOffset(12, 8), ACCENT)
header.TextSize = 15

local closeBtn = makeBtn(panel, "✕", UDim2.fromOffset(32, 32), UDim2.new(1, -40, 0, 8), Color3.fromRGB(160, 40, 40))
closeBtn.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

local tabFusion = makeBtn(panel, "⚗️ Fusion", UDim2.fromOffset(100, 28), UDim2.fromOffset(12, 48), Color3.fromRGB(60, 100, 160))
local tabCards = makeBtn(panel, "🃏 Cards", UDim2.fromOffset(100, 28), UDim2.fromOffset(120, 48), Color3.fromRGB(80, 50, 120))

local statusLabel = makeLabel(panel, "", UDim2.new(1, -16, 0, 20), UDim2.fromOffset(8, 358), SUCCESS)
statusLabel.TextXAlignment = Enum.TextXAlignment.Center

local fusionFrame = Instance.new("Frame")
fusionFrame.Size = UDim2.new(1, -16, 0, 290)
fusionFrame.Position = UDim2.fromOffset(8, 82)
fusionFrame.BackgroundTransparency = 1
fusionFrame.Parent = panel

local fusionList = Instance.new("ScrollingFrame")
fusionList.Size = UDim2.fromScale(1, 1)
fusionList.BackgroundTransparency = 1
fusionList.ScrollBarThickness = 4
fusionList.CanvasSize = UDim2.new()
fusionList.AutomaticCanvasSize = Enum.AutomaticSize.Y
fusionList.Parent = fusionFrame
local fusionLayout = Instance.new("UIListLayout")
fusionLayout.Padding = UDim.new(0, 6)
fusionLayout.Parent = fusionList

local cardFrame = Instance.new("Frame")
cardFrame.Size = UDim2.new(1, -16, 0, 290)
cardFrame.Position = UDim2.fromOffset(8, 82)
cardFrame.BackgroundTransparency = 1
cardFrame.Visible = false
cardFrame.Parent = panel

local slotLabels: { TextLabel } = {}

local cardInventoryList = Instance.new("ScrollingFrame")
cardInventoryList.Size = UDim2.fromOffset(420, 140)
cardInventoryList.Position = UDim2.fromOffset(0, 170)
cardInventoryList.BackgroundTransparency = 1
cardInventoryList.ScrollBarThickness = 4
cardInventoryList.CanvasSize = UDim2.new()
cardInventoryList.AutomaticCanvasSize = Enum.AutomaticSize.Y
cardInventoryList.Parent = cardFrame
local cardInvLayout = Instance.new("UIListLayout")
cardInvLayout.Padding = UDim.new(0, 4)
cardInvLayout.Parent = cardInventoryList

local function refreshCards()
	local ok, cards = pcall(function()
		return getEquippedRF:InvokeServer()
	end)
	if ok and cards then
		for i, lbl in slotLabels do
			local cardId: string = (cards :: { string })[i] or ""
			lbl.Text = string.format("Socket %d: %s", i, if cardId ~= "" then cardId else "(ว่าง)")
		end
	end

	for _, c in cardInventoryList:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end

	local invOk, inv = pcall(function()
		return getInventoryRF:InvokeServer()
	end)
	if not invOk or typeof(inv) ~= "table" then
		return
	end

	for _, cardId in CARD_IDS do
		local qty = (inv :: { [string]: number })[cardId] or 0
		if qty <= 0 then
			continue
		end

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 36)
		row.BackgroundColor3 = Color3.fromRGB(18, 26, 48)
		row.BorderSizePixel = 0
		row.Parent = cardInventoryList
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		makeLabel(row, string.format("🃏 %s × %d", cardId, qty), UDim2.fromOffset(220, 36), UDim2.fromOffset(8, 0), GOLD)

		for slot = 1, 2 do
			local eqBtn = makeBtn(row, "S" .. slot, UDim2.fromOffset(40, 26), UDim2.fromOffset(240 + (slot - 1) * 48, 5), ACCENT)
			eqBtn.TextColor3 = DARK
			eqBtn.MouseButton1Click:Connect(function()
				local eqOk, success, msg = pcall(function()
					return equipCardRF:InvokeServer(cardId, slot)
				end)
				if eqOk and success == true then
					statusLabel.Text = "✅ equip " .. cardId .. " slot " .. slot
					statusLabel.TextColor3 = SUCCESS
				else
					statusLabel.Text = "❌ " .. tostring(if eqOk then msg else success)
					statusLabel.TextColor3 = FAIL
				end
				refreshCards()
			end)
		end
	end
end

for i = 1, 2 do
	local y = (i - 1) * 80 + 10
	local slotBg = Instance.new("Frame")
	slotBg.Size = UDim2.fromOffset(420, 70)
	slotBg.Position = UDim2.fromOffset(0, y)
	slotBg.BackgroundColor3 = Color3.fromRGB(20, 30, 55)
	slotBg.BorderSizePixel = 0
	slotBg.Parent = cardFrame
	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 6)
	slotCorner.Parent = slotBg

	local lbl = makeLabel(slotBg, "Socket " .. i .. ": (ว่าง)", UDim2.fromOffset(300, 70), UDim2.fromOffset(8, 0), GOLD)
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	table.insert(slotLabels, lbl)

	local unBtn = makeBtn(slotBg, "ถอด", UDim2.fromOffset(60, 30), UDim2.new(1, -70, 0, 20), FAIL)
	local slot = i
	unBtn.MouseButton1Click:Connect(function()
		local ok, success, msg = pcall(function()
			return unequipCardRF:InvokeServer(slot)
		end)
		if ok and success == true then
			statusLabel.Text = "✅ ถอดการ์ด slot " .. slot
			statusLabel.TextColor3 = SUCCESS
		else
			statusLabel.Text = "❌ " .. tostring(if ok then msg else success)
			statusLabel.TextColor3 = FAIL
		end
		refreshCards()
	end)
end

local function refreshFusion()
	for _, c in fusionList:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local ok, recipes = pcall(function()
		return getFusionRecipesRF:InvokeServer()
	end)
	if not ok or not recipes then
		return
	end

	for _, recipe in recipes :: { any } do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 44)
		row.BackgroundColor3 = Color3.fromRGB(18, 26, 48)
		row.BorderSizePixel = 0
		row.Parent = fusionList
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		makeLabel(
			row,
			string.format("⚗️  %s × 2  →  %s  (💰%d)", recipe.inputItem, recipe.outputItem, recipe.creditCost),
			UDim2.fromOffset(300, 44),
			UDim2.fromOffset(8, 0)
		)

		local fuseBtn = makeBtn(row, "Fuse", UDim2.fromOffset(70, 30), UDim2.new(1, -80, 0, 7), ACCENT)
		fuseBtn.TextColor3 = DARK
		local inp = recipe.inputItem
		fuseBtn.MouseButton1Click:Connect(function()
			local invokeOk, res = pcall(function()
				return fuseItemRF:InvokeServer(inp)
			end)
			if invokeOk and type(res) == "table" then
				statusLabel.Text = if res.ok then "✅ ได้ " .. tostring(res.output) else "❌ " .. tostring(res.reason)
				statusLabel.TextColor3 = if res.ok then SUCCESS else FAIL
			else
				statusLabel.Text = "❌ " .. tostring(res)
				statusLabel.TextColor3 = FAIL
			end
		end)
	end
end

tabFusion.MouseButton1Click:Connect(function()
	fusionFrame.Visible = true
	cardFrame.Visible = false
	tabFusion.BackgroundColor3 = Color3.fromRGB(60, 100, 160)
	tabCards.BackgroundColor3 = Color3.fromRGB(80, 50, 120)
end)

tabCards.MouseButton1Click:Connect(function()
	fusionFrame.Visible = false
	cardFrame.Visible = true
	tabFusion.BackgroundColor3 = Color3.fromRGB(40, 60, 110)
	tabCards.BackgroundColor3 = Color3.fromRGB(100, 70, 150)
	refreshCards()
end)

toggleBtn.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		refreshFusion()
	end
end)
