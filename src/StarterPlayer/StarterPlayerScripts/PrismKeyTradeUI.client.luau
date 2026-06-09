--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PrismKeyRandomPools = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismKeyRandomPools"))

local remotes = ReplicatedStorage:WaitForChild("PrismKeyRemotes")
local getOwnedKeys = remotes:WaitForChild("GetOwnedKeys") :: RemoteFunction
local executeKeyTrade = remotes:WaitForChild("ExecuteKeyTrade") :: RemoteFunction
local tradeSessionStarted = remotes:WaitForChild("TradeSessionStarted") :: RemoteEvent
local tradeSessionEnded = remotes:WaitForChild("TradeSessionEnded") :: RemoteEvent
local ghostComplaint = remotes:WaitForChild("GhostComplaint") :: RemoteEvent

local PALETTE = {
	Pearl = Color3.fromRGB(245, 245, 240),
	Gold = Color3.fromRGB(212, 175, 55),
	Purple = Color3.fromRGB(180, 140, 255),
	Dark = Color3.fromRGB(18, 12, 28),
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PrismKeyTradeUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "TradeRoot"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(500, 420)
root.BackgroundColor3 = PALETTE.Dark
root.BorderSizePixel = 0
root.Visible = false
root.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = root

local stroke = Instance.new("UIStroke")
stroke.Color = PALETTE.Purple
stroke.Thickness = 2
stroke.Parent = root

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(16, 12)
title.Size = UDim2.new(1, -32, 0, 28)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = PALETTE.Pearl
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "วิญญาณแลกกุญแจ — 3 ดอก → 1 หมายเลข"
title.Parent = root

local timerLbl = Instance.new("TextLabel")
timerLbl.BackgroundTransparency = 1
timerLbl.Position = UDim2.fromOffset(16, 42)
timerLbl.Size = UDim2.new(1, -32, 0, 20)
timerLbl.Font = Enum.Font.GothamBold
timerLbl.TextSize = 14
timerLbl.TextColor3 = PALETTE.Gold
timerLbl.TextXAlignment = Enum.TextXAlignment.Left
timerLbl.Text = ""
timerLbl.Parent = root

local statusLbl = Instance.new("TextLabel")
statusLbl.BackgroundTransparency = 1
statusLbl.Position = UDim2.fromOffset(16, 64)
statusLbl.Size = UDim2.new(1, -32, 0, 36)
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 13
statusLbl.TextColor3 = PALETTE.Purple
statusLbl.TextWrapped = true
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Text = "เลือกกุญแจ 3 ดอกที่จะสละ และใส่หมายเลขที่ต้องการ"
statusLbl.Parent = root

local ownedList = Instance.new("ScrollingFrame")
ownedList.Name = "OwnedKeys"
ownedList.Position = UDim2.fromOffset(16, 108)
ownedList.Size = UDim2.new(0.55, -8, 1, -180)
ownedList.BackgroundTransparency = 1
ownedList.BorderSizePixel = 0
ownedList.ScrollBarThickness = 4
ownedList.CanvasSize = UDim2.new()
ownedList.Parent = root

local ownedLayout = Instance.new("UIListLayout")
ownedLayout.Padding = UDim.new(0, 4)
ownedLayout.Parent = ownedList

local targetBox = Instance.new("TextBox")
targetBox.Name = "TargetKey"
targetBox.Position = UDim2.new(0.58, 0, 0, 108)
targetBox.Size = UDim2.new(0.4, -16, 0, 36)
targetBox.BackgroundColor3 = Color3.fromRGB(35, 25, 50)
targetBox.Font = Enum.Font.Gotham
targetBox.TextSize = 16
targetBox.PlaceholderText = "หมายเลข 1–99"
targetBox.Text = ""
targetBox.TextColor3 = PALETTE.Pearl
targetBox.Parent = root

local tradeBtn = Instance.new("TextButton")
tradeBtn.Position = UDim2.new(0.58, 0, 0, 156)
tradeBtn.Size = UDim2.new(0.4, -16, 0, 40)
tradeBtn.BackgroundColor3 = PALETTE.Gold
tradeBtn.Font = Enum.Font.GothamBold
tradeBtn.TextSize = 15
tradeBtn.TextColor3 = PALETTE.Dark
tradeBtn.Text = "แลกกุญแจ"
tradeBtn.Parent = root

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -12, 0, 12)
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.BackgroundColor3 = PALETTE.Purple
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "X"
closeBtn.TextColor3 = PALETTE.Dark
closeBtn.Parent = root

