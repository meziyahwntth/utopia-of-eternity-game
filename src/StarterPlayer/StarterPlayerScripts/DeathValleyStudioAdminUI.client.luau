--!strict
--[[
	Phase I/J — Studio-only admin panel for season rollover testing (F9).
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

if not RunService:IsStudio() then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local adminForceRollover = remotes:WaitForChild("AdminForceSeasonRollover") :: RemoteFunction
local adminDeliverRewards = remotes:WaitForChild("AdminDeliverRolloverRewards") :: RemoteFunction
local adminResetPointer = remotes:WaitForChild("AdminResetSeasonPointer") :: RemoteFunction
local getStudioAdminStatus = remotes:WaitForChild("GetStudioAdminStatus") :: RemoteFunction

local gui = Instance.new("ScreenGui")
gui.Name = "DeathValleyStudioAdminUI"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -12, 0, 12)
panel.Size = UDim2.fromOffset(280, 268)
panel.BackgroundColor3 = Color3.fromRGB(20, 14, 28)
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -12, 0, 24)
title.Position = UDim2.fromOffset(8, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(255, 120, 120)
title.Text = "Studio · Season Admin"
title.Parent = panel

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -12, 0, 48)
status.Position = UDim2.fromOffset(8, 34)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.TextWrapped = true
status.TextColor3 = Color3.fromRGB(200, 190, 220)
status.Text = "Loading..."
status.Parent = panel

local function makeBtn(text: string, y: number, color: Color3): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -16, 0, 32)
	btn.Position = UDim2.fromOffset(8, y)
	btn.BackgroundColor3 = color
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Text = text
	btn.Parent = panel
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	return btn
end

local rolloverBtn = makeBtn("Force Season Rollover", 88, Color3.fromRGB(120, 60, 60))
local deliverBtn = makeBtn("Deliver My Auto Rewards", 124, Color3.fromRGB(60, 90, 120))
local resetBtn = makeBtn("Reset Season Pointer", 160, Color3.fromRGB(90, 70, 50))
local closeBtn = makeBtn("Close (F9)", 196, Color3.fromRGB(50, 50, 60))

local function refreshStatus()
	local data = getStudioAdminStatus:InvokeServer()
	if typeof(data) ~= "table" then
		status.Text = "Admin status unavailable"
		return
	end
	local rollover = data.rollover
	if typeof(rollover) == "table" then
		status.Text = string.format(
			"Current: %s\nStored: %s · Top %s auto",
			tostring(rollover.activeSeasonId or "?"),
			tostring(rollover.storedSeasonId or "?"),
			tostring(rollover.topAutoCount or 25)
		)
	else
		status.Text = tostring(data.currentSeasonId or "")
	end
end

local function setVisible(visible: boolean)
	gui.Enabled = visible
	if visible then
		refreshStatus()
	end
end

rolloverBtn.MouseButton1Click:Connect(function()
	local ok, msg = adminForceRollover:InvokeServer()
	status.Text = msg
	if ok then
		refreshStatus()
	end
end)

deliverBtn.MouseButton1Click:Connect(function()
	local ok, msg = adminDeliverRewards:InvokeServer()
	status.Text = msg
	if ok then
		refreshStatus()
	end
end)

resetBtn.MouseButton1Click:Connect(function()
	local ok, msg = adminResetPointer:InvokeServer()
	status.Text = msg
	if ok then
		refreshStatus()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	setVisible(false)
end)

ContextActionService:BindAction("ToggleDVStudioAdmin", function(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	setVisible(not gui.Enabled)
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.F9)

print("[DeathValley] Studio admin UI ready (F9)")
