--!strict
--[[
	DropNotifClient — bottom-right stack notifications for item drops
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

type DropResult = {
	dropType: string?,
	itemId: string,
	qty: number,
	petId: string?,
}

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("SocialRemotes") :: Folder

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DropNotif"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 7
screenGui.Parent = playerGui

local container = Instance.new("Frame")
container.Size = UDim2.fromScale(0.2, 0.35)
container.Position = UDim2.fromScale(0.79, 0.62)
container.BackgroundTransparency = 1
container.Parent = screenGui

local listLayout = Instance.new("UIListLayout")
listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
listLayout.Padding = UDim.new(0, 3)
listLayout.Parent = container

local MAX_NOTIFS = 5
local activeNotifs: { Frame } = {}

local itemColors: { [string]: Color3 } = {
	StoneFragment = Color3.fromRGB(160, 140, 100),
	IronOre = Color3.fromRGB(140, 160, 180),
	MagicCrystal = Color3.fromRGB(140, 80, 220),
}

local itemIcons: { [string]: string } = {
	StoneFragment = "🪨",
	IronOre = "⛏",
	MagicCrystal = "💎",
}

local function removeNotif(row: Frame)
	local idx = table.find(activeNotifs, row)
	if idx then
		table.remove(activeNotifs, idx)
	end
	if row.Parent then
		row:Destroy()
	end
end

local function spawnNotif(text: string, color: Color3)
	while #activeNotifs >= MAX_NOTIFS do
		local oldest = table.remove(activeNotifs, 1)
		if oldest and oldest.Parent then
			oldest:Destroy()
		end
	end

	local row = Instance.new("Frame")
	row.Size = UDim2.fromScale(1, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	row.BackgroundTransparency = 0.2
	row.BorderSizePixel = 0
	row.Parent = container

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0.15, 0)
	rowCorner.Parent = row

	table.insert(activeNotifs, row)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = color
	lbl.TextScaled = false
	lbl.TextSize = 13
	lbl.Font = Enum.Font.GothamBold
	lbl.Text = text
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local lblPadding = Instance.new("UIPadding")
	lblPadding.PaddingLeft = UDim.new(0.05, 0)
	lblPadding.Parent = lbl

	task.delay(3, function()
		if not row.Parent then
			return
		end
		TweenService:Create(row, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(lbl, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		task.wait(0.55)
		removeNotif(row)
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
		for _, drop in drops :: { DropResult } do
			if drop.dropType == "pet" then
				continue
			else
				local icon = itemIcons[drop.itemId] or "📦"
				local color = itemColors[drop.itemId] or Color3.fromRGB(200, 200, 200)
				spawnNotif(string.format("%s +%d %s", icon, drop.qty, drop.itemId), color)
			end
		end
	end)
end)
