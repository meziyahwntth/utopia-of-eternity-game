--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("DungeonRemotes")
local getCatalog = remotes:WaitForChild("GetLoadoutCatalog") :: RemoteFunction
local saveLoadout = remotes:WaitForChild("SaveLoadout") :: RemoteFunction

local PALETTE = {
	Pearl = Color3.fromRGB(245, 245, 240),
	Gold = Color3.fromRGB(212, 175, 55),
	Cyan = Color3.fromRGB(0, 229, 255),
	Amber = Color3.fromRGB(255, 179, 71),
	Dark = Color3.fromRGB(18, 14, 28),
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DungeonLoadoutUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "LoadoutRoot"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(560, 560)
root.BackgroundColor3 = PALETTE.Dark
root.BorderSizePixel = 0
root.Visible = false
root.Parent = screenGui

Instance.new("UICorner", root).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke")
stroke.Color = PALETTE.Amber
stroke.Thickness = 2
stroke.Parent = root

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(16, 10)
title.Size = UDim2.new(1, -70, 0, 28)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = PALETTE.Pearl
title.Text = "Hellbound Loadout — Zone 1 Duo"
title.Parent = root

local weightLabel = Instance.new("TextLabel")
weightLabel.BackgroundTransparency = 1
weightLabel.Position = UDim2.fromOffset(16, 38)
weightLabel.Size = UDim2.new(1, -32, 0, 20)
weightLabel.Font = Enum.Font.Gotham
weightLabel.TextSize = 14
weightLabel.TextXAlignment = Enum.TextXAlignment.Left
weightLabel.TextColor3 = PALETTE.Cyan
weightLabel.Text = "Weight: 0 / 50"
weightLabel.Parent = root

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -12, 0, 10)
closeBtn.Size = UDim2.fromOffset(36, 36)
closeBtn.BackgroundColor3 = PALETTE.Gold
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = PALETTE.Dark
closeBtn.Text = "X"
closeBtn.Parent = root
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local roleRow = Instance.new("Frame")
roleRow.BackgroundTransparency = 1
roleRow.Position = UDim2.fromOffset(16, 64)
roleRow.Size = UDim2.new(1, -32, 0, 36)
roleRow.Parent = root

local roleLayout = Instance.new("UIListLayout")
roleLayout.FillDirection = Enum.FillDirection.Horizontal
roleLayout.Padding = UDim.new(0, 6)
roleLayout.Parent = roleRow

local itemList = Instance.new("ScrollingFrame")
itemList.Position = UDim2.fromOffset(16, 108)
itemList.Size = UDim2.new(1, -32, 1, -250)
itemList.BackgroundTransparency = 1
itemList.BorderSizePixel = 0
itemList.ScrollBarThickness = 6
itemList.CanvasSize = UDim2.fromOffset(0, 0)
itemList.Parent = root

local itemLayout = Instance.new("UIListLayout")
itemLayout.Padding = UDim.new(0, 6)
itemLayout.Parent = itemList

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.new(0, 16, 1, -176)
status.Size = UDim2.new(1, -32, 0, 52)
status.Font = Enum.Font.Gotham
status.TextSize = 13
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextColor3 = PALETTE.Pearl
status.TextWrapped = true
status.Text = ""
status.Parent = root

local weaponRow = Instance.new("Frame")
weaponRow.Name = "WeaponSkins"
weaponRow.BackgroundTransparency = 1
weaponRow.Position = UDim2.new(0, 16, 1, -118)
weaponRow.Size = UDim2.new(1, -32, 0, 56)
weaponRow.Parent = root

