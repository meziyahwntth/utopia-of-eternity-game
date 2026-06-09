--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PlaceTeleport = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlaceTeleport"))

local function isDeathValleyPlace(): boolean
	if game.PlaceId == 0 then
		local sim = GameConfig.StudioDev and GameConfig.StudioDev.SimulatePlaceKey
		return sim == "DeathValley"
	end
	local deathValleyId = PlaceTeleport:GetPlaceId("DeathValley")
	return deathValleyId ~= nil and deathValleyId > 0 and game.PlaceId == deathValleyId
end

if not isDeathValleyPlace() then
	return
end

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local getSurvivalState = remotes:WaitForChild("GetSurvivalState") :: RemoteFunction
local depositFuel = remotes:WaitForChild("DepositBeaconFuel") :: RemoteFunction
local startRevive = remotes:WaitForChild("StartReviveChannel") :: RemoteFunction
local completeRevive = remotes:WaitForChild("CompleteReviveChannel") :: RemoteFunction
local stateChanged = remotes:WaitForChild("SurvivalStateChanged") :: RemoteEvent
local playerDowned = remotes:WaitForChild("PlayerDowned") :: RemoteEvent
local nightSurvived = remotes:WaitForChild("NightSurvived") :: RemoteEvent
local wraithAlert = remotes:WaitForChild("WraithAlert") :: RemoteEvent
local ringUnlocked = remotes:WaitForChild("HorizonRingUnlocked") :: RemoteEvent
local poiClue = remotes:WaitForChild("PoiClueDiscovered") :: RemoteEvent

local PALETTE = {
	Amber = Color3.fromRGB(255, 179, 71),
	Cyan = Color3.fromRGB(0, 229, 255),
	Dark = Color3.fromRGB(14, 10, 22),
	Pearl = Color3.fromRGB(240, 235, 255),
}

local hud = Instance.new("ScreenGui")
hud.Name = "DeathValleySurvivalHUD"
hud.ResetOnSpawn = false
hud.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "SurvivalPanel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -12, 0, 12)
panel.Size = UDim2.fromOffset(280, 210)
panel.BackgroundColor3 = PALETTE.Dark
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.Parent = hud
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -16, 0, 24)
title.Position = UDim2.fromOffset(10, 8)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = PALETTE.Amber
title.Text = "หุบเขามรณะ — Night Run"
title.Parent = panel

local phaseLbl = Instance.new("TextLabel")
phaseLbl.BackgroundTransparency = 1
phaseLbl.Size = UDim2.new(1, -16, 0, 18)
phaseLbl.Position = UDim2.fromOffset(10, 34)
phaseLbl.Font = Enum.Font.Gotham
phaseLbl.TextSize = 13
phaseLbl.TextXAlignment = Enum.TextXAlignment.Left
phaseLbl.TextColor3 = PALETTE.Cyan
phaseLbl.Text = "Phase: Prep"
phaseLbl.Parent = panel

local nightsLbl = Instance.new("TextLabel")
nightsLbl.BackgroundTransparency = 1
nightsLbl.Size = UDim2.new(1, -16, 0, 18)
nightsLbl.Position = UDim2.fromOffset(10, 54)
nightsLbl.Font = Enum.Font.GothamBold
nightsLbl.TextSize = 14
nightsLbl.TextXAlignment = Enum.TextXAlignment.Left
nightsLbl.TextColor3 = PALETTE.Pearl
nightsLbl.Text = "Nights Survived: 0"
nightsLbl.Parent = panel

local fuelBg = Instance.new("Frame")
fuelBg.Size = UDim2.new(1, -20, 0, 12)
fuelBg.Position = UDim2.fromOffset(10, 80)
fuelBg.BackgroundColor3 = Color3.fromRGB(40, 30, 55)
fuelBg.BorderSizePixel = 0
fuelBg.Parent = panel
Instance.new("UICorner", fuelBg).CornerRadius = UDim.new(0, 4)

local fuelFill = Instance.new("Frame")
fuelFill.Size = UDim2.fromScale(0.5, 1)
fuelFill.BackgroundColor3 = PALETTE.Amber
fuelFill.BorderSizePixel = 0
fuelFill.Parent = fuelBg
Instance.new("UICorner", fuelFill).CornerRadius = UDim.new(0, 4)

local fuelLbl = Instance.new("TextLabel")
fuelLbl.BackgroundTransparency = 1
fuelLbl.Size = UDim2.new(1, -16, 0, 16)
fuelLbl.Position = UDim2.fromOffset(10, 96)
fuelLbl.Font = Enum.Font.Gotham
fuelLbl.TextSize = 12
fuelLbl.TextXAlignment = Enum.TextXAlignment.Left
fuelLbl.TextColor3 = PALETTE.Pearl
fuelLbl.Text = "Beacon Lv1 · Fuel 50/100"
fuelLbl.Parent = panel

local modifierLbl = Instance.new("TextLabel")
modifierLbl.BackgroundTransparency = 1
modifierLbl.Size = UDim2.new(1, -16, 0, 16)
modifierLbl.Position = UDim2.fromOffset(10, 116)
modifierLbl.Font = Enum.Font.Gotham
modifierLbl.TextSize = 11
modifierLbl.TextXAlignment = Enum.TextXAlignment.Left
modifierLbl.TextColor3 = Color3.fromRGB(180, 220, 255)
modifierLbl.Text = "Modifier: Calm Night"
modifierLbl.Parent = panel

