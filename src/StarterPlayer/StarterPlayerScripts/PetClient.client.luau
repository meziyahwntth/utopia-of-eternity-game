--!strict
--[[
	PetClient (Backlog B) — collection panel, buff label, equip/unequip HUD, pet drop notifications
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PetConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetConfig"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local equipPetRF = remotes:WaitForChild("EquipPet") :: RemoteFunction
local unequipPetRF = remotes:WaitForChild("UnequipPet") :: RemoteFunction
local getColRF = remotes:WaitForChild("GetPetCollection") :: RemoteFunction
local petEquipped = remotes:WaitForChild("PetEquipped") :: RemoteEvent
local petUnequipped = remotes:WaitForChild("PetUnequipped") :: RemoteEvent

local rarityColor: { [PetConfig.PetRarity]: Color3 } = {
	Common = Color3.fromRGB(180, 180, 200),
	Rare = Color3.fromRGB(80, 160, 255),
	Epic = Color3.fromRGB(160, 80, 255),
	Legendary = Color3.fromRGB(255, 180, 50),
}

local petNotifGui = Instance.new("ScreenGui")
petNotifGui.Name = "PetDropNotif"
petNotifGui.ResetOnSpawn = false
petNotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
petNotifGui.DisplayOrder = 8
petNotifGui.Parent = playerGui

local petNotifContainer = Instance.new("Frame")
petNotifContainer.Size = UDim2.fromScale(0.22, 0.25)
petNotifContainer.Position = UDim2.fromScale(0.77, 0.62)
petNotifContainer.BackgroundTransparency = 1
petNotifContainer.Parent = petNotifGui

local petNotifLayout = Instance.new("UIListLayout")
petNotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
petNotifLayout.Padding = UDim.new(0, 3)
petNotifLayout.Parent = petNotifContainer

local MAX_PET_NOTIFS = 4
local activePetNotifs: { Frame } = {}

local function findPetConfig(petId: string): PetConfig.PetEntry?
	for _, entry in PetConfig.Pets do
		if entry.id == petId then
			return entry
		end
	end
	return nil
end

local function showPetNotif(petId: string)
	local cfg = findPetConfig(petId)
	local color = if cfg then rarityColor[cfg.rarity] else rarityColor.Common
	local label = if cfg then cfg.icon .. " " .. cfg.nameTH else ("🐾 " .. petId)

	while #activePetNotifs >= MAX_PET_NOTIFS do
		local oldest = table.remove(activePetNotifs, 1)
		if oldest and oldest.Parent then
			oldest:Destroy()
		end
	end

	local row = Instance.new("Frame")
	row.Size = UDim2.fromScale(1, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	row.BackgroundTransparency = 0.15
	row.BorderSizePixel = 0
	row.Parent = petNotifContainer
	Instance.new("UICorner", row).CornerRadius = UDim.new(0.12, 0)
	table.insert(activePetNotifs, row)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = color
	lbl.TextSize = 13
	lbl.Font = Enum.Font.GothamBold
	lbl.Text = "ได้รับสัตว์เลี้ยง: " .. label
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextWrapped = true
	lbl.Parent = row
	Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0.04, 0)

	task.delay(3.5, function()
		if not row.Parent then
			return
		end
		TweenService:Create(row, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(lbl, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		task.wait(0.55)
		local idx = table.find(activePetNotifs, row)
		if idx then
			table.remove(activePetNotifs, idx)
		end
		row:Destroy()
	end)
end

task.spawn(function()
	local itemDroppedEv = remotes:WaitForChild("ItemDropped", 10) :: RemoteEvent?
	if not itemDroppedEv then
		return
	end
	itemDroppedEv.OnClientEvent:Connect(function(drops)
		if typeof(drops) ~= "table" then
			return
		end
		for _, drop in drops :: { { dropType: string?, petId: string?, itemId: string } } do
			if drop.dropType == "pet" then
				showPetNotif(drop.petId or drop.itemId)
			end
		end
	end)
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 5
screenGui.Parent = playerGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromScale(0.07, 0.05)
toggleBtn.Position = UDim2.fromScale(0.465, 0.88)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.TextScaled = true
toggleBtn.Text = "🐾"
toggleBtn.Parent = screenGui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromScale(0.45, 0.35)
panel.Position = UDim2.fromScale(0.275, 0.52)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
panel.BackgroundTransparency = 0.1
panel.Visible = false
panel.Parent = screenGui

local panelLayout = Instance.new("UIGridLayout")
panelLayout.CellSize = UDim2.fromScale(0.18, 0.45)
panelLayout.CellPadding = UDim2.fromScale(0.02, 0.05)
panelLayout.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromScale(0.1, 0.15)
closeBtn.Position = UDim2.fromScale(0.89, 0.02)
closeBtn.Text = "✕"
closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.ZIndex = 2
closeBtn.Parent = panel

closeBtn.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

local buffLabel = Instance.new("TextLabel")
buffLabel.Size = UDim2.fromScale(0.2, 0.04)
buffLabel.Position = UDim2.fromScale(0.4, 0.84)
buffLabel.BackgroundTransparency = 1
buffLabel.TextColor3 = Color3.fromRGB(255, 230, 100)
buffLabel.TextScaled = true
buffLabel.Text = ""
buffLabel.Parent = screenGui

local activePetId: string? = nil

local function refreshPanel()
	for _, child in panel:GetChildren() do
		if child:IsA("TextButton") and child ~= closeBtn then
			child:Destroy()
		end
	end

	local ok, owned = pcall(function()
		return getColRF:InvokeServer()
	end)
	if not ok or typeof(owned) ~= "table" then
		return
	end

	for _, petId in owned :: { string } do
		local cfg = findPetConfig(petId)
		if not cfg then
			continue
		end

		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = if activePetId == petId
			then Color3.fromRGB(80, 160, 80)
			else Color3.fromRGB(50, 50, 80)
		btn.TextScaled = true
		btn.Text = cfg.icon .. "\n" .. cfg.nameTH
		btn.Parent = panel

		btn.MouseButton1Click:Connect(function()
			if activePetId == petId then
				pcall(function()
					unequipPetRF:InvokeServer()
				end)
			else
				pcall(function()
					equipPetRF:InvokeServer(petId)
				end)
			end
			panel.Visible = false
		end)
	end
end

toggleBtn.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		refreshPanel()
	end
end)

petEquipped.OnClientEvent:Connect(function(petId, expBonus, _pickupRadius, luckBonus)
	activePetId = petId :: string
	buffLabel.Text = string.format(
		"🐾 EXP+%d%% Drop+%d%%",
		math.floor((expBonus :: number) * 100),
		math.floor((luckBonus :: number) * 100)
	)
end)

petUnequipped.OnClientEvent:Connect(function()
	activePetId = nil
	buffLabel.Text = ""
end)
