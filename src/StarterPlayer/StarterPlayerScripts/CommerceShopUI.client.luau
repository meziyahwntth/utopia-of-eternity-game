--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("CommerceRemotes")
local getCatalog = remotes:WaitForChild("GetShopCatalog") :: RemoteFunction
local purchaseItem = remotes:WaitForChild("PurchaseItem") :: RemoteFunction
local shopOpened = remotes:WaitForChild("ShopOpened") :: RemoteEvent
local purchaseResult = remotes:WaitForChild("PurchaseResult") :: RemoteEvent

local PALETTE = {
	Pearl = Color3.fromRGB(245, 245, 240),
	Gold = Color3.fromRGB(212, 175, 55),
	Cyan = Color3.fromRGB(0, 229, 255),
	Dark = Color3.fromRGB(18, 22, 32),
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CommerceShopUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "ShopRoot"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(520, 420)
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
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(16, 12)
title.Size = UDim2.new(1, -80, 0, 32)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = PALETTE.Pearl
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Prism Shop"
title.Parent = root

local peaceBadge = Instance.new("TextLabel")
peaceBadge.BackgroundTransparency = 1
peaceBadge.Position = UDim2.fromOffset(16, 44)
peaceBadge.Size = UDim2.new(1, -32, 0, 18)
peaceBadge.Font = Enum.Font.Gotham
peaceBadge.TextSize = 12
peaceBadge.TextColor3 = PALETTE.Cyan
peaceBadge.TextXAlignment = Enum.TextXAlignment.Left
peaceBadge.Text = "☮ Commerce Peace Zone — cosmetic only"
peaceBadge.Parent = root

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -12, 0, 12)
closeBtn.Size = UDim2.fromOffset(36, 36)
closeBtn.BackgroundColor3 = PALETTE.Gold
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = PALETTE.Dark
closeBtn.Text = "X"
closeBtn.Parent = root
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local list = Instance.new("ScrollingFrame")
list.Name = "ItemList"
list.Position = UDim2.fromOffset(16, 72)
list.Size = UDim2.new(1, -32, 1, -120)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.fromOffset(0, 0)
list.Parent = root

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = list

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.new(0, 16, 1, -40)
status.Size = UDim2.new(1, -32, 0, 28)
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextColor3 = PALETTE.Pearl
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = ""
status.Parent = root

local currentShopId: string? = nil
local activeAccent = PALETTE.Gold
local titlePulseTween: Tween? = nil

local function colorFromTable(payload: any): Color3?
	if typeof(payload) ~= "table" then
		return nil
	end
	local r = payload.r
	local g = payload.g
	local b = payload.b
	if typeof(r) == "number" and typeof(g) == "number" and typeof(b) == "number" then
		return Color3.new(r, g, b)
	end
	return nil
end

local function applySeasonTheme(theme: any?)
	if typeof(theme) ~= "table" then
		activeAccent = PALETTE.Gold
		stroke.Color = PALETTE.Gold
		title.TextColor3 = PALETTE.Pearl
		peaceBadge.TextColor3 = PALETTE.Cyan
		closeBtn.BackgroundColor3 = PALETTE.Gold
		return
	end
	local accent = colorFromTable(theme.accent) or PALETTE.Gold
	activeAccent = accent
	stroke.Color = accent
	title.TextColor3 = accent
	peaceBadge.TextColor3 = accent
	closeBtn.BackgroundColor3 = accent
	titlePulseTween = TweenService:Create(
		title,
		TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ TextTransparency = 0.15 }
	)
	titlePulseTween:Play()
end

local function resetSeasonTheme()
	if titlePulseTween then
		titlePulseTween:Cancel()
		titlePulseTween = nil
	end
	title.TextTransparency = 0
	applySeasonTheme(nil)
end

local SOURCE_SECTION_LABELS = {
	fashion = "Season Fashion",
	season_rotation = "Featured Packs",
	ugc_creator = "Creator UGC",
}

local function makeSectionHeader(label: string, layoutOrder: number)
	local header = Instance.new("TextLabel")
	header.Name = "Section_" .. label
	header.Size = UDim2.new(1, -4, 0, 22)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.TextSize = 13
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextColor3 = activeAccent
	header.Text = label
	header.LayoutOrder = layoutOrder
	header.Parent = list
end

local function sourceBadgeText(source: string?): string?
	if source == "ugc_creator" then
		return "Creator Pack"
	end
	if source == "season_rotation" then
		return "Featured"
	end
	return nil
end

local function setStatus(msg: string)
	status.Text = msg
end

