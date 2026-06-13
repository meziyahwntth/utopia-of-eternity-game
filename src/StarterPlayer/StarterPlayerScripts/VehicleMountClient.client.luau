--!strict
-- VehicleMountClient.client.luau
-- UI: Garage Panel — tab Vehicles | Mounts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local CommerceRemotes = ReplicatedStorage:WaitForChild("CommerceRemotes") :: Folder
local getStateRF = CommerceRemotes:WaitForChild("GetVehicleMountState") :: RemoteFunction
local equipVehicleRE = CommerceRemotes:WaitForChild("EquipVehicle") :: RemoteEvent
local equipMountRE = CommerceRemotes:WaitForChild("EquipMount") :: RemoteEvent
local unequipRE = CommerceRemotes:WaitForChild("UnequipVehicleMount") :: RemoteEvent

local VehicleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("VehicleConfig"))
local MountConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MountConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PALETTE = {
	Pearl = Color3.fromRGB(245, 245, 240),
	Gold = Color3.fromRGB(255, 210, 100),
	Dark = Color3.fromRGB(15, 10, 30),
	Row = Color3.fromRGB(25, 20, 40),
	RowEquipped = Color3.fromRGB(60, 50, 10),
	TabInactive = Color3.fromRGB(60, 40, 80),
}

local screen = Instance.new("ScreenGui")
screen.Name = "GarageUI"
screen.ResetOnSpawn = false
screen.Enabled = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local hudBtn = Instance.new("TextButton")
hudBtn.Name = "GarageHUDButton"
hudBtn.Size = UDim2.fromOffset(44, 44)
hudBtn.Position = UDim2.new(0, 12, 0.5, 60)
hudBtn.BackgroundColor3 = PALETTE.Dark
hudBtn.Text = "🚗"
hudBtn.TextSize = 22
hudBtn.Font = Enum.Font.GothamBold
hudBtn.TextColor3 = PALETTE.Gold
hudBtn.Parent = screen
Instance.new("UICorner", hudBtn).CornerRadius = UDim.new(0, 10)

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(560, 420)
frame.Position = UDim2.new(0.5, -280, 0.5, -210)
frame.BackgroundColor3 = PALETTE.Dark
frame.BorderSizePixel = 0
frame.Parent = screen
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundTransparency = 1
title.Text = "🚗  GARAGE"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = PALETTE.Gold
title.Parent = frame

local tabVehicle = Instance.new("TextButton")
tabVehicle.Size = UDim2.new(0.5, -4, 0, 30)
tabVehicle.Position = UDim2.new(0, 4, 0, 38)
tabVehicle.Text = "⚙ Vehicles"
tabVehicle.Font = Enum.Font.GothamSemibold
tabVehicle.TextSize = 14
tabVehicle.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
tabVehicle.TextColor3 = Color3.fromRGB(10, 5, 20)
tabVehicle.Parent = frame

local tabMount = Instance.new("TextButton")
tabMount.Size = UDim2.new(0.5, -4, 0, 30)
tabMount.Position = UDim2.new(0.5, 0, 0, 38)
tabMount.Text = "🐲 Mounts"
tabMount.Font = Enum.Font.GothamSemibold
tabMount.TextSize = 14
tabMount.BackgroundColor3 = PALETTE.TabInactive
tabMount.TextColor3 = Color3.fromRGB(200, 180, 255)
tabMount.Parent = frame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -84)
scroll.Position = UDim2.new(0, 8, 0, 76)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = scroll

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 4)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local currentTab = "vehicle"
local state: any = nil

local refresh: () -> ()

local function makeRow(name: string, subtitle: string, owned: boolean, equipped: boolean, onEquip: () -> ())
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 52)
	row.BackgroundColor3 = if equipped then PALETTE.RowEquipped else PALETTE.Row
	row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.6, 0, 0.55, 0)
	lbl.Position = UDim2.new(0, 10, 0, 4)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.Font = Enum.Font.GothamSemibold
	lbl.TextSize = 13
	lbl.TextColor3 = if equipped then Color3.fromRGB(255, 220, 80) else Color3.fromRGB(220, 220, 255)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(0.6, 0, 0.4, 0)
	sub.Position = UDim2.new(0, 10, 0.55, 0)
	sub.BackgroundTransparency = 1
	sub.Text = subtitle
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 11
	sub.TextColor3 = Color3.fromRGB(150, 140, 180)
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(90, 32)
	btn.Position = UDim2.new(1, -100, 0.5, -16)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	if equipped then
		btn.Text = "✓ ON"
		btn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.MouseButton1Click:Connect(function()
			unequipRE:FireServer()
			task.delay(0.3, refresh)
		end)
	elseif owned then
		btn.Text = "Equip"
		btn.BackgroundColor3 = Color3.fromRGB(80, 60, 160)
		btn.TextColor3 = Color3.fromRGB(220, 210, 255)
		btn.MouseButton1Click:Connect(function()
			onEquip()
			task.delay(0.3, refresh)
		end)
	else
		btn.Text = "🔒 Buy"
		btn.BackgroundColor3 = Color3.fromRGB(50, 40, 70)
		btn.TextColor3 = Color3.fromRGB(160, 140, 200)
	end

	btn.Parent = row
	return row
end

function refresh()
	state = getStateRF:InvokeServer()
	for _, c in scroll:GetChildren() do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end

	if currentTab == "vehicle" then
		for _, def in VehicleConfig.All do
			local owned = state and state.ownedVehicles[def.id] == true
			local equipped = state and state.equippedVehicle == def.id
			local sub = def.vehicleClass .. " · " .. def.seats .. " seats · +" .. def.speedBoost .. " spd"
			local row = makeRow(def.displayName, sub, owned, equipped, function()
				equipVehicleRE:FireServer(def.id)
			end)
			row.Parent = scroll
		end
	else
		for _, def in MountConfig.All do
			local owned = state and state.ownedMounts[def.id] == true
			local equipped = state and state.equippedMount == def.id
			local sub = def.mountType .. " · +" .. def.speedBoost .. " spd · " .. def.rarity
			local row = makeRow(def.displayName, sub, owned, equipped, function()
				equipMountRE:FireServer(def.id)
			end)
			row.Parent = scroll
		end
	end
end

local function toggleGarage()
	screen.Enabled = not screen.Enabled
	if screen.Enabled then
		refresh()
	end
end

tabVehicle.MouseButton1Click:Connect(function()
	currentTab = "vehicle"
	tabVehicle.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	tabMount.BackgroundColor3 = PALETTE.TabInactive
	refresh()
end)

tabMount.MouseButton1Click:Connect(function()
	currentTab = "mount"
	tabMount.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	tabVehicle.BackgroundColor3 = PALETTE.TabInactive
	refresh()
end)

closeBtn.MouseButton1Click:Connect(function()
	screen.Enabled = false
end)

hudBtn.MouseButton1Click:Connect(toggleGarage)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.G then
		toggleGarage()
	end
end)

local openGarage = ReplicatedStorage:WaitForChild("OpenGarage") :: BindableEvent
openGarage.Event:Connect(toggleGarage)

print("[Client] VehicleMountClient ready (G key or 🚗 HUD)")
