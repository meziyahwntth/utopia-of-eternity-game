--!strict
--[[
	Summer Music Festival Phase 1 — Stage C: Countdown System (Server)
	- Reads event start/end from GameConfig
	- Sets CountdownEndUnix attribute on sign parts for client countdown script
	- Manages festival lighting state (dusk + bloom boost during event)
	- Does NOT touch EternityCityLighting outside the event window
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local FestivalCountdownService = {}

-- ──────────────────────────────────────────────
-- Event window from GameConfig
-- ──────────────────────────────────────────────

local EVENT_START = os.time({ year = 2026, month = 6, day = 15, hour = 0, min = 0, sec = 0 })
local EVENT_END = os.time({ year = 2026, month = 8, day = 31, hour = 23, min = 59, sec = 59 })

-- ──────────────────────────────────────────────
-- Festival lighting (dusk + bloom boost)
-- ──────────────────────────────────────────────

local _originalLighting: { [string]: any }? = nil

local function applyFestivalLighting()
	local lighting = game:GetService("Lighting")
	_originalLighting = {
		ClockTime = lighting.ClockTime,
		Brightness = lighting.Brightness,
		Ambient = lighting.Ambient,
		OutdoorAmbient = lighting.OutdoorAmbient,
		EnvironmentDiffuseScale = lighting.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = lighting.EnvironmentSpecularScale,
	}

	lighting.ClockTime = 18.5
	lighting.Brightness = 1.6
	lighting.Ambient = Color3.fromRGB(40, 60, 100)
	lighting.OutdoorAmbient = Color3.fromRGB(50, 70, 120)
	lighting.EnvironmentDiffuseScale = 0.35
	lighting.EnvironmentSpecularScale = 0.7

	-- Boost bloom
	local bloom = lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then
		bloom.Intensity = 1.0
		bloom.Size = 24
		bloom.Threshold = 0.7
	end

	-- Warmer atmosphere
	local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Glare = 0.6
		atmosphere.Haze = 1.5
	end

	print("[FestivalCountdown] Festival lighting activated")
end

local function revertFestivalLighting()
	if not _originalLighting then return end
	local lighting = game:GetService("Lighting")
	for k, v in _originalLighting do
		(lighting :: any)[k] = v
	end

	local bloom = lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then
		bloom.Intensity = 0.45
		bloom.Size = 18
		bloom.Threshold = 0.85
	end

	local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Glare = 0.35
		atmosphere.Haze = 1.2
	end

	print("[FestivalCountdown] Festival lighting reverted")
end

-- ──────────────────────────────────────────────
-- Countdown sign management
-- ──────────────────────────────────────────────

local function isEventActive(): boolean
	local now = os.time()
	return now >= EVENT_START and now <= EVENT_END
end

local function isBeforeEvent(): boolean
	return os.time() < EVENT_START
end

local function getTargetUnix(): number
	if isBeforeEvent() then
		return EVENT_START -- countdown to start
	elseif isEventActive() then
		return EVENT_END -- countdown to end
	end
	return 0 -- past event, no countdown
end

local function buildCountdownSign(parent: Instance, position: Vector3, label: string, palette: any)
	local signFolder = Instance.new("Folder")
	signFolder.Name = "CountdownSign"
	signFolder.Parent = parent

	-- Post
	local post = Instance.new("Part")
	post.Name = "CountdownPost"
	post.Size = Vector3.new(1.5, 16, 1.5)
	post.CFrame = CFrame.new(position)
	post.Anchored = true
	post.Color = palette.Steel
	post.Material = Enum.Material.SmoothPlastic
	post.TopSurface = Enum.SurfaceType.Smooth
	post.BottomSurface = Enum.SurfaceType.Smooth
	post.Parent = signFolder

	-- Sign board
	local sign = Instance.new("Part")
	sign.Name = "FestivalCountdownSign"
	sign.Size = Vector3.new(22, 6, 1.2)
	sign.CFrame = CFrame.new(position + Vector3.new(0, 10, 0))
	sign.Anchored = true
	sign.Color = palette.Midnight
	sign.Material = Enum.Material.Slate
	sign.TopSurface = Enum.SurfaceType.Smooth
	sign.BottomSurface = Enum.SurfaceType.Smooth
	sign.Parent = signFolder

	-- BillboardGui for real-time countdown
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CountdownGui"
	billboard.Adornee = sign
	billboard.Size = UDim2.fromOffset(300, 80)
	billboard.StudsOffset = Vector3.new(0, 1.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = sign

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = palette.Gold
	stroke.Thickness = 1.5
	stroke.Parent = frame

	local text = Instance.new("TextLabel")
	text.Name = "CountdownText"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = palette.Cyan
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.Text = "..."
	text.Parent = frame

	-- Neon frame around sign
	local framePart = Instance.new("Part")
	framePart.Name = "CountdownNeonFrame"
	framePart.Size = Vector3.new(22.5, 6.5, 0.15)
	framePart.CFrame = CFrame.new(position + Vector3.new(0, 10, 0.6))
	framePart.Anchored = true
	framePart.Color = palette.Gold
	framePart.Material = Enum.Material.Neon
	framePart.Transparency = 0.05
	framePart.TopSurface = Enum.SurfaceType.Smooth
	framePart.BottomSurface = Enum.SurfaceType.Smooth
	framePart.Parent = signFolder

	-- Store target unix time as attribute for client
	sign:SetAttribute("CountdownTargetUnix", getTargetUnix())
	sign:SetAttribute("CountdownLabel", label)

	-- Update target when event transitions
	task.delay(60, function()
		sign:SetAttribute("CountdownTargetUnix", getTargetUnix())
	end)

	-- PointLight behind sign
	local light = Instance.new("PointLight")
	light.Color = palette.Amber
	light.Brightness = 1.5
	light.Range = 24
	light.Parent = sign

	return signFolder
end

-- ──────────────────────────────────────────────
-- Entry: setup(model)
-- ──────────────────────────────────────────────

function FestivalCountdownService.setup(model: Model, palette: any)
	-- Countdown sign #1: near stage (Twilight Overpass area)
	local stagePos = model:GetPivot().Position + Vector3.new(-90, 1.5, 105)
	buildCountdownSign(model, stagePos, "FestivalStage", palette)

	-- Countdown sign #2: near sanctuary spawn (loadout plaza area)
	local spawnPos = model:GetPivot().Position + Vector3.new(0, 3, 62)
	buildCountdownSign(model, spawnPos, "Sanctuary", palette)

	print("[FestivalCountdown] 2 countdown signs placed")

	-- Lighting: apply/revert based on event window
	local now = os.time()
	if now >= EVENT_START and now <= EVENT_END then
		applyFestivalLighting()
	elseif now < EVENT_START then
		-- Schedule lighting activation at event start
		local waitSeconds = EVENT_START - now
		if waitSeconds > 0 and waitSeconds < 86400 * 7 then -- within 7 days
			task.delay(waitSeconds, applyFestivalLighting)
			print(string.format("[FestivalCountdown] Lighting scheduled in %.1f hours", waitSeconds / 3600))
		end
	end

	-- Schedule lighting revert at event end
	if now < EVENT_END then
		local waitSeconds = EVENT_END - now
		if waitSeconds > 0 and waitSeconds < 86400 * 90 then -- within 90 days
			task.delay(waitSeconds, revertFestivalLighting)
		end
	end

	print(string.format("[FestivalCountdown] Initialized — start=%s end=%s now=%s",
		tostring(EVENT_START), tostring(EVENT_END), tostring(now)))
end

return FestivalCountdownService