local lightWeaponBtn = Instance.new("TextButton")
lightWeaponBtn.Size = UDim2.new(0.48, 0, 0, 24)
lightWeaponBtn.Position = UDim2.fromOffset(0, 0)
lightWeaponBtn.Font = Enum.Font.Gotham
lightWeaponBtn.TextSize = 11
lightWeaponBtn.TextXAlignment = Enum.TextXAlignment.Left
lightWeaponBtn.TextColor3 = PALETTE.Pearl
lightWeaponBtn.BackgroundColor3 = Color3.fromRGB(35, 28, 48)
lightWeaponBtn.Text = "Light: —"
lightWeaponBtn.Parent = weaponRow
Instance.new("UICorner", lightWeaponBtn).CornerRadius = UDim.new(0, 6)

local heavyWeaponBtn = Instance.new("TextButton")
heavyWeaponBtn.Size = UDim2.new(0.48, 0, 0, 24)
heavyWeaponBtn.AnchorPoint = Vector2.new(1, 0)
heavyWeaponBtn.Position = UDim2.new(1, 0, 0, 0)
heavyWeaponBtn.Font = Enum.Font.Gotham
heavyWeaponBtn.TextSize = 11
heavyWeaponBtn.TextXAlignment = Enum.TextXAlignment.Left
heavyWeaponBtn.TextColor3 = PALETTE.Pearl
heavyWeaponBtn.BackgroundColor3 = Color3.fromRGB(35, 28, 48)
heavyWeaponBtn.Text = "Heavy: —"
heavyWeaponBtn.Parent = weaponRow
Instance.new("UICorner", heavyWeaponBtn).CornerRadius = UDim.new(0, 6)

local weaponHint = Instance.new("TextLabel")
weaponHint.BackgroundTransparency = 1
weaponHint.Position = UDim2.fromOffset(0, 28)
weaponHint.Size = UDim2.new(1, 0, 0, 24)
weaponHint.Font = Enum.Font.Gotham
weaponHint.TextSize = 10
weaponHint.TextXAlignment = Enum.TextXAlignment.Left
weaponHint.TextColor3 = Color3.fromRGB(160, 160, 180)
weaponHint.TextWrapped = true
weaponHint.Text = "Legendary skins (cosmetic) · pick after adding weapon items"
weaponHint.Parent = weaponRow

local function weaponsForSlot(slot: string): { { id: string, displayName: string } }
	local list = {}
	for _, w in catalogWeapons do
		if w.loadoutSlot == slot then
			table.insert(list, w)
		end
	end
	return list
end

local function refreshWeaponButtons()
	local lightCount = itemCounts.light_weapon or 0
	local heavyCount = itemCounts.heavy_weapon or 0
	lightWeaponBtn.Visible = lightCount > 0 and selectedRole ~= "CombatMedic"
	heavyWeaponBtn.Visible = heavyCount > 0

	if lightCount <= 0 or selectedRole == "CombatMedic" then
		selectedLightWeapon = nil
	end
	if heavyCount <= 0 then
		selectedHeavyWeapon = nil
	end

	local lightName = "—"
	if selectedLightWeapon then
		for _, w in catalogWeapons do
			if w.id == selectedLightWeapon then
				lightName = w.displayName
				break
			end
		end
	end
	local heavyName = "—"
	if selectedHeavyWeapon then
		for _, w in catalogWeapons do
			if w.id == selectedHeavyWeapon then
				heavyName = w.displayName
				break
			end
		end
	end

	lightWeaponBtn.Text = string.format("Light: %s", lightName)
	heavyWeaponBtn.Text = string.format("Heavy: %s", heavyName)
end

