--!strict
--[[
	CraftingClient — Grandeur Upgrade panel (recipe list + craft)
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local getAllRF = remotes:WaitForChild("GetAllRecipes") :: RemoteFunction
local craftRF = remotes:WaitForChild("CraftItem") :: RemoteFunction
local getInventoryRF = remotes:WaitForChild("GetInventory") :: RemoteFunction
local getCreditsRF = remotes:WaitForChild("GetCredits") :: RemoteFunction

type MaterialReq = { id: string, qty: number }
type GrandeurRecipe = {
	baseItem: string,
	materials: { MaterialReq },
	creditCost: number,
	outputItem: string,
}

type CraftResult = {
	ok: boolean,
	reason: string,
	output: string?,
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CraftingUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 8
screenGui.Parent = playerGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromScale(0.07, 0.05)
toggleBtn.Position = UDim2.fromScale(0.92, 0.145)
toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 20)
toggleBtn.BackgroundTransparency = 0.15
toggleBtn.TextScaled = true
toggleBtn.Text = "⚒"
toggleBtn.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0.2, 0)
toggleCorner.Parent = toggleBtn

local panel = Instance.new("Frame")
panel.Size = UDim2.fromScale(0.38, 0.55)
panel.Position = UDim2.fromScale(0.61, 0.08)
panel.BackgroundColor3 = Color3.fromRGB(22, 18, 12)
panel.BackgroundTransparency = 0.05
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0.02, 0)
panelCorner.Parent = panel

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.fromScale(1, 0.1)
titleBar.BackgroundColor3 = Color3.fromRGB(80, 50, 20)
titleBar.Parent = panel

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0.04, 0)
titleBarCorner.Parent = titleBar

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.fromScale(0.85, 1)
titleLbl.BackgroundTransparency = 1
titleLbl.TextColor3 = Color3.new(1, 0.9, 0.6)
titleLbl.TextScaled = true
titleLbl.Font = Enum.Font.GothamBold
titleLbl.Text = "⚒ Crafting — Grandeur Upgrade"
titleLbl.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromScale(0.1, 0.8)
closeBtn.Position = UDim2.fromScale(0.89, 0.1)
closeBtn.Text = "✕"
closeBtn.TextScaled = true
closeBtn.BackgroundTransparency = 1
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Parent = titleBar

closeBtn.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

local recipeScroll = Instance.new("ScrollingFrame")
recipeScroll.Size = UDim2.fromScale(0.4, 0.87)
recipeScroll.Position = UDim2.fromScale(0.01, 0.12)
recipeScroll.BackgroundColor3 = Color3.fromRGB(15, 12, 8)
recipeScroll.ScrollBarThickness = 4
recipeScroll.CanvasSize = UDim2.fromScale(0, 0)
recipeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
recipeScroll.Parent = panel

local recipeLayout = Instance.new("UIListLayout")
recipeLayout.Padding = UDim.new(0, 3)
recipeLayout.Parent = recipeScroll

local detailPanel = Instance.new("Frame")
detailPanel.Size = UDim2.fromScale(0.56, 0.87)
detailPanel.Position = UDim2.fromScale(0.43, 0.12)
detailPanel.BackgroundColor3 = Color3.fromRGB(18, 15, 10)
detailPanel.Parent = panel

local detailCorner = Instance.new("UICorner")
detailCorner.CornerRadius = UDim.new(0.03, 0)
detailCorner.Parent = detailPanel

local detailTitle = Instance.new("TextLabel")
detailTitle.Size = UDim2.fromScale(1, 0.12)
detailTitle.BackgroundTransparency = 1
detailTitle.TextColor3 = Color3.new(1, 0.9, 0.5)
detailTitle.TextScaled = true
detailTitle.Font = Enum.Font.GothamBold
detailTitle.Text = "เลือก recipe"
detailTitle.Parent = detailPanel

local materialsLbl = Instance.new("TextLabel")
materialsLbl.Size = UDim2.fromScale(1, 0.55)
materialsLbl.Position = UDim2.fromScale(0, 0.13)
materialsLbl.BackgroundTransparency = 1
materialsLbl.TextColor3 = Color3.fromRGB(200, 200, 180)
materialsLbl.TextScaled = false
materialsLbl.TextSize = 13
materialsLbl.Font = Enum.Font.Gotham
materialsLbl.TextXAlignment = Enum.TextXAlignment.Left
materialsLbl.TextYAlignment = Enum.TextYAlignment.Top
materialsLbl.TextWrapped = true
materialsLbl.Text = ""
materialsLbl.Parent = detailPanel

