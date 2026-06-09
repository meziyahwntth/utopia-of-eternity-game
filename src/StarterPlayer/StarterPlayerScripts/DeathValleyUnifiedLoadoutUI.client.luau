--!strict
--[[
	Phase L — Unified loadout wardrobe: Titles | Cosmetics | Presets + 3D preview.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathValleyLoadoutPreview = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DeathValleyLoadoutPreview"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local getLoadoutFull = remotes:WaitForChild("GetLoadoutFull") :: RemoteFunction
local equipSeasonCosmetic = remotes:WaitForChild("EquipSeasonCosmetic") :: RemoteFunction
local unequipSeasonCosmetic = remotes:WaitForChild("UnequipSeasonCosmetic") :: RemoteFunction
local equipSeasonTitle = remotes:WaitForChild("EquipSeasonTitle") :: RemoteFunction
local unequipSeasonTitle = remotes:WaitForChild("UnequipSeasonTitle") :: RemoteFunction
local saveLoadoutPreset = remotes:WaitForChild("SaveLoadoutPreset") :: RemoteFunction
local applyLoadoutPreset = remotes:WaitForChild("ApplyLoadoutPreset") :: RemoteFunction
local clearLoadoutPreset = remotes:WaitForChild("ClearLoadoutPreset") :: RemoteFunction
local shareLoadoutPreset = remotes:WaitForChild("ShareLoadoutPreset") :: RemoteFunction
local applySharedPreset = remotes:WaitForChild("ApplySharedPreset") :: RemoteFunction
local dismissSharedPreset = remotes:WaitForChild("DismissSharedPreset") :: RemoteFunction
local generatePresetShareCode = remotes:WaitForChild("GeneratePresetShareCode") :: RemoteFunction
local redeemPresetShareCode = remotes:WaitForChild("RedeemPresetShareCode") :: RemoteFunction
local getLfgFriendsList = remotes:WaitForChild("GetLfgFriendsList") :: RemoteFunction
local teleportToFriend = remotes:WaitForChild("TeleportToFriend") :: RemoteFunction
local publishPresetMarket = remotes:WaitForChild("PublishPresetMarket") :: RemoteFunction
local acquirePresetMarket = remotes:WaitForChild("AcquirePresetMarket") :: RemoteFunction
local likePresetMarket = remotes:WaitForChild("LikePresetMarket") :: RemoteFunction
local browsePresetMarket = remotes:WaitForChild("BrowsePresetMarket") :: RemoteFunction
local setSocialNotifyPrefs = remotes:WaitForChild("SetSocialNotifyPrefs") :: RemoteFunction
local getFeaturedCarousel = remotes:WaitForChild("GetFeaturedCarousel") :: RemoteFunction
local getPresetPackCatalog = remotes:WaitForChild("GetPresetPackCatalog") :: RemoteFunction
local purchasePresetPack = remotes:WaitForChild("PurchasePresetPack") :: RemoteFunction
local getCreatorRevenueSummary = remotes:WaitForChild("GetCreatorRevenueSummary") :: RemoteFunction
local requestCreatorPayout = remotes:WaitForChild("RequestCreatorPayout") :: RemoteFunction
local createUgcCreatorPack = remotes:WaitForChild("CreateUgcCreatorPack") :: RemoteFunction
local getPresetMarket = remotes:WaitForChild("GetPresetMarket") :: RemoteFunction

type TabId = "titles" | "cosmetics" | "presets" | "shared" | "market"
local selectedShareSlot = 1
local marketPage = 1

local function friendStatusTag(friend: { [string]: any }): string
	if friend.inThisServer == true then
		local city = if typeof(friend.placeDisplayName) == "string" and friend.placeDisplayName ~= ""
			then friend.placeDisplayName
			else "Here"
		return " [Here · " .. city .. "]"
	end
	if friend.online == true then
		local city = if typeof(friend.placeDisplayName) == "string" and friend.placeDisplayName ~= ""
			then friend.placeDisplayName
			else "Utopia"
		return " [Online · " .. city .. "]"
	end
	return " [Offline]"
end

local gui = Instance.new("ScreenGui")
gui.Name = "DeathValleyUnifiedLoadoutUI"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.35
backdrop.BorderSizePixel = 0
backdrop.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(680, 460)
panel.BackgroundColor3 = Color3.fromRGB(12, 8, 20)
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -240, 0, 30)
header.Position = UDim2.fromOffset(14, 10)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBold
header.TextSize = 18
header.TextXAlignment = Enum.TextXAlignment.Left
header.TextColor3 = Color3.fromRGB(255, 190, 100)
header.Text = "Valley Loadout Wardrobe"
header.Parent = panel

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -240, 0, 32)
tabBar.Position = UDim2.fromOffset(14, 44)
tabBar.BackgroundTransparency = 1
tabBar.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -240, 1, -130)
list.Position = UDim2.fromOffset(14, 82)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.Parent = panel

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -240, 0, 36)
status.Position = UDim2.new(0, 14, 1, -88)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.TextWrapped = true
status.TextColor3 = Color3.fromRGB(120, 220, 180)
status.Text = ""
status.Parent = panel