local function cycleWeapon(slot: string)
	local options = weaponsForSlot(slot)
	if #options == 0 then
		return
	end
	local current = if slot == "light" then selectedLightWeapon else selectedHeavyWeapon
	local index = 1
	for i, w in options do
		if w.id == current then
			index = (i % #options) + 1
			break
		end
	end
	if slot == "light" then
		selectedLightWeapon = options[index].id
	else
		selectedHeavyWeapon = options[index].id
	end
	refreshWeaponButtons()
end

lightWeaponBtn.MouseButton1Click:Connect(function()
	cycleWeapon("light")
end)
heavyWeaponBtn.MouseButton1Click:Connect(function()
	cycleWeapon("heavy")
end)

local lockBtn = Instance.new("TextButton")
lockBtn.AnchorPoint = Vector2.new(1, 1)
lockBtn.Position = UDim2.new(1, -16, 1, -16)
lockBtn.Size = UDim2.fromOffset(160, 40)
lockBtn.BackgroundColor3 = PALETTE.Amber
lockBtn.Font = Enum.Font.GothamBold
lockBtn.TextSize = 16
lockBtn.TextColor3 = PALETTE.Dark
lockBtn.Text = "Lock Loadout"
lockBtn.Parent = root
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 8)

type CatalogItem = {
	id: string,
	displayName: string,
	weightPerUnit: number,
	maxCount: number,
}

local catalogItems: { CatalogItem } = {}
local catalogRoles: { { id: string, label: string } } = {}
local catalogWeapons: { { id: string, displayName: string, loadoutSlot: string, kind: string } } = {}
local weightCap = 50
local selectedRole = "BossStriker"
local itemCounts: { [string]: number } = {}
local selectedLightWeapon: string? = nil
local selectedHeavyWeapon: string? = nil

local function computeWeight(): number
	local total = 0
	for _, item in catalogItems do
		local c = itemCounts[item.id] or 0
		total += c * item.weightPerUnit
	end
	return total
end

local function refreshWeight()
	weightLabel.Text = string.format("Weight: %d / %d", computeWeight(), weightCap)
end

local function clearItemRows()
	for _, child in itemList:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function makeItemRow(item: CatalogItem, order: number)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -4, 0, 44)
	row.BackgroundColor3 = Color3.fromRGB(30, 24, 40)
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.Parent = itemList
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(10, 4)
	name.Size = UDim2.new(0.55, 0, 1, -8)
	name.Font = Enum.Font.Gotham
	name.TextSize = 13
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextColor3 = PALETTE.Pearl
	name.Text = string.format("%s (wt %d)", item.displayName, item.weightPerUnit)
	name.Parent = row

	local countLabel = Instance.new("TextLabel")
	countLabel.BackgroundTransparency = 1
	countLabel.AnchorPoint = Vector2.new(1, 0.5)
	countLabel.Position = UDim2.new(1, -70, 0.5, 0)
	countLabel.Size = UDim2.fromOffset(36, 24)
	countLabel.Font = Enum.Font.GothamBold
	countLabel.TextSize = 16
	countLabel.TextColor3 = PALETTE.Cyan
	countLabel.Text = tostring(itemCounts[item.id] or 0)
	countLabel.Parent = row

	local minus = Instance.new("TextButton")
	minus.Size = UDim2.fromOffset(28, 28)
	minus.AnchorPoint = Vector2.new(1, 0.5)
	minus.Position = UDim2.new(1, -36, 0.5, 0)
	minus.Text = "-"
	minus.Font = Enum.Font.GothamBold
	minus.TextSize = 18
	minus.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
	minus.Parent = row
	Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 6)

	local plus = Instance.new("TextButton")
	plus.Size = UDim2.fromOffset(28, 28)
	plus.AnchorPoint = Vector2.new(1, 0.5)
	plus.Position = UDim2.new(1, -4, 0.5, 0)
	plus.Text = "+"
	plus.Font = Enum.Font.GothamBold
	plus.TextSize = 18
	plus.BackgroundColor3 = Color3.fromRGB(40, 60, 50)
	plus.Parent = row
	Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 6)

	local function setCount(n: number)
		n = math.clamp(n, 0, item.maxCount)
		itemCounts[item.id] = n
		countLabel.Text = tostring(n)
		refreshWeight()
		refreshWeaponButtons()
	end

	minus.MouseButton1Click:Connect(function()
		setCount((itemCounts[item.id] or 0) - 1)
	end)
	plus.MouseButton1Click:Connect(function()
		setCount((itemCounts[item.id] or 0) + 1)
	end)