local materialsPadding = Instance.new("UIPadding")
materialsPadding.PaddingLeft = UDim.new(0.03, 0)
materialsPadding.Parent = materialsLbl

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.fromScale(1, 0.1)
statusLbl.Position = UDim2.fromScale(0, 0.7)
statusLbl.BackgroundTransparency = 1
statusLbl.TextColor3 = Color3.fromRGB(100, 255, 120)
statusLbl.TextScaled = false
statusLbl.TextSize = 13
statusLbl.Text = ""
statusLbl.Parent = detailPanel

local craftBtn = Instance.new("TextButton")
craftBtn.Size = UDim2.fromScale(0.85, 0.13)
craftBtn.Position = UDim2.fromScale(0.075, 0.84)
craftBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 10)
craftBtn.TextColor3 = Color3.fromRGB(200, 180, 100)
craftBtn.TextScaled = true
craftBtn.Font = Enum.Font.GothamBold
craftBtn.Text = "Craft"
craftBtn.Parent = detailPanel

local craftCorner = Instance.new("UICorner")
craftCorner.CornerRadius = UDim.new(0.2, 0)
craftCorner.Parent = craftBtn

local selectedOutputItem: string? = nil

local function buildMaterialText(recipe: GrandeurRecipe, inventory: { [string]: number }): string
	local lines = {
		"📦 Base: "
			.. recipe.baseItem
			.. "  (มี "
			.. tostring(inventory[recipe.baseItem] or 0)
			.. ")",
	}
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
	detailTitle.Text = "⚔ → " .. outputItem
	materialsLbl.Text = buildMaterialText(recipe, inventory)
	statusLbl.Text = ""
end

local function showStatus(msg: string, success: boolean)
	statusLbl.Text = msg
	statusLbl.TextColor3 = if success then Color3.fromRGB(80, 255, 100) else Color3.fromRGB(255, 80, 80)
	task.delay(3, function()
		statusLbl.Text = ""
	end)
end

local function buildRecipeList(recipes: { [string]: GrandeurRecipe }, inventory: { [string]: number })
	for _, child in recipeScroll:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for outputItem, recipe in recipes do
		local have = inventory[recipe.baseItem] or 0
		local canCraft = have >= 1
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromScale(0.96, 0)
		btn.AutomaticSize = Enum.AutomaticSize.Y
		btn.BackgroundColor3 = if canCraft then Color3.fromRGB(50, 35, 15) else Color3.fromRGB(30, 30, 30)
		btn.TextColor3 = if canCraft then Color3.new(1, 0.9, 0.5) else Color3.fromRGB(120, 120, 120)
		btn.TextScaled = false
		btn.TextSize = 13
		btn.Font = Enum.Font.GothamBold
		btn.Text = (if canCraft then "⚒ " else "🔒 ") .. outputItem
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Parent = recipeScroll

		local btnPadding = Instance.new("UIPadding")
		btnPadding.PaddingLeft = UDim.new(0.05, 0)
		btnPadding.Parent = btn

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0.1, 0)
		btnCorner.Parent = btn

		btn.MouseButton1Click:Connect(function()
			showDetail(outputItem, recipe, inventory)
		end)
	end
end

local function refreshUI()
	local okR, recipes = pcall(function()
		return getAllRF:InvokeServer()
	end)
	local okI, inventory = pcall(function()
		return getInventoryRF:InvokeServer()
	end)
	local okC, credits = pcall(function()
		return getCreditsRF:InvokeServer()
	end)
	if not okR or not okI or typeof(recipes) ~= "table" or typeof(inventory) ~= "table" then
		return
	end

	local inv = inventory :: { [string]: number }
	inv["__credits__"] = if okC and typeof(credits) == "number" then credits else 0

	buildRecipeList(recipes :: { [string]: GrandeurRecipe }, inv)
	if selectedOutputItem then
		local recipe = (recipes :: { [string]: GrandeurRecipe })[selectedOutputItem]
		if recipe then
			showDetail(selectedOutputItem, recipe, inv)
		end
	end
end

toggleBtn.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		refreshUI()
	end
end)

craftBtn.MouseButton1Click:Connect(function()
	if not selectedOutputItem then
		return
	end
	craftBtn.Active = false
	craftBtn.Text = "กำลัง Craft..."

	local ok, result = pcall(function()
		return craftRF:InvokeServer(selectedOutputItem)
	end)

	craftBtn.Active = true
	craftBtn.Text = "Craft"

	if ok and typeof(result) == "table" then
		local res = result :: CraftResult
		showStatus(if res.ok then "✨ ได้รับ " .. tostring(res.output) .. "!" else "❌ " .. res.reason, res.ok)
		if res.ok then
			task.wait(0.5)
			refreshUI()
		end
	else
		showStatus("❌ เชื่อมต่อล้มเหลว", false)
	end
end)