local unequipBtn = Instance.new("TextButton")
unequipBtn.Size = UDim2.fromOffset(130, 32)
unequipBtn.Position = UDim2.new(0, 14, 1, -44)
unequipBtn.Font = Enum.Font.GothamBold
unequipBtn.TextSize = 11
unequipBtn.TextColor3 = Color3.new(1, 1, 1)
unequipBtn.BackgroundColor3 = Color3.fromRGB(60, 55, 75)
unequipBtn.Parent = panel
Instance.new("UICorner", unequipBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(110, 32)
closeBtn.Position = UDim2.new(1, -124, 1, -44)
closeBtn.Text = "Close (V)"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 11
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Parent = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local preview = DeathValleyLoadoutPreview.mount(panel, UDim2.fromOffset(210, 320), UDim2.new(1, -224, 0, 62))

local ugcModalOverlay = Instance.new("Frame")
ugcModalOverlay.Name = "UgcPricePickerOverlay"
ugcModalOverlay.Size = UDim2.fromScale(1, 1)
ugcModalOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ugcModalOverlay.BackgroundTransparency = 0.45
ugcModalOverlay.BorderSizePixel = 0
ugcModalOverlay.Visible = false
ugcModalOverlay.ZIndex = 20
ugcModalOverlay.Parent = panel

local ugcModalBox = Instance.new("Frame")
ugcModalBox.AnchorPoint = Vector2.new(0.5, 0.5)
ugcModalBox.Position = UDim2.fromScale(0.5, 0.5)
ugcModalBox.Size = UDim2.fromOffset(320, 280)
ugcModalBox.BackgroundColor3 = Color3.fromRGB(18, 14, 28)
ugcModalBox.BorderSizePixel = 0
ugcModalBox.ZIndex = 21
ugcModalBox.Parent = ugcModalOverlay
Instance.new("UICorner", ugcModalBox).CornerRadius = UDim.new(0, 10)

local ugcModalTitle = Instance.new("TextLabel")
ugcModalTitle.Size = UDim2.new(1, -16, 0, 24)
ugcModalTitle.Position = UDim2.fromOffset(8, 8)
ugcModalTitle.BackgroundTransparency = 1
ugcModalTitle.Font = Enum.Font.GothamBold
ugcModalTitle.TextSize = 13
ugcModalTitle.TextXAlignment = Enum.TextXAlignment.Left
ugcModalTitle.TextColor3 = Color3.fromRGB(255, 200, 120)
ugcModalTitle.Text = "Set UGC Pack Price"
ugcModalTitle.ZIndex = 22
ugcModalTitle.Parent = ugcModalBox

local ugcModalPreview = Instance.new("TextLabel")
ugcModalPreview.Size = UDim2.new(1, -16, 0, 36)
ugcModalPreview.Position = UDim2.fromOffset(8, 34)
ugcModalPreview.BackgroundTransparency = 1
ugcModalPreview.Font = Enum.Font.Gotham
ugcModalPreview.TextSize = 10
ugcModalPreview.TextWrapped = true
ugcModalPreview.TextXAlignment = Enum.TextXAlignment.Left
ugcModalPreview.TextColor3 = Color3.fromRGB(180, 175, 210)
ugcModalPreview.ZIndex = 22
ugcModalPreview.Parent = ugcModalBox

local ugcTierGrid = Instance.new("Frame")
ugcTierGrid.Size = UDim2.new(1, -16, 0, 120)
ugcTierGrid.Position = UDim2.fromOffset(8, 76)
ugcTierGrid.BackgroundTransparency = 1
ugcTierGrid.ZIndex = 22
ugcTierGrid.Parent = ugcModalBox

local ugcSharePreview = Instance.new("TextLabel")
ugcSharePreview.Size = UDim2.new(1, -16, 0, 22)
ugcSharePreview.Position = UDim2.fromOffset(8, 200)
ugcSharePreview.BackgroundTransparency = 1
ugcSharePreview.Font = Enum.Font.Gotham
ugcSharePreview.TextSize = 10
ugcSharePreview.TextXAlignment = Enum.TextXAlignment.Left
ugcSharePreview.TextColor3 = Color3.fromRGB(140, 200, 150)
ugcSharePreview.ZIndex = 22
ugcSharePreview.Parent = ugcModalBox

local ugcModalCancel = Instance.new("TextButton")
ugcModalCancel.Size = UDim2.fromOffset(90, 28)
ugcModalCancel.Position = UDim2.new(1, -196, 1, -38)
ugcModalCancel.Text = "Cancel"
ugcModalCancel.Font = Enum.Font.GothamBold
ugcModalCancel.TextSize = 11
ugcModalCancel.BackgroundColor3 = Color3.fromRGB(55, 50, 65)
ugcModalCancel.TextColor3 = Color3.new(1, 1, 1)
ugcModalCancel.ZIndex = 22
ugcModalCancel.Parent = ugcModalBox
Instance.new("UICorner", ugcModalCancel).CornerRadius = UDim.new(0, 6)

local ugcModalConfirm = Instance.new("TextButton")
ugcModalConfirm.Size = UDim2.fromOffset(90, 28)
ugcModalConfirm.Position = UDim2.new(1, -98, 1, -38)
ugcModalConfirm.Text = "Confirm"
ugcModalConfirm.Font = Enum.Font.GothamBold
ugcModalConfirm.TextSize = 11
ugcModalConfirm.BackgroundColor3 = Color3.fromRGB(110, 80, 140)
ugcModalConfirm.TextColor3 = Color3.new(1, 1, 1)
ugcModalConfirm.ZIndex = 22
ugcModalConfirm.Parent = ugcModalBox
Instance.new("UICorner", ugcModalConfirm).CornerRadius = UDim.new(0, 6)

local ugcPickerListingId: string? = nil
local ugcPickerSelectedRobux = 99
local ugcPickerSharePercent = 70

local function hideUgcPricePicker()
	ugcModalOverlay.Visible = false
	ugcPickerListingId = nil
end

local function formatPayoutDate(createdAt: number?): string
	if typeof(createdAt) ~= "number" or createdAt <= 0 then
		return "—"
	end
	return os.date("%Y-%m-%d", createdAt)
end

local function refreshUgcTierSelection(tierButtons: { TextButton })
	for _, btn in tierButtons do
		local price = tonumber(btn:GetAttribute("RobuxPrice"))
		if price == ugcPickerSelectedRobux then
			btn.BackgroundColor3 = Color3.fromRGB(130, 90, 170)
		else
			btn.BackgroundColor3 = Color3.fromRGB(45, 40, 60)
		end
	end
	ugcSharePreview.Text = string.format(
		"70%% creator share ≈ %d credits per sale",
		math.floor(ugcPickerSelectedRobux * (ugcPickerSharePercent / 100))
	)
end

local function showUgcPricePicker(
	listingId: string,
	listing: { [string]: any },
	creatorSummary: { [string]: any }
)
	ugcPickerListingId = listingId
	ugcPickerSharePercent = tonumber(creatorSummary.creatorSharePercent) or 70
	local tiers = creatorSummary.ugcPriceTiers
	if typeof(tiers) ~= "table" or #tiers == 0 then
		tiers = { 49, 99, 149, 199, 249, 299, 399, 499 }
	end
	ugcPickerSelectedRobux = if typeof(tiers[2]) == "number" then tiers[2] else 99

	ugcModalPreview.Text = string.format(
		"Slot %s · %s / %s",
		tostring(listing.slotIndex or "?"),
		tostring(listing.cosmeticName or "—"),
		tostring(listing.titleText or "—")
	)

	for _, child in ugcTierGrid:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local tierButtons: { TextButton } = {}
	local col = 0
	local row = 0
	for _, tier in tiers do
		if typeof(tier) ~= "number" then
			continue
		end
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(68, 26)
		btn.Position = UDim2.fromOffset(col * 74, row * 30)
		btn.Text = string.format("R$%d", tier)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 10
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn:SetAttribute("RobuxPrice", tier)
		btn.ZIndex = 23
		btn.Parent = ugcTierGrid
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
		table.insert(tierButtons, btn)
		btn.MouseButton1Click:Connect(function()
			ugcPickerSelectedRobux = tier
			refreshUgcTierSelection(tierButtons)
		end)
		col += 1
		if col >= 4 then
			col = 0
			row += 1
		end
	end

	refreshUgcTierSelection(tierButtons)
	ugcModalOverlay.Visible = true
end

ugcModalCancel.MouseButton1Click:Connect(hideUgcPricePicker)
ugcModalConfirm.MouseButton1Click:Connect(function()
	if not ugcPickerListingId then
		return
	end
	local ok, result = createUgcCreatorPack:InvokeServer(ugcPickerListingId, ugcPickerSelectedRobux)
	hideUgcPricePicker()
	if ok and typeof(result) == "table" then
		status.Text = string.format("UGC pack live · %s · R$%d", tostring(result.packId), ugcPickerSelectedRobux)
		renderMarket()
	else
		status.Text = if typeof(result) == "string" then result else "UGC pack failed"
	end
end)

local activeTab: TabId = "titles"
local tabButtons: { [TabId]: TextButton } = {}
local fullData: any = nil
local hoverTitle: string? = nil
local hoverCosmetic: string? = nil

local function updatePreviewFromEquipped()
	local summary = if typeof(fullData) == "table" then fullData.summary else nil
	local title = hoverTitle
	local cosmetic = hoverCosmetic
	if not title and typeof(summary) == "table" and typeof(summary.equippedTitle) == "string" then
		title = summary.equippedTitle
	end
	if not cosmetic and typeof(summary) == "table" and typeof(summary.equippedCosmeticId) == "string" then
		cosmetic = summary.equippedCosmeticId
	end
	preview.setPreview(title, cosmetic)
end

local function clearList()
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function makeRow(y: number, equipped: boolean): Frame
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -4, 0, 46)
	row.Position = UDim2.fromOffset(0, y)
	row.BackgroundColor3 = if equipped then Color3.fromRGB(50, 65, 55) else Color3.fromRGB(26, 22, 38)
	row.BorderSizePixel = 0
	row.Parent = list
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
	return row
end

