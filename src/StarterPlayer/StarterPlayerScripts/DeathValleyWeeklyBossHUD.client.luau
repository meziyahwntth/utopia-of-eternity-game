--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local attackWeeklyBoss = remotes:WaitForChild("AttackWeeklyBoss") :: RemoteFunction
local weeklyStateChanged = remotes:WaitForChild("WeeklyBossStateChanged") :: RemoteEvent

local hud = Instance.new("ScreenGui")
hud.Name = "DeathValleyWeeklyBossHUD"
hud.ResetOnSpawn = false
hud.Parent = playerGui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -80)
panel.Size = UDim2.fromOffset(320, 72)
panel.BackgroundColor3 = Color3.fromRGB(18, 10, 28)
panel.BackgroundTransparency = 0.12
panel.Visible = false
panel.Parent = hud
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -12, 0, 22)
title.Position = UDim2.fromOffset(8, 6)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(255, 179, 71)
title.Text = "Weekly Boss"
title.Parent = panel

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Size = UDim2.new(1, -12, 0, 36)
status.Position = UDim2.fromOffset(8, 28)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextColor3 = Color3.new(1, 1, 1)
status.Text = ""
status.Parent = panel

local bossActive = false

local function applyState(state: any)
	if typeof(state) ~= "table" then
		return
	end
	if state.bossActive then
		panel.Visible = true
		bossActive = true
		title.Text = string.format("Weekly · %s", state.bossName or "Boss")
		status.Text = string.format("HP %d / %d · Week %s · Press G", state.bossHp or 0, state.bossMaxHp or 1, state.weekId or "")
	elseif state.canAccess == false then
		panel.Visible = true
		bossActive = false
		title.Text = "Weekly Boss Locked"
		status.Text = string.format("Survive %d nights (Ring %d)", 20, state.minRing or 3)
	else
		panel.Visible = false
		bossActive = false
	end
end

weeklyStateChanged.OnClientEvent:Connect(applyState)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not bossActive or input.KeyCode ~= Enum.KeyCode.G then
		return
	end
	local ok, msg = attackWeeklyBoss:InvokeServer()
	status.Text = msg or (if ok then "Strike!" else "Failed")
end)

print("[DeathValley] Weekly boss HUD ready")
