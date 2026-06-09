--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("DeathValleyRemotes")
local stateChanged = remotes:WaitForChild("SurvivalStateChanged") :: RemoteEvent
local wraithAlert = remotes:WaitForChild("WraithAlert") :: RemoteEvent
local hollowScare = remotes:WaitForChild("HollowLakeScare") :: RemoteEvent

local ATTR_OPT_OUT = "DV_HorrorFxOptOut"

local overlay = Instance.new("ScreenGui")
overlay.Name = "DeathValleyHorrorFX"
overlay.ResetOnSpawn = false
overlay.IgnoreGuiInset = true
overlay.DisplayOrder = 5
overlay.Parent = playerGui

local vignette = Instance.new("Frame")
vignette.Name = "Vignette"
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundColor3 = Color3.new(0, 0, 0)
vignette.BackgroundTransparency = 0.45
vignette.BorderSizePixel = 0
vignette.Parent = overlay

local gradient = Instance.new("UIGradient")
gradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.05),
	NumberSequenceKeypoint.new(0.55, 0.55),
	NumberSequenceKeypoint.new(1, 0.05),
})
gradient.Parent = vignette

local toggleBtn = Instance.new("TextButton")
toggleBtn.AnchorPoint = Vector2.new(0, 1)
toggleBtn.Position = UDim2.new(0, 12, 1, -12)
toggleBtn.Size = UDim2.fromOffset(160, 28)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.Font = Enum.Font.Gotham
toggleBtn.TextSize = 12
toggleBtn.TextColor3 = Color3.fromRGB(220, 210, 255)
toggleBtn.Text = "Horror FX: ON"
toggleBtn.Parent = overlay

local heartbeat = Instance.new("Sound")
heartbeat.Name = "Heartbeat"
heartbeat.SoundId = "rbxasset://sounds/uuhhh.mp3"
heartbeat.Volume = 0.15
heartbeat.Looped = true
heartbeat.Parent = SoundService

local fxEnabled = player:GetAttribute(ATTR_OPT_OUT) ~= true
local waveActive = false
local pulse = 0

local function refreshToggle()
	fxEnabled = player:GetAttribute(ATTR_OPT_OUT) ~= true
	toggleBtn.Text = if fxEnabled then "Horror FX: ON" else "Horror FX: OFF (opt-out)"
	vignette.Visible = fxEnabled
	if not fxEnabled then
		heartbeat:Stop()
	end
end

toggleBtn.MouseButton1Click:Connect(function()
	player:SetAttribute(ATTR_OPT_OUT, fxEnabled)
	refreshToggle()
end)

stateChanged.OnClientEvent:Connect(function(state)
	if typeof(state) ~= "table" then
		return
	end
	waveActive = state.phase == "wave"
	if waveActive and fxEnabled then
		if not heartbeat.IsPlaying then
			heartbeat:Play()
		end
	else
		heartbeat:Stop()
		vignette.BackgroundTransparency = 0.45
	end
end)

wraithAlert.OnClientEvent:Connect(function()
	if fxEnabled then
		vignette.BackgroundTransparency = 0.15
		task.delay(0.35, function()
			if waveActive then
				vignette.BackgroundTransparency = 0.45
			end
		end)
	end
end)

hollowScare.OnClientEvent:Connect(function()
	if not fxEnabled then
		return
	end
	vignette.BackgroundTransparency = 0.02
	heartbeat.Volume = 0.45
	if not heartbeat.IsPlaying then
		heartbeat:Play()
	end
	task.delay(1.2, function()
		heartbeat.Volume = 0.15
		if waveActive then
			vignette.BackgroundTransparency = 0.45
		else
			vignette.BackgroundTransparency = 0.55
			heartbeat:Stop()
		end
	end)
end)

RunService.RenderStepped:Connect(function(dt)
	if not fxEnabled or not waveActive then
		return
	end
	pulse += dt * 2.4
	local alpha = 0.38 + math.sin(pulse) * 0.08
	vignette.BackgroundTransparency = alpha
end)

refreshToggle()
player:GetAttributeChangedSignal(ATTR_OPT_OUT):Connect(refreshToggle)