local function renderTitles()
	clearList()
	hoverTitle = nil
	hoverCosmetic = nil
	unequipBtn.Text = "Unequip Title"
	local titles = if typeof(fullData) == "table" then fullData.titles else nil
	local items = if typeof(titles) == "table" then titles.items else nil
	if typeof(items) ~= "table" or #items == 0 then
		status.Text = "No titles — earn season rewards in Death Valley (L)"
		list.CanvasSize = UDim2.fromOffset(0, 0)
		updatePreviewFromEquipped()
		return
	end
	local y = 0
	for _, item in items do
		if typeof(item) ~= "table" then
			continue
		end
		local row = makeRow(y, item.equipped == true)
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -90, 0, 22)
		titleLabel.Position = UDim2.fromOffset(10, 6)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextColor3 = Color3.fromRGB(255, 220, 150)
		titleLabel.Text = tostring(item.title)
		titleLabel.Parent = row
		local meta = Instance.new("TextLabel")
		meta.Size = UDim2.new(1, -90, 0, 16)
		meta.Position = UDim2.fromOffset(10, 26)
		meta.BackgroundTransparency = 1
		meta.Font = Enum.Font.Gotham
		meta.TextSize = 10
		meta.TextColor3 = Color3.fromRGB(140, 130, 170)
		meta.Text = string.format("%s %s", tostring(item.seasonName), tostring(item.year))
		meta.Parent = row
		local action = Instance.new("TextButton")
		action.Size = UDim2.fromOffset(72, 28)
		action.Position = UDim2.new(1, -82, 0.5, -14)
		action.Font = Enum.Font.GothamBold
		action.TextSize = 10
		action.TextColor3 = Color3.new(1, 1, 1)
		action.Parent = row
		Instance.new("UICorner", action).CornerRadius = UDim.new(0, 5)
		if item.equipped == true then
			action.Text = "Equipped"
			action.BackgroundColor3 = Color3.fromRGB(80, 100, 60)
			action.AutoButtonColor = false
		else
			action.Text = "Equip"
			action.BackgroundColor3 = Color3.fromRGB(120, 90, 50)
			local seasonId = tostring(item.seasonId)
			local titleText = tostring(item.title)
			action.MouseButton1Click:Connect(function()
				local ok, msg = equipSeasonTitle:InvokeServer(seasonId)
				status.Text = msg
				if ok then
					refresh()
				end
			end)
			row.MouseEnter:Connect(function()
				hoverTitle = titleText
				updatePreviewFromEquipped()
			end)
		end
		y += 52
	end
	list.CanvasSize = UDim2.fromOffset(0, y)
	status.Text = string.format("%d titles", #items)
	updatePreviewFromEquipped()
end

local function renderCosmetics()
	clearList()
	hoverTitle = nil
	hoverCosmetic = nil
	unequipBtn.Text = "Unequip Cosmetic"
	local cosmetics = if typeof(fullData) == "table" then fullData.cosmetics else nil
	local items = if typeof(cosmetics) == "table" then cosmetics.items else nil
	if typeof(items) ~= "table" or #items == 0 then
		status.Text = "No cosmetics — claim season rewards (L)"
		list.CanvasSize = UDim2.fromOffset(0, 0)
		updatePreviewFromEquipped()
		return
	end
	local y = 0
	for _, item in items do
		if typeof(item) ~= "table" then
			continue
		end
		local row = makeRow(y, item.equipped == true)
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -90, 0, 22)
		nameLabel.Position = UDim2.fromOffset(10, 6)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 12
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextColor3 = Color3.fromRGB(230, 220, 255)
		nameLabel.Text = tostring(item.displayName or item.id)
		nameLabel.Parent = row
		local meta = Instance.new("TextLabel")
		meta.Size = UDim2.new(1, -90, 0, 16)
		meta.Position = UDim2.fromOffset(10, 26)
		meta.BackgroundTransparency = 1
		meta.Font = Enum.Font.Gotham
		meta.TextSize = 10
		meta.TextColor3 = Color3.fromRGB(140, 130, 170)
		meta.Text = tostring(item.style)
		meta.Parent = row
		local action = Instance.new("TextButton")
		action.Size = UDim2.fromOffset(72, 28)
		action.Position = UDim2.new(1, -82, 0.5, -14)
		action.Font = Enum.Font.GothamBold
		action.TextSize = 10
		action.TextColor3 = Color3.new(1, 1, 1)
		action.Parent = row
		Instance.new("UICorner", action).CornerRadius = UDim.new(0, 5)
		if item.equipped == true then
			action.Text = "Equipped"
			action.BackgroundColor3 = Color3.fromRGB(70, 100, 70)
			action.AutoButtonColor = false
		else
			action.Text = "Equip"
			action.BackgroundColor3 = Color3.fromRGB(80, 110, 160)
			local cosmeticId = tostring(item.id)
			action.MouseButton1Click:Connect(function()
				local ok, msg = equipSeasonCosmetic:InvokeServer(cosmeticId)
				status.Text = msg
				if ok then
					refresh()
				end
			end)
			row.MouseEnter:Connect(function()
				hoverCosmetic = cosmeticId
				updatePreviewFromEquipped()
			end)
		end
		y += 52
	end
	list.CanvasSize = UDim2.fromOffset(0, y)
	status.Text = string.format("%d cosmetics", #items)
	updatePreviewFromEquipped()
end

local function renderPresets()
	clearList()
	hoverTitle = nil
	hoverCosmetic = nil
	unequipBtn.Text = "Save Current → Slot 1"
	local presets = if typeof(fullData) == "table" then fullData.presets else nil
	local slots = if typeof(presets) == "table" then presets.slots else nil
	if typeof(slots) ~= "table" then
		status.Text = "Presets unavailable"
		return
	end
	local y = 0
	for _, slot in slots do
		if typeof(slot) ~= "table" then
			continue
		end
		local row = makeRow(y + 4, false)
		row.Size = UDim2.new(1, -4, 0, 72)
		local slotLabel = Instance.new("TextLabel")
		slotLabel.Size = UDim2.new(1, -10, 0, 18)
		slotLabel.Position = UDim2.fromOffset(10, 6)
		slotLabel.BackgroundTransparency = 1
		slotLabel.Font = Enum.Font.GothamBold
		slotLabel.TextSize = 12
		slotLabel.TextXAlignment = Enum.TextXAlignment.Left
		slotLabel.TextColor3 = Color3.fromRGB(200, 180, 255)
		slotLabel.Text = string.format("Preset %d", slot.slot or 0)
		slotLabel.Parent = row
		local detail = Instance.new("TextLabel")
		detail.Size = UDim2.new(1, -10, 0, 32)
		detail.Position = UDim2.fromOffset(10, 24)
		detail.BackgroundTransparency = 1
		detail.Font = Enum.Font.Gotham
		detail.TextSize = 10
		detail.TextXAlignment = Enum.TextXAlignment.Left
		detail.TextYAlignment = Enum.TextYAlignment.Top
		detail.TextWrapped = true
		detail.TextColor3 = Color3.fromRGB(150, 145, 180)
		local titleLine = slot.titleText or "— no title —"
		local cosmeticLine = slot.cosmeticName or "— no cosmetic —"
		detail.Text = string.format("Title: %s\nCosmetic: %s", titleLine, cosmeticLine)
		detail.Parent = row

		local applyBtn = Instance.new("TextButton")
		applyBtn.Size = UDim2.fromOffset(58, 24)
		applyBtn.Position = UDim2.new(1, -190, 1, -30)
		applyBtn.Text = "Apply"
		applyBtn.Font = Enum.Font.GothamBold
		applyBtn.TextSize = 10
		applyBtn.BackgroundColor3 = Color3.fromRGB(70, 110, 70)
		applyBtn.TextColor3 = Color3.new(1, 1, 1)
		applyBtn.Parent = row
		Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 5)

		local saveBtn = Instance.new("TextButton")
		saveBtn.Size = UDim2.fromOffset(58, 24)
		saveBtn.Position = UDim2.new(1, -126, 1, -30)
		saveBtn.Text = "Save"
		saveBtn.Font = Enum.Font.GothamBold
		saveBtn.TextSize = 10
		saveBtn.BackgroundColor3 = Color3.fromRGB(80, 90, 130)
		saveBtn.TextColor3 = Color3.new(1, 1, 1)
		saveBtn.Parent = row
		Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 5)

		local clearBtn = Instance.new("TextButton")
		clearBtn.Size = UDim2.fromOffset(58, 24)
		clearBtn.Position = UDim2.new(1, -62, 1, -30)
		clearBtn.Text = "Clear"
		clearBtn.Font = Enum.Font.GothamBold
		clearBtn.TextSize = 10
		clearBtn.BackgroundColor3 = Color3.fromRGB(70, 50, 50)
		clearBtn.TextColor3 = Color3.new(1, 1, 1)
		clearBtn.Parent = row
		Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 5)

		local slotIndex = slot.slot
		applyBtn.MouseButton1Click:Connect(function()
			local ok, msg = applyLoadoutPreset:InvokeServer(slotIndex)
			status.Text = msg
			if ok then
				refresh()
			end
		end)
		saveBtn.MouseButton1Click:Connect(function()
			local ok, msg = saveLoadoutPreset:InvokeServer(slotIndex, true)
			status.Text = msg
			if ok then
				refresh()
			end
		end)
		clearBtn.MouseButton1Click:Connect(function()
			local ok, msg = clearLoadoutPreset:InvokeServer(slotIndex)
			status.Text = msg
			if ok then
				refresh()
			end
		end)
		row.MouseEnter:Connect(function()
			hoverTitle = if typeof(slot.titleText) == "string" then slot.titleText else nil
			hoverCosmetic = slot.cosmeticId
			updatePreviewFromEquipped()
		end)
		y += 80
	end
	list.CanvasSize = UDim2.fromOffset(0, y)
	status.Text = "Presets sync across Hub, Eternity City, and Death Valley"
	updatePreviewFromEquipped()
