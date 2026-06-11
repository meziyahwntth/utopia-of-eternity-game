--!strict
--[[
	Combat HUD — กด F (หรือปุ่ม touch บนมือถือ) strike wraith ใกล้สุด
	แสดงผลการโจมตี + toast เมื่อ wraith ถูกฆ่า (+shards)
	แผงโผล่เฉพาะตอน wave มี wraith (จาก SurvivalStateChanged)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local attackWraith = remotes:WaitForChild("AttackWraith") :: RemoteFunction
local wraithKilled = remotes:WaitForChild("WraithKilled") :: RemoteEvent
local stateChanged = remotes:WaitForChild("SurvivalStateChanged") :: RemoteEvent

local hud = Instance.new("ScreenGui")
hud.Name = "DeathValleyCombatHUD"
hud.ResetOnSpawn = false
hud.Parent = playerGui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -160)
panel.Size = UDim2.fromOffset(300, 56)
panel.BackgroundColor3 = Color3.fromRGB(28, 12, 16)
panel.BackgroundTransparency = 0.15
panel.Visible = false
panel.Parent = hud
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -12, 0, 20)
title.Position = UDim2.fromOffset(8, 4)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(255, 110, 110)
title.Text = "Wraith Wave — Press F to Strike"
title.Parent = panel

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Size = UDim2.new(1, -12, 0, 26)
status.Position = UDim2.fromOffset(8, 24)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextColor3 = Color3.new(1, 1, 1)
status.Text = ""
status.Parent = panel

local waveActive = false
local attackBusy = false

local function strike()
	if not waveActive or attackBusy then
		return
	end
	attackBusy = true
	task.spawn(function()
		local ok, success, text = pcall(function()
			return attackWraith:InvokeServer()
		end)
		attackBusy = false
		if ok and typeof(text) == "string" and text ~= "" then
			status.Text = text
		elseif ok and success == false then
			-- เงียบช่วง cooldown (text ว่าง)
		elseif not ok then
			status.Text = "..."
		end
	end)
end

local strikeBound = false

local function setStrikeBound(bound: boolean)
	if bound == strikeBound then
		return
	end
	strikeBound = bound
	if bound then
		ContextActionService:BindAction("DVStrike", function(_name, inputState, _input)
			if inputState == Enum.UserInputState.Begin then
				strike()
			end
			return Enum.ContextActionResult.Sink
		end, true, Enum.KeyCode.F)
		ContextActionService:SetTitle("DVStrike", "Strike")
	else
		ContextActionService:UnbindAction("DVStrike")
	end
end

stateChanged.OnClientEvent:Connect(function(state)
	if typeof(state) ~= "table" then
		return
	end
	local isWave = state.phase == "wave"
	local count = if typeof(state.activeWraiths) == "number" then state.activeWraiths else 0
	waveActive = isWave and count > 0
	panel.Visible = waveActive
	setStrikeBound(waveActive)
	if waveActive then
		title.Text = string.format("Wraith Wave (%d) — Press F to Strike", count)
	end
end)

wraithKilled.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end
	local count = if typeof(payload.activeWraiths) == "number" then payload.activeWraiths else 0
	title.Text = string.format("Wraith Wave (%d) — Press F to Strike", count)
	if payload.killerUserId == player.UserId then
		status.Text = string.format("Wraith destroyed! +%d shards", payload.shardReward or 0)
	elseif typeof(payload.killerName) == "string" then
		status.Text = string.format("%s destroyed a wraith", payload.killerName)
	end
end)

print("[DeathValley] Combat HUD ready — F to strike")