local selectedKeys: { [number]: boolean } = {}
local sessionDeadline: number? = nil

local function clearOwnedList()
	for _, child in ownedList:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function refreshOwned(keys: { number })
	clearOwnedList()
	selectedKeys = {}
	table.sort(keys)
	for _, keyNum in keys do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -4, 0, 32)
		btn.BackgroundColor3 = Color3.fromRGB(40, 30, 55)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		btn.TextColor3 = PALETTE.Pearl
		btn.Text = string.format("#%d", keyNum)
		btn.Parent = ownedList
		btn.MouseButton1Click:Connect(function()
			if selectedKeys[keyNum] then
				selectedKeys[keyNum] = nil
				btn.BackgroundColor3 = Color3.fromRGB(40, 30, 55)
			else
				local count = 0
				for _ in selectedKeys do
					count += 1
				end
				if count >= PrismKeyRandomPools.TradeCost then
					statusLbl.Text = string.format("เลือกได้สูงสุด %d ดอก", PrismKeyRandomPools.TradeCost)
					return
				end
				selectedKeys[keyNum] = true
				btn.BackgroundColor3 = PALETTE.Purple
			end
		end)
	end
	ownedLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ownedList.CanvasSize = UDim2.fromOffset(0, ownedLayout.AbsoluteContentSize.Y + 4)
	end)
	ownedList.CanvasSize = UDim2.fromOffset(0, ownedLayout.AbsoluteContentSize.Y + 4)
end

local function closeUi()
	root.Visible = false
	sessionDeadline = nil
	selectedKeys = {}
end

closeBtn.MouseButton1Click:Connect(closeUi)

tradeBtn.MouseButton1Click:Connect(function()
	local target = tonumber(targetBox.Text)
	if not target then
		statusLbl.Text = "ใส่หมายเลขกุญแจที่ต้องการ"
		return
	end
	local sacrifice: { number } = {}
	for keyNum in selectedKeys do
		table.insert(sacrifice, keyNum)
	end
	if #sacrifice ~= PrismKeyRandomPools.TradeCost then
		statusLbl.Text = string.format("เลือกกุญแจ %d ดอกก่อน", PrismKeyRandomPools.TradeCost)
		return
	end
	local ok, msg = executeKeyTrade:InvokeServer(sacrifice, target)
	statusLbl.Text = if ok then msg else ("Error: " .. msg)
	if ok then
		task.delay(1.5, closeUi)
	end
end)

task.spawn(function()
	while true do
		if root.Visible and sessionDeadline then
			local left = math.max(0, sessionDeadline - os.clock())
			timerLbl.Text = string.format("เหลือเวลา %.0f วินาที — ไม่เสร็จ NPC จะล่องลอยไป", left)
			if left <= 0 then
				statusLbl.Text = PrismKeyRandomPools.GhostNpc.ComplaintText
				task.delay(2, closeUi)
			end
		end
		task.wait(0.25)
	end
end)

tradeSessionStarted.OnClientEvent:Connect(function(payload)
	sessionDeadline = payload.deadline
	if payload.ownedKeys then
		refreshOwned(payload.ownedKeys)
	else
		local catalog = getOwnedKeys:InvokeServer()
		if catalog.ok then
			refreshOwned(catalog.keys)
		end
	end
	root.Visible = true
	statusLbl.Text = string.format(
		"Zone %d · สละ %d ดอกใดก็ได้ → รับหมายเลขที่เลือก 1 ดอก",
		payload.zoneIndex or 0,
		PrismKeyRandomPools.TradeCost
	)
end)

tradeSessionEnded.OnClientEvent:Connect(function(payload)
	if payload.reason == "timeout" then
		statusLbl.Text = PrismKeyRandomPools.GhostNpc.ComplaintText
		task.delay(2, closeUi)
	elseif payload.reason == "complete" then
		closeUi()
	end
end)

ghostComplaint.OnClientEvent:Connect(function(text: string)
	statusLbl.Text = text
end)