end

local function renderShared()
	clearList()
	hoverTitle = nil
	hoverCosmetic = nil
	unequipBtn.Text = "Refresh Shared"
	local shared = if typeof(fullData) == "table" then fullData.shared else nil
	local inbox = if typeof(shared) == "table" then shared.items else nil
	local y = 0

	local inboxHeader = Instance.new("TextLabel")
	inboxHeader.Size = UDim2.new(1, -4, 0, 20)
	inboxHeader.Position = UDim2.fromOffset(0, y)
	inboxHeader.BackgroundTransparency = 1
	inboxHeader.Font = Enum.Font.GothamBold
	inboxHeader.TextSize = 12
	inboxHeader.TextXAlignment = Enum.TextXAlignment.Left
	inboxHeader.TextColor3 = Color3.fromRGB(200, 180, 255)
	inboxHeader.Text = "From Friends"
	inboxHeader.Parent = list
	y += 24

	if typeof(inbox) ~= "table" or #inbox == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, -4, 0, 36)
		empty.Position = UDim2.fromOffset(0, y)
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 11
		empty.TextWrapped = true
		empty.TextXAlignment = Enum.TextXAlignment.Left
		empty.TextColor3 = Color3.fromRGB(140, 135, 170)
		empty.Text = "No shared presets yet — friends can send you loadout combos"
		empty.Parent = list
		y += 44
	else
		for _, entry in inbox do
			if typeof(entry) ~= "table" then
				continue
			end
			local row = makeRow(y, false)
			row.Size = UDim2.new(1, -4, 0, 64)
			local fromLabel = Instance.new("TextLabel")
			fromLabel.Size = UDim2.new(1, -130, 0, 18)
			fromLabel.Position = UDim2.fromOffset(10, 6)
			fromLabel.BackgroundTransparency = 1
			fromLabel.Font = Enum.Font.GothamBold
			fromLabel.TextSize = 11
			fromLabel.TextXAlignment = Enum.TextXAlignment.Left
			fromLabel.TextColor3 = Color3.fromRGB(220, 210, 255)
			fromLabel.Text = "From " .. tostring(entry.fromDisplayName or "?")
			fromLabel.Parent = row
			local detail = Instance.new("TextLabel")
			detail.Size = UDim2.new(1, -130, 0, 32)
			detail.Position = UDim2.fromOffset(10, 22)
			detail.BackgroundTransparency = 1
			detail.Font = Enum.Font.Gotham
			detail.TextSize = 10
			detail.TextWrapped = true
			detail.TextXAlignment = Enum.TextXAlignment.Left
			detail.TextColor3 = Color3.fromRGB(150, 145, 180)
			detail.Text = string.format(
				"%s · %s",
				tostring(entry.titleText or "— title —"),
				tostring(entry.cosmeticName or "— cosmetic —")
			)
			detail.Parent = row
			local applyBtn = Instance.new("TextButton")
			applyBtn.Size = UDim2.fromOffset(56, 24)
			applyBtn.Position = UDim2.new(1, -120, 0.5, -12)
			applyBtn.Text = "Apply"
			applyBtn.Font = Enum.Font.GothamBold
			applyBtn.TextSize = 10
			applyBtn.BackgroundColor3 = Color3.fromRGB(70, 110, 70)
			applyBtn.TextColor3 = Color3.new(1, 1, 1)
			applyBtn.Parent = row
			Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 5)
			local dismissBtn = Instance.new("TextButton")
			dismissBtn.Size = UDim2.fromOffset(56, 24)
			dismissBtn.Position = UDim2.new(1, -58, 0.5, -12)
			dismissBtn.Text = "Dismiss"
			dismissBtn.Font = Enum.Font.GothamBold
			dismissBtn.TextSize = 10
			dismissBtn.BackgroundColor3 = Color3.fromRGB(70, 50, 50)
			dismissBtn.TextColor3 = Color3.new(1, 1, 1)
			dismissBtn.Parent = row
			Instance.new("UICorner", dismissBtn).CornerRadius = UDim.new(0, 5)
			local shareId = tostring(entry.shareId)
			applyBtn.MouseButton1Click:Connect(function()
				local ok, msg = applySharedPreset:InvokeServer(shareId)
				status.Text = msg
				if ok then
					refresh()
				end
			end)
			dismissBtn.MouseButton1Click:Connect(function()
				local ok, msg = dismissSharedPreset:InvokeServer(shareId)
				status.Text = msg
				if ok then
					refresh()
				end
			end)
			row.MouseEnter:Connect(function()
				hoverTitle = if typeof(entry.titleText) == "string" then entry.titleText else nil
				hoverCosmetic = entry.cosmeticId
				updatePreviewFromEquipped()
			end)
			y += 70
		end
	end

	local codeHeader = Instance.new("TextLabel")
	codeHeader.Size = UDim2.new(1, -4, 0, 20)
	codeHeader.Position = UDim2.fromOffset(0, y + 8)
	codeHeader.BackgroundTransparency = 1
	codeHeader.Font = Enum.Font.GothamBold
	codeHeader.TextSize = 12
	codeHeader.TextXAlignment = Enum.TextXAlignment.Left
	codeHeader.TextColor3 = Color3.fromRGB(200, 180, 255)
	codeHeader.Text = "Share Code / Link"
	codeHeader.Parent = list
	y += 32

	local redeemRow = Instance.new("Frame")
	redeemRow.Size = UDim2.new(1, -4, 0, 30)
	redeemRow.Position = UDim2.fromOffset(0, y)
	redeemRow.BackgroundTransparency = 1
	redeemRow.Parent = list
	local redeemBox = Instance.new("TextBox")
	redeemBox.Size = UDim2.new(1, -92, 1, 0)
	redeemBox.BackgroundColor3 = Color3.fromRGB(30, 26, 44)
	redeemBox.TextColor3 = Color3.new(1, 1, 1)
	redeemBox.PlaceholderText = "UTOPIA-XXXXXXXX"
	redeemBox.Font = Enum.Font.Gotham
	redeemBox.TextSize = 11
	redeemBox.ClearTextOnFocus = false
	redeemBox.Parent = redeemRow
	Instance.new("UICorner", redeemBox).CornerRadius = UDim.new(0, 5)
	local redeemBtn = Instance.new("TextButton")
	redeemBtn.Size = UDim2.fromOffset(84, 28)
	redeemBtn.Position = UDim2.new(1, -84, 0.5, -14)
	redeemBtn.Text = "Redeem"
	redeemBtn.Font = Enum.Font.GothamBold
	redeemBtn.TextSize = 10
	redeemBtn.BackgroundColor3 = Color3.fromRGB(70, 100, 140)
	redeemBtn.TextColor3 = Color3.new(1, 1, 1)
	redeemBtn.Parent = redeemRow
	Instance.new("UICorner", redeemBtn).CornerRadius = UDim.new(0, 5)
	redeemBtn.MouseButton1Click:Connect(function()
		local ok, msg = redeemPresetShareCode:InvokeServer(redeemBox.Text)
		status.Text = if typeof(msg) == "string" then msg else tostring(msg)
		if ok then
			redeemBox.Text = ""
			refresh()
		end
	end)
	y += 38

	local shareCodes = if typeof(fullData) == "table" then fullData.shareCodes else nil
	local activeCodes = if typeof(shareCodes) == "table" then shareCodes.codes else nil
	if typeof(activeCodes) == "table" and #activeCodes > 0 then
		for _, codeEntry in activeCodes do
			if typeof(codeEntry) ~= "table" then
				continue
			end
			local codeLabel = Instance.new("TextLabel")
			codeLabel.Size = UDim2.new(1, -4, 0, 18)
			codeLabel.Position = UDim2.fromOffset(0, y)
			codeLabel.BackgroundTransparency = 1
			codeLabel.Font = Enum.Font.Gotham
			codeLabel.TextSize = 10
			codeLabel.TextXAlignment = Enum.TextXAlignment.Left
			codeLabel.TextColor3 = Color3.fromRGB(170, 200, 255)
			codeLabel.Text = string.format(
				"Slot %s · %s",
				tostring(codeEntry.slotIndex or "?"),
				tostring(codeEntry.shareLink or codeEntry.code or "?")
			)
			codeLabel.Parent = list
			y += 20
		end
		y += 4
	end

	local genBtn = Instance.new("TextButton")
	genBtn.Size = UDim2.fromOffset(180, 26)
	genBtn.Position = UDim2.fromOffset(0, y)
	genBtn.Text = string.format("Generate Code (Slot %d)", selectedShareSlot)
	genBtn.Font = Enum.Font.GothamBold
	genBtn.TextSize = 10
	genBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 150)
	genBtn.TextColor3 = Color3.new(1, 1, 1)
	genBtn.Parent = list
	Instance.new("UICorner", genBtn).CornerRadius = UDim.new(0, 5)
	genBtn.MouseButton1Click:Connect(function()
		local ok, result = generatePresetShareCode:InvokeServer(selectedShareSlot)
		if ok and typeof(result) == "table" then
			status.Text = string.format("Share link: %s (24h)", tostring(result.shareLink or result.code))
			refresh()
		else
			status.Text = if typeof(result) == "string" then result else "Could not generate code"
		end
	end)
	y += 34

	local shareHeader = Instance.new("TextLabel")
	shareHeader.Size = UDim2.new(1, -4, 0, 20)
	shareHeader.Position = UDim2.fromOffset(0, y + 8)
	shareHeader.BackgroundTransparency = 1
	shareHeader.Font = Enum.Font.GothamBold
	shareHeader.TextSize = 12
	shareHeader.TextXAlignment = Enum.TextXAlignment.Left
	shareHeader.TextColor3 = Color3.fromRGB(200, 180, 255)
	shareHeader.Text = string.format("Share Preset Slot %d → Friend", selectedShareSlot)
	shareHeader.Parent = list
	y += 32

	for slotIndex = 1, 3 do
		local slotBtn = Instance.new("TextButton")
		slotBtn.Size = UDim2.fromOffset(56, 24)
		slotBtn.Position = UDim2.fromOffset((slotIndex - 1) * 62, y)
		slotBtn.Text = "Slot " .. tostring(slotIndex)
		slotBtn.Font = Enum.Font.GothamBold
		slotBtn.TextSize = 10
		slotBtn.TextColor3 = Color3.new(1, 1, 1)
		slotBtn.BackgroundColor3 = if slotIndex == selectedShareSlot
			then Color3.fromRGB(90, 70, 120)
			else Color3.fromRGB(50, 45, 65)
		slotBtn.Parent = list
		Instance.new("UICorner", slotBtn).CornerRadius = UDim.new(0, 5)
		slotBtn.MouseButton1Click:Connect(function()
			selectedShareSlot = slotIndex
			renderShared()
		end)
	end
	y += 32

	local friends = getLfgFriendsList:InvokeServer()
	if typeof(friends) ~= "table" or #friends == 0 then
		local noFriends = Instance.new("TextLabel")
		noFriends.Size = UDim2.new(1, -4, 0, 28)
		noFriends.Position = UDim2.fromOffset(0, y)
		noFriends.BackgroundTransparency = 1
		noFriends.Font = Enum.Font.Gotham
		noFriends.TextSize = 11
		noFriends.TextColor3 = Color3.fromRGB(140, 135, 170)
		noFriends.Text = "No friends loaded — share works with Roblox friends (online anywhere in Utopia)"
		noFriends.Parent = list
		y += 32
	else
		for _, friend in friends do
			if typeof(friend) ~= "table" then
				continue
			end
			local row = makeRow(y, false)
			row.Size = UDim2.new(1, -4, 0, 36)
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, -170, 1, 0)
			nameLabel.Position = UDim2.fromOffset(10, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Font = Enum.Font.Gotham
			nameLabel.TextSize = 10
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextColor3 = if friend.online == true
				then Color3.fromRGB(220, 225, 255)
				else Color3.fromRGB(120, 115, 150)
			nameLabel.Text = tostring(friend.displayName or friend.username) .. friendStatusTag(friend)
			nameLabel.Parent = row
			local joinBtn = Instance.new("TextButton")
			joinBtn.Size = UDim2.fromOffset(56, 26)
			joinBtn.Position = UDim2.new(1, -146, 0.5, -13)
			joinBtn.Text = "Join"
			joinBtn.Font = Enum.Font.GothamBold
			joinBtn.TextSize = 10
			joinBtn.BackgroundColor3 = Color3.fromRGB(70, 120, 90)
			joinBtn.TextColor3 = Color3.new(1, 1, 1)
			joinBtn.Active = friend.online == true
			joinBtn.AutoButtonColor = friend.online == true
			joinBtn.BackgroundTransparency = if friend.online == true then 0 else 0.45
			joinBtn.Parent = row
			Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 5)
			local sendBtn = Instance.new("TextButton")
			sendBtn.Size = UDim2.fromOffset(56, 26)
			sendBtn.Position = UDim2.new(1, -82, 0.5, -13)
			sendBtn.Text = "Share"
			sendBtn.Font = Enum.Font.GothamBold
			sendBtn.TextSize = 10
			sendBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 150)
			sendBtn.TextColor3 = Color3.new(1, 1, 1)
			sendBtn.Active = friend.online == true
			sendBtn.AutoButtonColor = friend.online == true
			sendBtn.BackgroundTransparency = if friend.online == true then 0 else 0.45
			sendBtn.Parent = row
			Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(0, 5)
			if friend.online == true then
				local targetUserId = friend.userId
				joinBtn.MouseButton1Click:Connect(function()
					local ok, msg = teleportToFriend:InvokeServer(targetUserId)
					status.Text = msg
				end)
				sendBtn.MouseButton1Click:Connect(function()
					local ok, msg = shareLoadoutPreset:InvokeServer(selectedShareSlot, targetUserId)
					status.Text = msg
				end)
			end
			y += 42
		end
	end

	list.CanvasSize = UDim2.fromOffset(0, y + 8)
	status.Text = "Share presets with friends · codes work cross-server · apply only items you own"
	updatePreviewFromEquipped()