end

local function rebuildRoleButtons()
	for _, child in roleRow:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for _, role in catalogRoles do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(120, 32)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.Text = role.label
		btn.Parent = roleRow
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		local active = role.id == selectedRole
		btn.BackgroundColor3 = if active then PALETTE.Cyan else Color3.fromRGB(45, 40, 55)
		btn.TextColor3 = if active then PALETTE.Dark else PALETTE.Pearl
		btn.MouseButton1Click:Connect(function()
			selectedRole = role.id
			rebuildRoleButtons()
			refreshWeaponButtons()
		end)
	end
end

local function openLoadout()
	status.Text = "Loading…"
	root.Visible = true
	local catalog = getCatalog:InvokeServer()
	if not catalog then
		status.Text = "Failed to load catalog"
		return
	end
	catalogItems = catalog.items or {}
	catalogRoles = catalog.roles or {}
	catalogWeapons = catalog.legendaryWeapons or {}
	weightCap = catalog.weightCap or 50
	itemCounts = {}
	selectedLightWeapon = nil
	selectedHeavyWeapon = nil
	clearItemRows()
	rebuildRoleButtons()
	for i, item in catalogItems do
		makeItemRow(item, i)
	end
	itemList.CanvasSize = UDim2.fromOffset(0, #catalogItems * 50)
	refreshWeight()
	refreshWeaponButtons()
	status.Text = "Select role + items + legendary skin · max weight 50"
end

local function closeLoadout()
	root.Visible = false
	status.Text = ""
end

closeBtn.MouseButton1Click:Connect(closeLoadout)

lockBtn.MouseButton1Click:Connect(function()
	status.Text = "Saving…"
	local result = saveLoadout:InvokeServer({
		role = selectedRole,
		items = itemCounts,
		weaponSkins = {
			light = selectedLightWeapon,
			heavy = selectedHeavyWeapon,
		},
	})
	if result and result.ok then
		local skinText = ""
		if result.weaponSkins then
			local parts: { string } = {}
			if result.weaponSkins.light then
				table.insert(parts, result.weaponSkins.light)
			end
			if result.weaponSkins.heavy then
				table.insert(parts, result.weaponSkins.heavy)
			end
			if #parts > 0 then
				skinText = " · " .. table.concat(parts, " + ")
			end
		end
		status.Text = result.message
			.. string.format(" · %s · %d wt · %d dmg/hit%s", result.role, result.weight, result.bossHitDamage or 15, skinText)
		lockBtn.Text = "Locked ✓"
		lockBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
	else
		status.Text = result and result.message or "Save failed"
	end
end)

root:GetPropertyChangedSignal("Visible"):Connect(function()
	if root.Visible then
		root.BackgroundTransparency = 1
		TweenService:Create(root, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
	end
end)

local function bindPrompt(prompt: ProximityPrompt)
	if prompt:GetAttribute("DungeonBound") then
		return
	end
	prompt:SetAttribute("DungeonBound", true)
	prompt.Triggered:Connect(function()
		local action = prompt:GetAttribute("DungeonAction")
		if action == "duo_depth" and prompt.ObjectText:find("Loadout") then
			openLoadout()
		end
	end)
end

local function scanPrompts()
	for _, inst in workspace:GetDescendants() do
		if inst:IsA("ProximityPrompt") and inst.Name == "DungeonPrompt" then
			local parent = inst.Parent
			if parent and parent.Name == "LoadoutKiosk" then
				bindPrompt(inst)
			end
		end
	end
end

workspace.DescendantAdded:Connect(function(inst)
	if inst:IsA("ProximityPrompt") and inst.Name == "DungeonPrompt" then
		task.defer(function()
			local parent = inst.Parent
			if parent and parent.Name == "LoadoutKiosk" then
				bindPrompt(inst)
			end
		end)
	end
end)

task.defer(scanPrompts)

print("[Dungeon] Loadout UI ready")
