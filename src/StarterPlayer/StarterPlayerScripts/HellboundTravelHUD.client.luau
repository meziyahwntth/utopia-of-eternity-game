--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("HellboundRemotes")
local travelChanged = remotes:WaitForChild("TravelStateChanged") :: RemoteEvent

local hud = Instance.new("ScreenGui")
hud.Name = "HellboundTravelHUD"
hud.ResetOnSpawn = false
hud.Parent = playerGui

local banner = Instance.new("Frame")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 48)
banner.Size = UDim2.fromOffset(360, 56)
banner.BackgroundColor3 = Color3.fromRGB(20, 12, 30)
banner.BackgroundTransparency = 0.15
banner.Visible = false
banner.Parent = hud
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 10)

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -16, 1, -8)
label.Position = UDim2.fromOffset(8, 4)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.TextColor3 = Color3.fromRGB(0, 229, 255)
label.TextWrapped = true
label.Text = ""
label.Parent = banner

travelChanged.OnClientEvent:Connect(function(state)
	if typeof(state) ~= "table" or state.active ~= true then
		banner.Visible = false
		return
	end
	banner.Visible = true
	local left = math.max(0, (state.phaseEndsAt or 0) - os.clock())
	label.Text = string.format(
		"Hellbound · %s (%d/%d) · %.0fs",
		state.phaseName or "Travel",
		state.phaseIndex or 0,
		state.totalPhases or 6,
		left
	)
end)

print("[Hellbound] Travel HUD ready")