end

local function renderMarket()
	clearList()
	hoverTitle = nil
	hoverCosmetic = nil
	unequipBtn.Text = "Push Alerts"
	local y = 0

	local carouselHeader = Instance.new("TextLabel")
	carouselHeader.Size = UDim2.new(1, -4, 0, 18)
	carouselHeader.Position = UDim2.fromOffset(0, y)
	carouselHeader.BackgroundTransparency = 1
	carouselHeader.Font = Enum.Font.GothamBold
	carouselHeader.TextSize = 12
	carouselHeader.TextXAlignment = Enum.TextXAlignment.Left
	carouselHeader.TextColor3 = Color3.fromRGB(255, 210, 120)
	carouselHeader.Text = "Featured Carousel"
	carouselHeader.Parent = list
	y += 20

	local carousel = getFeaturedCarousel:InvokeServer()
	local rotation = if typeof(carousel) == "table" then carousel.rotation else nil
	if typeof(rotation) == "table" and typeof(rotation.seasonName) == "string" then
		local seasonLabel = Instance.new("TextLabel")
		seasonLabel.Size = UDim2.new(1, -4, 0, 16)
		seasonLabel.Position = UDim2.fromOffset(0, y)
		seasonLabel.BackgroundTransparency = 1
		seasonLabel.Font = Enum.Font.Gotham
		seasonLabel.TextSize = 10
		seasonLabel.TextXAlignment = Enum.TextXAlignment.Left
		seasonLabel.TextColor3 = Color3.fromRGB(180, 210, 255)
		seasonLabel.Text = string.format("Season spotlight: %s", rotation.seasonName)
		seasonLabel.Parent = list
		y += 18
	end
	local carouselListings = if typeof(carousel) == "table" then carousel.listings else nil
	local carouselPacks = if typeof(carousel) == "table" then carousel.packs else nil

	local cardX = 0
	if typeof(carouselListings) == "table" then
		for _, entry in carouselListings do
			if typeof(entry) ~= "table" or cardX >= 420 then
				continue
			end
			local card = Instance.new("TextButton")
			card.Size = UDim2.fromOffset(130, 56)
			card.Position = UDim2.fromOffset(cardX, y)
			card.BackgroundColor3 = Color3.fromRGB(38, 32, 58)
			card.Text = string.format(
				"★ %s\n%s",
				tostring(entry.authorDisplayName or "?"),
				tostring(entry.cosmeticName or entry.titleText or "Loadout")
			)
			card.Font = Enum.Font.Gotham
			card.TextSize = 9
			card.TextColor3 = Color3.new(1, 1, 1)
			card.TextWrapped = true
			card.Parent = list
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
			local listingId = tostring(entry.listingId)
			card.MouseButton1Click:Connect(function()
				local ok, msg = acquirePresetMarket:InvokeServer(listingId)
				status.Text = msg
				if ok then
					setTab("shared")
				end
			end)
			cardX += 136
		end
	end
	y += 64

	local packsHeader = Instance.new("TextLabel")
	packsHeader.Size = UDim2.new(1, -4, 0, 18)
	packsHeader.Position = UDim2.fromOffset(0, y)
	packsHeader.BackgroundTransparency = 1
	packsHeader.Font = Enum.Font.GothamBold
	packsHeader.TextSize = 11
	packsHeader.TextXAlignment = Enum.TextXAlignment.Left
	packsHeader.TextColor3 = Color3.fromRGB(200, 180, 255)
	packsHeader.Text = "Robux Preset Packs"
	packsHeader.Parent = list
	y += 22

	local packs = carouselPacks
	if typeof(packs) ~= "table" or #packs == 0 then
		local packCatalog = getPresetPackCatalog:InvokeServer()
		packs = if typeof(packCatalog) == "table" then packCatalog.items else {}
	end
	if typeof(packs) == "table" then
		for _, pack in packs do
			if typeof(pack) ~= "table" then
				continue
			end
			local row = makeRow(y, false)
			row.Size = UDim2.new(1, -4, 0, 52)
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, -100, 0, 18)
			nameLabel.Position = UDim2.fromOffset(10, 6)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 10
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextColor3 = Color3.fromRGB(220, 225, 255)
			nameLabel.Text = tostring(pack.displayName or pack.id)
			nameLabel.Parent = row
			local detail = Instance.new("TextLabel")
			detail.Size = UDim2.new(1, -100, 0, 28)
			detail.Position = UDim2.fromOffset(10, 22)
			detail.BackgroundTransparency = 1
			detail.Font = Enum.Font.Gotham
			detail.TextSize = 9
			detail.TextWrapped = true
			detail.TextXAlignment = Enum.TextXAlignment.Left
			detail.TextColor3 = Color3.fromRGB(150, 145, 180)
			detail.Text = string.format(
				"%s · R$ %s",
				tostring(pack.description or "Curated loadout"),
				tostring(pack.robux or "?")
			)
			detail.Parent = row
			local buyBtn = Instance.new("TextButton")
			buyBtn.Size = UDim2.fromOffset(72, 26)
			buyBtn.Position = UDim2.new(1, -82, 0.5, -13)
			buyBtn.Text = if pack.owned == true then "Owned" else "Buy"
			buyBtn.Font = Enum.Font.GothamBold
			buyBtn.TextSize = 10
			buyBtn.BackgroundColor3 = Color3.fromRGB(120, 90, 40)
			buyBtn.TextColor3 = Color3.new(1, 1, 1)
			buyBtn.Active = pack.owned ~= true
			buyBtn.BackgroundTransparency = if pack.owned == true then 0.5 else 0
			buyBtn.Parent = row
			Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 5)
			if pack.owned ~= true then
				local packId = tostring(pack.id)
				buyBtn.MouseButton1Click:Connect(function()
					local ok, msg = purchasePresetPack:InvokeServer(packId)
					status.Text = msg
					if ok then
						refresh()
					end
				end)
			end
			y += 58
		end
	end
	y += 8

	local prefsBtn = Instance.new("TextButton")
	prefsBtn.Size = UDim2.fromOffset(120, 24)
	prefsBtn.Position = UDim2.fromOffset(0, y)
	prefsBtn.Text = "Enable Push"
	prefsBtn.Font = Enum.Font.GothamBold
	prefsBtn.TextSize = 10
	prefsBtn.BackgroundColor3 = Color3.fromRGB(60, 90, 120)
	prefsBtn.TextColor3 = Color3.new(1, 1, 1)
	prefsBtn.Parent = list
	Instance.new("UICorner", prefsBtn).CornerRadius = UDim.new(0, 5)
	prefsBtn.MouseButton1Click:Connect(function()
		local ok, msg = setSocialNotifyPrefs:InvokeServer({
			pushOptIn = true,
			presetShare = true,
			friendOnline = true,
			marketFeatured = true,
		})
		status.Text = msg
	end)
	y += 32

	local creatorSummary = getCreatorRevenueSummary:InvokeServer()
	if typeof(creatorSummary) == "table" then
		local earningsLabel = Instance.new("TextLabel")
		earningsLabel.Size = UDim2.new(1, -4, 0, 28)
		earningsLabel.Position = UDim2.fromOffset(0, y)
		earningsLabel.BackgroundTransparency = 1
		earningsLabel.Font = Enum.Font.Gotham
		earningsLabel.TextSize = 10
		earningsLabel.TextWrapped = true
		earningsLabel.TextXAlignment = Enum.TextXAlignment.Left
		earningsLabel.TextColor3 = Color3.fromRGB(170, 200, 160)
		earningsLabel.Text = string.format(
			"Creator credits: %d · %d%% pack revenue share · +5 credits per Bazaar download",
			tonumber(creatorSummary.balance) or 0,
			tonumber(creatorSummary.creatorSharePercent) or 70
		)
		earningsLabel.Parent = list
		y += 28

		local minPayout = tonumber(creatorSummary.minPayout) or 100
		local hasPendingPayout = false
		local payoutHistory = creatorSummary.payoutHistory
		if typeof(payoutHistory) == "table" then
			for _, req in payoutHistory do
				if typeof(req) == "table" and (req.status == "pending" or req.status == "exported") then
					hasPendingPayout = true
					break
				end
			end
		end

		local payoutHint = Instance.new("TextLabel")
		payoutHint.Size = UDim2.new(1, -4, 0, 16)
		payoutHint.Position = UDim2.fromOffset(0, y)
		payoutHint.BackgroundTransparency = 1
		payoutHint.Font = Enum.Font.Gotham
		payoutHint.TextSize = 9
		payoutHint.TextXAlignment = Enum.TextXAlignment.Left
		payoutHint.TextColor3 = Color3.fromRGB(150, 170, 140)
		payoutHint.Text = string.format("Minimum payout: %d credits", minPayout)
		payoutHint.Parent = list
		y += 20

		local groupId = tonumber(creatorSummary.groupId) or 0
		local communityUrl = if typeof(creatorSummary.communityUrl) == "string"
			then creatorSummary.communityUrl
			else ""
		if groupId > 0 and communityUrl ~= "" then
			local communityHint = Instance.new("TextLabel")
			communityHint.Size = UDim2.new(1, -4, 0, 28)
			communityHint.Position = UDim2.fromOffset(0, y)
			communityHint.BackgroundTransparency = 1
			communityHint.Font = Enum.Font.Gotham
			communityHint.TextSize = 9
			communityHint.TextWrapped = true
			communityHint.TextXAlignment = Enum.TextXAlignment.Left
			communityHint.TextColor3 = Color3.fromRGB(120, 180, 220)
			communityHint.Text = string.format("Community %d — payouts via Roblox Group treasurer", groupId)
			communityHint.Parent = list
			y += 30
		end

		local payoutBtn = Instance.new("TextButton")
		payoutBtn.Size = UDim2.fromOffset(140, 24)
		payoutBtn.Position = UDim2.fromOffset(0, y)
		payoutBtn.Text = if hasPendingPayout then "Payout Pending…" else "Request Group Payout"
		payoutBtn.Font = Enum.Font.GothamBold
		payoutBtn.TextSize = 10
		payoutBtn.BackgroundColor3 = Color3.fromRGB(90, 120, 80)
		payoutBtn.TextColor3 = Color3.new(1, 1, 1)
		payoutBtn.Active = not hasPendingPayout
		payoutBtn.AutoButtonColor = not hasPendingPayout
		payoutBtn.BackgroundTransparency = if hasPendingPayout then 0.45 else 0
		payoutBtn.Parent = list
		Instance.new("UICorner", payoutBtn).CornerRadius = UDim.new(0, 5)
		if not hasPendingPayout then
			payoutBtn.MouseButton1Click:Connect(function()
				local ok, msg = requestCreatorPayout:InvokeServer()
				status.Text = msg
				if ok then
					renderMarket()
				end
			end)
		end
		y += 30

		local historyHeader = Instance.new("TextLabel")
		historyHeader.Size = UDim2.new(1, -4, 0, 16)
		historyHeader.Position = UDim2.fromOffset(0, y)
		historyHeader.BackgroundTransparency = 1
		historyHeader.Font = Enum.Font.GothamBold
		historyHeader.TextSize = 10
		historyHeader.TextXAlignment = Enum.TextXAlignment.Left
		historyHeader.TextColor3 = Color3.fromRGB(200, 180, 255)
		historyHeader.Text = "Payout History"
		historyHeader.Parent = list
		y += 20

		if typeof(payoutHistory) == "table" and #payoutHistory > 0 then
			for _, req in payoutHistory do
				if typeof(req) ~= "table" then
					continue
				end
				local row = Instance.new("TextLabel")
				row.Size = UDim2.new(1, -4, 0, 18)
				row.Position = UDim2.fromOffset(0, y)
				row.BackgroundTransparency = 1
				row.Font = Enum.Font.Gotham
				row.TextSize = 9
				row.TextXAlignment = Enum.TextXAlignment.Left
				row.TextColor3 = if req.status == "pending"
					then Color3.fromRGB(255, 190, 90)
					elseif req.status == "exported"
					then Color3.fromRGB(120, 180, 255)
					elseif req.status == "paid"
					then Color3.fromRGB(120, 210, 140)
					else Color3.fromRGB(150, 170, 150)
				local dateLabel = if req.status == "exported" and req.exportedAt
					then formatPayoutDate(req.exportedAt)
					elseif req.status == "paid" and req.paidAt
					then formatPayoutDate(req.paidAt)
					else formatPayoutDate(req.createdAt)
				row.Text = string.format(
					"%s · %d credits · %s",
					tostring(req.status or "?"),
					tonumber(req.amount) or 0,
					dateLabel
				)
				row.Parent = list
				y += 20
			end
		else
			local emptyHistory = Instance.new("TextLabel")
			emptyHistory.Size = UDim2.new(1, -4, 0, 18)
			emptyHistory.Position = UDim2.fromOffset(0, y)
			emptyHistory.BackgroundTransparency = 1
			emptyHistory.Font = Enum.Font.Gotham
			emptyHistory.TextSize = 9
			emptyHistory.TextXAlignment = Enum.TextXAlignment.Left
			emptyHistory.TextColor3 = Color3.fromRGB(120, 115, 140)
			emptyHistory.Text = "No payout requests yet"
			emptyHistory.Parent = list
			y += 20
		end
		y += 8
	end

	local marketPayload = getPresetMarket:InvokeServer()
	local myPublished = if typeof(marketPayload) == "table" then marketPayload.published else nil
	if typeof(myPublished) == "table" and #myPublished > 0 then
		local mineHeader = Instance.new("TextLabel")
		mineHeader.Size = UDim2.new(1, -4, 0, 18)
		mineHeader.Position = UDim2.fromOffset(0, y)
		mineHeader.BackgroundTransparency = 1
		mineHeader.Font = Enum.Font.GothamBold
		mineHeader.TextSize = 11
		mineHeader.TextXAlignment = Enum.TextXAlignment.Left
		mineHeader.TextColor3 = Color3.fromRGB(200, 180, 255)
		mineHeader.Text = "My Published Listings"
		mineHeader.Parent = list
		y += 22

		for _, pub in myPublished do
			if typeof(pub) ~= "table" then
				continue
			end
			local row = makeRow(y, false)
			row.Size = UDim2.new(1, -4, 0, 44)
			local listingId = tostring(pub.listingId)
			local listing = if typeof(pub.listing) == "table" then pub.listing else pub
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -120, 1, -8)
			label.Position = UDim2.fromOffset(10, 4)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.Gotham
			label.TextSize = 9
			label.TextWrapped = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextColor3 = Color3.fromRGB(180, 175, 210)
			label.Text = string.format(
				"Slot %s · %s / %s",
				tostring(pub.slotIndex or "?"),
				tostring(listing.cosmeticName or "—"),
				tostring(listing.titleText or "—")
			)
			label.Parent = row
			local ugcBtn = Instance.new("TextButton")
			ugcBtn.Size = UDim2.fromOffset(100, 24)
			ugcBtn.Position = UDim2.new(1, -110, 0.5, -12)
			if typeof(pub.ugcPackId) == "string" and pub.ugcPackId ~= "" then
				ugcBtn.Text = string.format("UGC R$%s", tostring(pub.ugcRobux or "?"))
				ugcBtn.Active = false
				ugcBtn.BackgroundTransparency = 0.4
			else
				ugcBtn.Text = "Sell as Pack"
			end
			ugcBtn.Font = Enum.Font.GothamBold
			ugcBtn.TextSize = 9
			ugcBtn.BackgroundColor3 = Color3.fromRGB(110, 80, 140)
			ugcBtn.TextColor3 = Color3.new(1, 1, 1)
			ugcBtn.Parent = row
			Instance.new("UICorner", ugcBtn).CornerRadius = UDim.new(0, 5)
			if typeof(pub.ugcPackId) ~= "string" or pub.ugcPackId == "" then
				local previewListing = {
					slotIndex = pub.slotIndex,
					cosmeticName = listing.cosmeticName,
					titleText = listing.titleText,
				}
				ugcBtn.MouseButton1Click:Connect(function()
					showUgcPricePicker(listingId, previewListing, creatorSummary or {})
				end)
			end
			y += 50
		end
		y += 8
	end

	local publishBtn = Instance.new("TextButton")
	publishBtn.Size = UDim2.fromOffset(180, 26)
	publishBtn.Position = UDim2.fromOffset(0, y)
	publishBtn.Text = string.format("Publish Slot %d to Bazaar", selectedShareSlot)
	publishBtn.Font = Enum.Font.GothamBold
	publishBtn.TextSize = 10
	publishBtn.BackgroundColor3 = Color3.fromRGB(80, 130, 100)
	publishBtn.TextColor3 = Color3.new(1, 1, 1)
	publishBtn.Parent = list
	Instance.new("UICorner", publishBtn).CornerRadius = UDim.new(0, 5)
	publishBtn.MouseButton1Click:Connect(function()
		local ok, result = publishPresetMarket:InvokeServer(selectedShareSlot, { "community" })
		if ok and typeof(result) == "table" then
			status.Text = string.format("Published · %s", tostring(result.shareLink or "listed"))
			refresh()
		else
			status.Text = if typeof(result) == "string" then result else "Publish failed"
		end
	end)
	y += 34

	for slotIndex = 1, 3 do
		local slotBtn = Instance.new("TextButton")
		slotBtn.Size = UDim2.fromOffset(56, 24)
		slotBtn.Position = UDim2.fromOffset((slotIndex - 1) * 62, y)
		slotBtn.Text = "Slot " .. tostring(slotIndex)
		slotBtn.Font = Enum.Font.GothamBold
		slotBtn.TextSize = 10
		slotBtn.TextColor3 = Color3.new(1, 1, 1)
		slotBtn.BackgroundColor3 = if slotIndex == selectedShareSlot
			then Color3.fromRGB(90, 70, 120)
			else Color3.fromRGB(50, 45, 65)
		slotBtn.Parent = list
		Instance.new("UICorner", slotBtn).CornerRadius = UDim.new(0, 5)
		slotBtn.MouseButton1Click:Connect(function()
			selectedShareSlot = slotIndex
			renderMarket()
		end)
	end
	y += 32

	local browse = browsePresetMarket:InvokeServer(marketPage)
	local items = if typeof(browse) == "table" then browse.items else nil
	if typeof(items) ~= "table" or #items == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, -4, 0, 36)
		empty.Position = UDim2.fromOffset(0, y)
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 11
		empty.TextColor3 = Color3.fromRGB(140, 135, 170)
		empty.Text = "No marketplace listings yet — publish a preset to start the bazaar"
		empty.Parent = list
		y += 44
	else
		for _, entry in items do
			if typeof(entry) ~= "table" then
				continue
			end
			local row = makeRow(y, false)
			row.Size = UDim2.new(1, -4, 0, 64)
			local titleLabel = Instance.new("TextLabel")
			titleLabel.Size = UDim2.new(1, -150, 0, 18)
			titleLabel.Position = UDim2.fromOffset(10, 6)
			titleLabel.BackgroundTransparency = 1
			titleLabel.Font = Enum.Font.GothamBold
			titleLabel.TextSize = 10
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel.TextColor3 = Color3.fromRGB(220, 225, 255)
			titleLabel.Text = tostring(entry.authorDisplayName or "?")
			titleLabel.Parent = row
			local detail = Instance.new("TextLabel")
			detail.Size = UDim2.new(1, -150, 0, 32)
			detail.Position = UDim2.fromOffset(10, 22)
			detail.BackgroundTransparency = 1
			detail.Font = Enum.Font.Gotham
			detail.TextSize = 10
			detail.TextWrapped = true
			detail.TextXAlignment = Enum.TextXAlignment.Left
			detail.TextColor3 = Color3.fromRGB(150, 145, 180)
			detail.Text = string.format(
				"%s · %s · ♥ %s",
				tostring(entry.titleText or "—"),
				tostring(entry.cosmeticName or "—"),
				tostring(entry.likes or 0)
			)
			detail.Parent = row
			local getBtn = Instance.new("TextButton")
			getBtn.Size = UDim2.fromOffset(56, 24)
			getBtn.Position = UDim2.new(1, -120, 0.5, -12)
			getBtn.Text = "Get"
			getBtn.Font = Enum.Font.GothamBold
			getBtn.TextSize = 10
			getBtn.BackgroundColor3 = Color3.fromRGB(70, 110, 70)
			getBtn.TextColor3 = Color3.new(1, 1, 1)
			getBtn.Parent = row
			Instance.new("UICorner", getBtn).CornerRadius = UDim.new(0, 5)
			local likeBtn = Instance.new("TextButton")
			likeBtn.Size = UDim2.fromOffset(50, 24)
			likeBtn.Position = UDim2.new(1, -58, 0.5, -12)
			likeBtn.Text = "Like"
			likeBtn.Font = Enum.Font.GothamBold
			likeBtn.TextSize = 10
			likeBtn.BackgroundColor3 = Color3.fromRGB(80, 70, 110)
			likeBtn.TextColor3 = Color3.new(1, 1, 1)
			likeBtn.Parent = row
			Instance.new("UICorner", likeBtn).CornerRadius = UDim.new(0, 5)
			local listingId = tostring(entry.listingId)
			getBtn.MouseButton1Click:Connect(function()
				local ok, msg = acquirePresetMarket:InvokeServer(listingId)
				status.Text = msg
				if ok then
					setTab("shared")
				end
			end)
			likeBtn.MouseButton1Click:Connect(function()
				local ok, msg = likePresetMarket:InvokeServer(listingId)
				status.Text = msg
				if ok then
					renderMarket()
				end
			end)
			row.MouseEnter:Connect(function()
				hoverTitle = if typeof(entry.titleText) == "string" then entry.titleText else nil
				hoverCosmetic = entry.cosmeticId
				updatePreviewFromEquipped()
			end)
			y += 70
		end
	end

	list.CanvasSize = UDim2.fromOffset(0, y + 8)
	status.Text = "Preset Bazaar · apply only items you own · share codes valid 24h"
	updatePreviewFromEquipped()
