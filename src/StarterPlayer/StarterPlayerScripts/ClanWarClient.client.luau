--!strict
--[[
	ClanWarClient (P5) — territory HUD, war countdown, fort HP bar
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local ClanWarConfig = require(Modules:WaitForChild("ClanWarConfig"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes")
local warStarted = remotes:WaitForChild("WarStarted") :: RemoteEvent
local warResult = remotes:WaitForChild("WarResult") :: RemoteEvent
local territoryUpdate = remotes:WaitForChild("TerritoryUpdate") :: RemoteEvent
local getTerritoryStatus = remotes:WaitForChild("GetTerritoryStatus") :: RemoteFunction

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClanWarHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 8
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "TerritoryPanel"
panel.Size = UDim2.fromScale(0.32, 0.14)
panel.Position = UDim2.fromScale(0.01, 0.01)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
panel.BackgroundTransparency = 0.35
panel.BorderSizePixel = 0
panel.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = panel
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = panel
end

local zoneLabel = Instance.new("TextLabel")
zoneLabel.Size = UDim2.new(1, 0, 0, 18)
zoneLabel.BackgroundTransparency = 1
zoneLabel.Text = "🏛 Territory: —"
zoneLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
zoneLabel.Font = Enum.Font.GothamBold
zoneLabel.TextSize = 13
zoneLabel.TextXAlignment = Enum.TextXAlignment.Left
zoneLabel.Parent = panel

local fortBarBg = Instance.new("Frame")
fortBarBg.Size = UDim2.new(1, 0, 0, 10)
fortBarBg.Position = UDim2.fromOffset(0, 22)
fortBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
fortBarBg.BorderSizePixel = 0
fortBarBg.Parent = panel
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = fortBarBg
end

local fortBarFill = Instance.new("Frame")
fortBarFill.Name = "Fill"
fortBarFill.Size = UDim2.new(1, 0, 1, 0)
fortBarFill.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
fortBarFill.BorderSizePixel = 0
fortBarFill.Parent = fortBarBg
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = fortBarFill
end

local fortLabel = Instance.new("TextLabel")
fortLabel.Size = UDim2.new(1, 0, 0, 14)
fortLabel.Position = UDim2.fromOffset(0, 34)
fortLabel.BackgroundTransparency = 1
fortLabel.Text = "Fort HP: —"
fortLabel.TextColor3 = Color3.fromRGB(180, 220, 180)
fortLabel.Font = Enum.Font.Gotham
fortLabel.TextSize = 11
fortLabel.TextXAlignment = Enum.TextXAlignment.Left
fortLabel.Parent = panel

local countdownLabel = Instance.new("TextLabel")
countdownLabel.Size = UDim2.fromScale(0.22, 0.06)
countdownLabel.Position = UDim2.fromScale(0.39, 0.01)
countdownLabel.BackgroundTransparency = 0.25
countdownLabel.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
countdownLabel.TextColor3 = Color3.new(1, 1, 1)
countdownLabel.Font = Enum.Font.GothamBold
countdownLabel.TextSize = 14
countdownLabel.Text = ""
countdownLabel.Visible = false
countdownLabel.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = countdownLabel
end

local activeZoneId: string? = nil
local warEndsAt: number? = nil

local function zoneDisplayName(zoneId: string): string
	for _, zone in ClanWarConfig.Zones do
		if zone.id == zoneId then
			return zone.displayName
		end
	end
	return zoneId
end

local function updateFortHp(fortHp: number)
	local pct = math.clamp(fortHp / ClanWarConfig.FortHpMax, 0, 1)
	fortBarFill.Size = UDim2.new(pct, 0, 1, 0)
	fortLabel.Text = string.format("Fort HP: %d%%", fortHp)
end

local function showTerritory(zoneId: string, ownerName: string, taxRate: number, fortHp: number?)
	activeZoneId = zoneId
	local display = zoneDisplayName(zoneId)
	zoneLabel.Text = string.format("🏛 %s | %s | Tax %d%%", display, ownerName, taxRate)
	if typeof(fortHp) == "number" then
		updateFortHp(fortHp)
	end
end

task.defer(function()
	local ok, status = pcall(function()
		return getTerritoryStatus:InvokeServer()
	end)
	if ok and typeof(status) == "table" and #status > 0 then
		local first = status[1]
		if typeof(first) == "table" then
			showTerritory(
				tostring(first.zoneId),
				tostring(first.ownerName),
				if typeof(first.taxRate) == "number" then first.taxRate else 1,
				if typeof(first.fortHp) == "number" then first.fortHp else ClanWarConfig.FortHpMax
			)
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if warEndsAt then
		local remaining = math.max(0, warEndsAt - os.time())
		local m = math.floor(remaining / 60)
		local s = remaining % 60
		countdownLabel.Text = string.format("⚔ War: %02d:%02d", m, s)
		if remaining == 0 then
			warEndsAt = nil
			countdownLabel.Visible = false
		end
	end
end)

warStarted.OnClientEvent:Connect(function(zoneId: any, endsAt: any)
	if typeof(endsAt) == "number" then
		warEndsAt = endsAt
		countdownLabel.Visible = true
	end
	if typeof(zoneId) == "string" then
		zoneLabel.Text = "⚔ WAR: " .. zoneDisplayName(zoneId)
	end
end)

warResult.OnClientEvent:Connect(function(zoneId: any, winnerId: any)
	countdownLabel.Visible = false
	warEndsAt = nil
	zoneLabel.Text = string.format("🏆 %s → %s", tostring(zoneId), tostring(winnerId))
end)

territoryUpdate.OnClientEvent:Connect(function(zoneId: any, ownerName: any, taxRate: any, fortHp: any)
	if typeof(zoneId) ~= "string" then
		return
	end
	if activeZoneId == nil or activeZoneId == zoneId then
		showTerritory(
			zoneId,
			tostring(ownerName),
			if typeof(taxRate) == "number" then taxRate else 1,
			if typeof(fortHp) == "number" then fortHp else nil
		)
	end
end)

print("[ClanWar] ClanWarClient online (P5)")