local ringLbl = Instance.new("TextLabel")
ringLbl.BackgroundTransparency = 1
ringLbl.Size = UDim2.new(1, -16, 0, 16)
ringLbl.Position = UDim2.fromOffset(10, 136)
ringLbl.Font = Enum.Font.Gotham
ringLbl.TextSize = 11
ringLbl.TextXAlignment = Enum.TextXAlignment.Left
ringLbl.TextColor3 = Color3.fromRGB(200, 180, 255)
ringLbl.Text = "Horizon: Sanctuary Core"
ringLbl.Parent = panel

local alertLbl = Instance.new("TextLabel")
alertLbl.BackgroundTransparency = 1
alertLbl.Size = UDim2.new(1, -16, 0, 36)
alertLbl.Position = UDim2.fromOffset(10, 160)
alertLbl.Font = Enum.Font.Gotham
alertLbl.TextSize = 12
alertLbl.TextWrapped = true
alertLbl.TextXAlignment = Enum.TextXAlignment.Left
alertLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
alertLbl.Text = ""
alertLbl.Parent = panel

local reviveBtn = Instance.new("TextButton")
reviveBtn.Size = UDim2.fromOffset(120, 32)
reviveBtn.Position = UDim2.new(0.5, -60, 1, 24)
reviveBtn.BackgroundColor3 = PALETTE.Cyan
reviveBtn.Font = Enum.Font.GothamBold
reviveBtn.TextSize = 13
reviveBtn.TextColor3 = PALETTE.Dark
reviveBtn.Text = "Revive Ally [R]"
reviveBtn.Visible = false
reviveBtn.Parent = panel

local downedTargetId: number? = nil
local reviveChannelEnds: number? = nil

local function applyState(state: any)
	if typeof(state) ~= "table" then
		return
	end
	local phase = tostring(state.phase or "prep")
	local left = math.max(0, (state.phaseEndsAt or 0) - os.clock())
	phaseLbl.Text = string.format("Phase: %s · %.0fs", string.upper(phase), left)
	nightsLbl.Text = string.format("Nights Survived: %d · Night %d", state.nightsSurvived or 0, state.currentNight or 1)
	local beacon = state.beacon
	if typeof(beacon) == "table" then
		local fuel = beacon.fuel or 0
		local maxFuel = beacon.maxFuel or 100
		fuelFill.Size = UDim2.fromScale(math.clamp(fuel / maxFuel, 0, 1), 1)
		fuelLbl.Text = string.format("Beacon Lv%d · Fuel %.0f/%.0f · R%.0f stud", beacon.level or 1, fuel, maxFuel, beacon.radiusStuds or 60)
	end
	local modifier = state.nightModifier
	if typeof(modifier) == "table" then
		modifierLbl.Text = string.format("Modifier: %s", modifier.displayName or "Calm Night")
	end
	local expansion = state.expansion
	if typeof(expansion) == "table" then
		ringLbl.Text = string.format(
			"Horizon: %s · next ring @ %d nights",
			expansion.displayName or "Sanctuary Core",
			expansion.nextRingNights or 5
		)
	end
	if state.checkpoint then
		ringLbl.Text ..= " · Checkpoint active"
	end
end

stateChanged.OnClientEvent:Connect(applyState)
nightSurvived.OnClientEvent:Connect(function(payload)
	local checkpointNote = if payload.checkpointSaved then " · Checkpoint saved" else ""
	alertLbl.Text = string.format(
		"Night %d cleared! Total survived: %d%s",
		payload.night or 0,
		payload.nightsSurvived or 0,
		checkpointNote
	)
	task.delay(4, function()
		alertLbl.Text = ""
	end)
end)
ringUnlocked.OnClientEvent:Connect(function(payload)
	alertLbl.Text = string.format("Horizon unlocked: %s", payload.displayName or ("Ring " .. tostring(payload.ring)))
	task.delay(5, function()
		alertLbl.Text = ""
	end)
end)
poiClue.OnClientEvent:Connect(function(payload)
	if typeof(payload.clueText) == "string" then
		alertLbl.Text = payload.clueText
	end
end)
wraithAlert.OnClientEvent:Connect(function(payload)
	if typeof(payload.message) == "string" then
		alertLbl.Text = payload.message
	end
end)
playerDowned.OnClientEvent:Connect(function(payload)
	if payload.userId == player.UserId then
		alertLbl.Text = "You are downed — allies revive at Beacon · solo auto-revive in sanctuary"
		reviveBtn.Visible = false
	else
		downedTargetId = payload.userId
		reviveBtn.Visible = true
		alertLbl.Text = string.format("%s is downed — press R at Beacon", payload.name or "Ally")
	end
end)

reviveBtn.MouseButton1Click:Connect(function()
	if not downedTargetId then
		return
	end
	local ok, msg, channel = startRevive:InvokeServer(downedTargetId)
	if ok and typeof(channel) == "number" then
		reviveChannelEnds = os.clock() + channel
		alertLbl.Text = "Reviving..."
		task.delay(channel, function()
			local done, doneMsg = completeRevive:InvokeServer()
			alertLbl.Text = if done then doneMsg else ("Revive failed: " .. doneMsg)
			reviveBtn.Visible = false
			downedTargetId = nil
		end)
	else
		alertLbl.Text = msg or "Cannot revive"
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.R then
		return
	end
	if reviveBtn.Visible then
		reviveBtn:Activate()
	end
end)

task.spawn(function()
	while true do
		local state = getSurvivalState:InvokeServer()
		applyState(state)
		task.wait(1)
	end
end)