end

local function renderActiveTab()
	if activeTab == "titles" then
		renderTitles()
	elseif activeTab == "cosmetics" then
		renderCosmetics()
	elseif activeTab == "shared" then
		renderShared()
	elseif activeTab == "market" then
		renderMarket()
	else
		renderPresets()
	end
	for tabId, button in tabButtons do
		button.BackgroundColor3 = if tabId == activeTab
			then Color3.fromRGB(90, 70, 120)
			else Color3.fromRGB(40, 36, 56)
	end
end

local function setTab(tabId: TabId)
	activeTab = tabId
	renderActiveTab()
end

local tabDefs: { { id: TabId, label: string } } = {
	{ id = "titles", label = "Titles" },
	{ id = "cosmetics", label = "Cosms" },
	{ id = "presets", label = "Presets" },
	{ id = "shared", label = "Shared" },
	{ id = "market", label = "Bazaar" },
}
for index, def in tabDefs do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(64, 28)
	btn.Position = UDim2.fromOffset((index - 1) * 66, 2)
	btn.Text = def.label
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.BackgroundColor3 = Color3.fromRGB(40, 36, 56)
	btn.Parent = tabBar
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	tabButtons[def.id] = btn
	btn.MouseButton1Click:Connect(function()
		setTab(def.id)
	end)
