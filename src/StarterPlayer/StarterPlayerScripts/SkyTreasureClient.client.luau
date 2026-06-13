--!strict
--[[
	SkyTreasureClient (P6) — announcement banner, countdown timer, minimap markers
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

local remotes = ReplicatedStorage:WaitForChild("SocialRemotes")
local announce = remotes:WaitForChild("SkyTreasureAnnounce") :: RemoteEvent
local claimed = remotes:WaitForChild("SkyTreasureClaimed") :: RemoteEvent

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkyTreasureHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 9
screenGui.Parent = playerGui

local banner = Instance.new("Frame")
banner.Size = UDim2.fromScale(0.6, 0.1)
banner.Position = UDim2.fromScale(0.2, -0.12)
banner.BackgroundColor3 = Color3.fromRGB(180, 140, 20)
banner.BackgroundTransparency = 0.1
banner.BorderSizePixel = 0
banner.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = banner
end

local bannerText = Instance.new("TextLabel")
bannerText.Size = UDim2.fromScale(1, 0.6)
bannerText.BackgroundTransparency = 1
bannerText.TextColor3 = Color3.new(1, 1, 1)
bannerText.Font = Enum.Font.GothamBold
bannerText.TextSize = 16
bannerText.TextWrapped = true
bannerText.Text = ""
bannerText.Parent = banner

local timerText = Instance.new("TextLabel")
timerText.Size = UDim2.fromScale(1, 0.4)
timerText.Position = UDim2.fromScale(0, 0.6)
timerText.BackgroundTransparency = 1
timerText.TextColor3 = Color3.fromRGB(255, 240, 160)
timerText.Font = Enum.Font.GothamBold
timerText.TextSize = 14
timerText.Text = ""
timerText.Parent = banner

local markerFolder = Instance.new("Folder")
markerFolder.Name = "SkyTreasureMarkers"
markerFolder.Parent = screenGui

local chestEndsAt: number? = nil
local slideTween: Tween? = nil

local function clearMarkers()
	for _, child in markerFolder:GetChildren() do
		child:Destroy()
	end
end

local function addMarker(displayName: string, position: Vector3)
	local marker = Instance.new("Frame")
	marker.Size = UDim2.fromOffset(10, 10)
	marker.BackgroundColor3 = Color3.fromRGB(255, 220, 80)
	marker.BorderSizePixel = 0
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Parent = markerFolder
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = marker
	end

	local tip = Instance.new("TextLabel")
	tip.Size = UDim2.fromOffset(120, 16)
	tip.Position = UDim2.fromOffset(-55, -18)
	tip.BackgroundTransparency = 1
	tip.Text = displayName
	tip.TextColor3 = Color3.fromRGB(255, 240, 160)
	tip.Font = Enum.Font.Gotham
	tip.TextSize = 11
	tip.Parent = marker

	marker:SetAttribute("WorldX", position.X)
	marker:SetAttribute("WorldY", position.Y)
	marker:SetAttribute("WorldZ", position.Z)
end

local function updateMarkerPositions()
	for _, marker in markerFolder:GetChildren() do
		if not marker:IsA("Frame") then
			continue
		end
		local wx = marker:GetAttribute("WorldX")
		local wy = marker:GetAttribute("WorldY")
		local wz = marker:GetAttribute("WorldZ")
		if typeof(wx) ~= "number" or typeof(wy) ~= "number" or typeof(wz) ~= "number" then
			continue
		end
		local screenPos, onScreen = camera:WorldToScreenPoint(Vector3.new(wx, wy, wz))
		if onScreen then
			marker.Visible = true
			marker.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
		else
			marker.Visible = false
		end
	end
end

local function showBanner(text: string)
	bannerText.Text = text
	if slideTween then
		slideTween:Cancel()
	end
	local inTween = TweenService:Create(banner, TweenInfo.new(0.4), {
		Position = UDim2.fromScale(0.2, 0.02),
	})
	slideTween = inTween
	inTween:Play()
	task.delay(8, function()
		local outTween = TweenService:Create(banner, TweenInfo.new(0.4), {
			Position = UDim2.fromScale(0.2, -0.12),
		})
		outTween:Play()
	end)
end

RunService.Heartbeat:Connect(function()
	if chestEndsAt then
		local remaining = math.max(0, chestEndsAt - os.time())
		timerText.Text = string.format("⏱ %d:%02d", math.floor(remaining / 60), remaining % 60)
		if remaining == 0 then
			chestEndsAt = nil
			timerText.Text = ""
			clearMarkers()
		end
	end
	updateMarkerPositions()
end)

announce.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	local endsAt = payload.endsAt
	if typeof(endsAt) == "number" then
		chestEndsAt = endsAt
	end

	local zoneNames = payload.zoneNames
	local zones = if typeof(zoneNames) == "table" then table.concat(zoneNames :: { string }, " · ") else "Eternity City"
	showBanner(string.format("🎁 กล่องสมบัติลอยฟ้าตกที่ %s!", zones))

	clearMarkers()
	local chests = payload.chests
	if typeof(chests) == "table" then
		for _, entry in chests :: { any } do
			if typeof(entry) ~= "table" then
				continue
			end
			local name = if typeof(entry.displayName) == "string" then entry.displayName else "Chest"
			local pos = entry.position
			if typeof(pos) == "Vector3" then
				addMarker(name, pos)
			end
		end
	end
end)

claimed.OnClientEvent:Connect(function(winnerName: any, zoneName: any, rewardLabel: any)
	chestEndsAt = nil
	timerText.Text = ""
	clearMarkers()
	showBanner(
		string.format("🏆 %s ยึด %s ได้ %s!", tostring(winnerName), tostring(zoneName), tostring(rewardLabel))
	)
end)

print("[LiveOps] SkyTreasureClient online (P6)")
