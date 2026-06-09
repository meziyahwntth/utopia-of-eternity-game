--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("MountRemotes")
local getRewardCatalog = remotes:WaitForChild("GetRewardCatalog") :: RemoteFunction
local claimMountReward = remotes:WaitForChild("ClaimMountReward") :: RemoteFunction
local mountRewardResult = remotes:WaitForChild("MountRewardResult") :: RemoteEvent

local PALETTE = {
	Pearl = Color3.fromRGB(245, 245, 240),
	Gold = Color3.fromRGB(212, 175, 55),
	Cyan = Color3.fromRGB(0, 229, 255),
	Dark = Color3.fromRGB(18, 22, 32),
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MountRewardUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "RewardRoot"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(480, 360)
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
title.Size = UDim2.new(1, -32, 0, 36)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = PALETTE.Pearl
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Prism Key Reward"
title.Parent = root

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(16, 48)
status.Size = UDim2.new(1, -32, 0, 24)
status.Font = Enum.Font.Gotham
status.TextSize = 13
status.TextColor3 = PALETTE.Cyan
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = ""
status.Parent = root

local list = Instance.new("Frame")
list.Name = "Options"
list.Position = UDim2.fromOffset(16, 84)
list.Size = UDim2.new(1, -32, 1, -100)
list.BackgroundTransparency = 1
list.Parent = root

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local pendingKind: string? = nil

local function clearOptions()
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function addOption(entry: { id: string, displayName: string })
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 15
	btn.TextColor3 = PALETTE.Pearl
	btn.Text = entry.displayName
	btn.Parent = list

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		local kind = pendingKind
		if kind == "mount_choice" then
			kind = "pet"
		end
		local ok, msg = claimMountReward:InvokeServer(entry.id, kind)
		status.Text = if ok then msg else ("Error: " .. msg)
		if ok then
			task.delay(1.2, function()
				root.Visible = false
			end)
		end
	end)
end

local function refresh()
	local catalog = getRewardCatalog:InvokeServer()
	if not catalog.pending then
		root.Visible = false
		return
	end

	clearOptions()
	pendingKind = catalog.type
	title.Text = string.format("Prism Key %d Reward", catalog.pending)
	status.Text = if catalog.type == "weapon_choice"
		then "Choose 1 legendary weapon (cosmetic skin)"
		elseif catalog.type == "vehicle_choice" then "Choose 1 vehicle + unlock Premium Shop"
		else "Choose 1 companion mount"

	for _, entry in catalog.options or {} do
		addOption(entry)
	end

	root.Visible = true
end

player:GetAttributeChangedSignal("PrismKeyMilestonePending"):Connect(refresh)
mountRewardResult.OnClientEvent:Connect(function(ok: boolean, msg: string)
	status.Text = if ok then msg else ("Error: " .. msg)
end)
task.defer(refresh)