end

local function refresh()
	fullData = getLoadoutFull:InvokeServer()
	renderActiveTab()
end

local function setVisible(visible: boolean)
	gui.Enabled = visible
	if visible then
		refresh()
	end
end

local function openWithTab(tabId: TabId?)
	if tabId then
		setTab(tabId)
	end
	setVisible(true)
end

unequipBtn.MouseButton1Click:Connect(function()
	if activeTab == "titles" then
		local ok, msg = unequipSeasonTitle:InvokeServer()
		status.Text = msg
		if ok then
			refresh()
		end
	elseif activeTab == "cosmetics" then
		local ok, msg = unequipSeasonCosmetic:InvokeServer()
		status.Text = msg
		if ok then
			refresh()
		end
	elseif activeTab == "shared" or activeTab == "market" then
		refresh()
	else
		local ok, msg = saveLoadoutPreset:InvokeServer(1, true)
		status.Text = msg
		if ok then
			refresh()
		end
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	setVisible(false)
end)

backdrop.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		setVisible(false)
	end
end)

ContextActionService:BindAction("ToggleDVUnifiedLoadout", function(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	openWithTab("titles")
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.V)

ContextActionService:BindAction("ToggleDVUnifiedLoadoutTitle", function(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	openWithTab("titles")
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.T)

ContextActionService:BindAction("ToggleDVUnifiedLoadoutCosmetic", function(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	openWithTab("cosmetics")
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.C)

player:GetAttributeChangedSignal("DV_OpenUnifiedLoadoutTab"):Connect(function()
	local mode = player:GetAttribute("DV_OpenUnifiedLoadoutTab")
	if typeof(mode) ~= "string" or mode == "" then
		return
	end
	player:SetAttribute("DV_OpenUnifiedLoadoutTab", "")
	if mode == "cosmetic" or mode == "cosmetics" then
		openWithTab("cosmetics")
	elseif mode == "title" or mode == "titles" then
		openWithTab("titles")
	elseif mode == "preset" or mode == "presets" then
		openWithTab("presets")
	elseif mode == "shared" or mode == "share" then
		openWithTab("shared")
	elseif mode == "market" or mode == "bazaar" then
		openWithTab("market")
	else
		openWithTab("titles")
	end
end)

player:GetAttributeChangedSignal("DV_MirrorMessage"):Connect(function()
	local msg = player:GetAttribute("DV_MirrorMessage")
	if typeof(msg) == "string" and msg ~= "" and gui.Enabled then
		status.Text = msg
	end
end)

player:GetAttributeChangedSignal("DV_PresetShareMsg"):Connect(function()
	local msg = player:GetAttribute("DV_PresetShareMsg")
	if typeof(msg) == "string" and msg ~= "" then
		status.Text = msg
		if gui.Enabled and activeTab == "shared" then
			refresh()
		end
	end
end)

print("[DeathValley] Unified loadout UI ready (V · T · C · Shared tab)")