local function clearList()
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function makeRow(item: any, layoutOrder: number)
	local row = Instance.new("Frame")
	row.Name = "Row_" .. item.id
	row.Size = UDim2.new(1, -4, 0, 52)
	row.BackgroundColor3 = Color3.fromRGB(30, 36, 50)
	row.BorderSizePixel = 0
	row.LayoutOrder = layoutOrder
	row.Parent = list
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(12, 6)
	name.Size = UDim2.new(0.55, 0, 0, 22)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 14
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextColor3 = PALETTE.Pearl
	name.Text = item.displayName
	name.Parent = row

	local badgeText = sourceBadgeText(item.source)
	if badgeText then
		name.Size = UDim2.new(0.45, 0, 0, 22)
		local badge = Instance.new("TextLabel")
		badge.BackgroundTransparency = 1
		badge.Position = UDim2.fromOffset(12, 6)
		badge.Size = UDim2.new(0.45, 0, 0, 22)
		badge.Font = Enum.Font.GothamBold
		badge.TextSize = 10
		badge.TextXAlignment = Enum.TextXAlignment.Right
		badge.TextColor3 = activeAccent
		badge.Text = badgeText
		badge.Parent = row
	end

	local meta = Instance.new("TextLabel")
	meta.BackgroundTransparency = 1
	meta.Position = UDim2.fromOffset(12, 28)
	meta.Size = UDim2.new(0.55, 0, 0, 18)
	meta.Font = Enum.Font.Gotham
	meta.TextSize = 12
	meta.TextXAlignment = Enum.TextXAlignment.Left
	meta.TextColor3 = PALETTE.Cyan
	meta.Text = if item.locked
		then (item.lockReason or "Locked")
		else string.format("%s · %d R$", item.kind, item.robux)
	meta.TextColor3 = if item.locked then Color3.fromRGB(255, 120, 120) else PALETTE.Cyan
	meta.Parent = row

	local buy = Instance.new("TextButton")
	buy.AnchorPoint = Vector2.new(1, 0.5)
	buy.Position = UDim2.new(1, -12, 0.5, 0)
	buy.Size = UDim2.fromOffset(100, 34)
	buy.Font = Enum.Font.GothamBold
	buy.TextSize = 14
	buy.Parent = row
	Instance.new("UICorner", buy).CornerRadius = UDim.new(0, 8)

	if item.owned then
		buy.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		buy.TextColor3 = PALETTE.Pearl
		buy.Text = "Owned"
		buy.Active = false
	elseif item.locked then
		buy.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
		buy.TextColor3 = PALETTE.Pearl
		buy.Text = "Locked"
		buy.Active = false
	else
		buy.BackgroundColor3 = activeAccent
		buy.TextColor3 = PALETTE.Dark
		buy.Text = "Buy"
		buy.MouseButton1Click:Connect(function()
			setStatus("Processing…")
			local result = purchaseItem:InvokeServer(currentShopId or "", item.id)
			if result and result.ok then
				setStatus(result.message or "OK")
			else
				setStatus(result and result.message or "Failed")
			end
		end)
	end
end

local function openShop(shopId: string)
	currentShopId = shopId
	clearList()
	resetSeasonTheme()
	setStatus("Loading…")
	root.Visible = true

	local catalog = getCatalog:InvokeServer(shopId)
	if not catalog then
		setStatus("Failed to load catalog")
		return
	end

	title.Text = catalog.shopName or "Shop"
	local isSeasonalPopUp = typeof(catalog.seasonPopUpLabel) == "string" and catalog.seasonPopUpLabel ~= ""
	if isSeasonalPopUp then
		applySeasonTheme(catalog.seasonTheme)
		peaceBadge.Text = "☮ " .. catalog.seasonPopUpLabel
	else
		local tierLabel = if catalog.commerceTier == "luxury"
			then "Luxury Mall · 3× price · no key required"
			else string.format("Street shop · keys %d/%d", catalog.playerKeyCount or 0, catalog.minPrismKeys or 0)
		peaceBadge.Text = "☮ " .. tierLabel
	end

	local items = catalog.items or {}
	local layoutOrder = 0
	local lastSource: string? = nil
	for _, item in items do
		if isSeasonalPopUp and typeof(item.source) == "string" and item.source ~= lastSource then
			local sectionLabel = SOURCE_SECTION_LABELS[item.source]
			if sectionLabel then
				layoutOrder += 1
				makeSectionHeader(sectionLabel, layoutOrder)
			end
			lastSource = item.source
		end
		layoutOrder += 1
		makeRow(item, layoutOrder)
	end
	list.CanvasSize = UDim2.fromOffset(0, layoutOrder * 60)
	setStatus(string.format("%d items · peace zone active", #items))
	shopOpened:FireServer(shopId)
end

local function closeShop()
	root.Visible = false
	currentShopId = nil
	resetSeasonTheme()
	clearList()
	setStatus("")
end

closeBtn.MouseButton1Click:Connect(closeShop)

purchaseResult.OnClientEvent:Connect(function(result)
	if result and result.ok and result.itemId then
		setStatus("Purchased: " .. result.itemId)
		if currentShopId then
			openShop(currentShopId)
		end
	end
end)

local function bindPrompt(prompt: ProximityPrompt)
	if prompt:GetAttribute("CommerceBound") then
		return
	end
	prompt:SetAttribute("CommerceBound", true)
	prompt.Triggered:Connect(function()
		local shopPart = prompt.Parent
		if not shopPart or not shopPart:IsA("BasePart") then
			return
		end
		local shopId = shopPart.Name:gsub("^Shop_", "")
		openShop(shopId)
	end)
end

local function scanShops()
	for _, inst in workspace:GetDescendants() do
		if inst:IsA("ProximityPrompt") and inst.Name == "ShopPrompt" then
			bindPrompt(inst)
		end
	end
end

workspace.DescendantAdded:Connect(function(inst)
	if inst:IsA("ProximityPrompt") and inst.Name == "ShopPrompt" then
		task.defer(function()
			bindPrompt(inst)
		end)
	end
end)

task.defer(scanShops)

-- Fade in when opened
root:GetPropertyChangedSignal("Visible"):Connect(function()
	if root.Visible then
		root.BackgroundTransparency = 1
		TweenService:Create(root, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
	end
end)

print("[Commerce] Shop UI ready")
