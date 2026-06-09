--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("MountRemotes")
local getShopCatalog = remotes:WaitForChild("GetEternityShopCatalog") :: RemoteFunction
local devGrant = remotes:WaitForChild("DevGrantEternityItem") :: RemoteFunction
local openShopEvent = remotes:WaitForChild("OpenEternityShop") :: RemoteEvent

local PALETTE = {
	Pearl = Color3.fromRGB(245, 245, 240),
	Gold = Color3.fromRGB(212, 175, 55),
	Cyan = Color3.fromRGB(0, 229, 255),
	Dark = Color3.fromRGB(18, 22, 32),
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EternityPremiumShopUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "ShopRoot"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(560, 440)
root.BackgroundColor3 = PALETTE.Dark
root.BorderSizePixel = 0
root.Visible = false
root.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = root

local stroke = Instance.new("UIStroke")
stroke.Color = PALETTE.Gold
stroke.Thickness = 2
stroke.Parent = root

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(16, 12)
title.Size = UDim2.new(1, -80, 0, 32)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = PALETTE.Pearl
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Eternity Premium Shop"
title.Parent = root

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(16, 44)
subtitle.Size = UDim2.new(1, -32, 0, 18)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 12
subtitle.TextColor3 = PALETTE.Cyan
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "Vehicles + weapons · cosmetic only · Eternity City exclusive"
subtitle.Parent = root

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -12, 0, 12)
closeBtn.Size = UDim2.fromOffset(36, 36)
closeBtn.BackgroundColor3 = PALETTE.Gold
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = PALETTE.Dark
closeBtn.Text = "X"
closeBtn.Parent = root

local list = Instance.new("ScrollingFrame")
list.Name = "CatalogList"
list.Position = UDim2.fromOffset(16, 72)
list.Size = UDim2.new(1, -32, 1, -88)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.new()
list.Parent = root

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.fromOffset(16, 0)
statusLabel.Size = UDim2.new(1, -32, 0, 20)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 13
statusLabel.TextColor3 = PALETTE.Cyan
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Text = ""
statusLabel.Parent = root

local function clearList()
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function addRow(text: string, itemId: string, kind: string)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 44)
	row.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
	row.BorderSizePixel = 0
	row.Parent = list

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.fromOffset(12, 0)
	lbl.Size = UDim2.new(1, -120, 1, 0)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 14
	lbl.TextColor3 = PALETTE.Pearl
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = text
	lbl.Parent = row

	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, -8, 0.5, 0)
	btn.Size = UDim2.fromOffset(96, 30)
	btn.BackgroundColor3 = PALETTE.Gold
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = PALETTE.Dark
	btn.Text = "Dev Grant"
	btn.Parent = row

	btn.MouseButton1Click:Connect(function()
		local ok, msg = devGrant:InvokeServer(itemId, kind)
		statusLabel.Text = if ok then msg else ("Error: " .. msg)
	end)
end

local function openShop()
	local catalog = getShopCatalog:InvokeServer()
	if not catalog.ok then
		statusLabel.Text = catalog.message or "Shop locked"
		root.Visible = true
		return
	end

	clearList()
	subtitle.Text = catalog.advisorTip or subtitle.Text

	for _, vehicle in catalog.vehicles or {} do
		addRow(
			string.format("[%s] %s · %s · %d seats", vehicle.travelMode, vehicle.displayName, vehicle.doorType or "None", vehicle.seatCount),
			vehicle.id,
			"vehicle"
		)
	end
	for _, weapon in catalog.weapons or {} do
		addRow(
			string.format("[Weapon] %s · %d R$", weapon.displayName, weapon.robux or 0),
			weapon.id,
			"weapon"
		)
	end

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
	end)
	list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)

	root.Visible = true
	statusLabel.Text = ""
end

closeBtn.MouseButton1Click:Connect(function()
	root.Visible = false
end)

openShopEvent.OnClientEvent:Connect(openShop)

local function bindPrompts()
	for _, inst in workspace:GetDescendants() do
		if inst:IsA("ProximityPrompt") and inst.Name == "PremiumShopPrompt" then
			inst.Triggered:Connect(function(triggerPlayer)
				if triggerPlayer == player then
					openShop()
				end
			end)
		end
	end
end

workspace.DescendantAdded:Connect(function(inst)
	if inst:IsA("ProximityPrompt") and inst.Name == "PremiumShopPrompt" then
		inst.Triggered:Connect(function(triggerPlayer)
			if triggerPlayer == player then
				openShop()
			end
		end)
	end
end)

task.defer(bindPrompts)
