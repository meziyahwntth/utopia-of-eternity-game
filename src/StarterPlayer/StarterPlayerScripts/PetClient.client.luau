--!strict
--[[
	PetClient (Backlog B) — collection panel, buff label, equip/unequip HUD
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetConfig"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder
local equipPetRF = remotes:WaitForChild("EquipPet") :: RemoteFunction
local unequipPetRF = remotes:WaitForChild("UnequipPet") :: RemoteFunction
local getColRF = remotes:WaitForChild("GetPetCollection") :: RemoteFunction
local petEquipped = remotes:WaitForChild("PetEquipped") :: RemoteEvent
local petUnequipped = remotes:WaitForChild("PetUnequipped") :: RemoteEvent

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

local function findPetConfig(petId: string): PetConfig.PetEntry?
	for _, entry in PetConfig.Pets do
		if entry.id == petId then
			return entry
		end
	end
	return nil
end

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
