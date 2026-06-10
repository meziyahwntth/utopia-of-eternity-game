--!strict
--[[
	Eternity City art pass #6 — Twilight Overpass (Visual Bible: elevated walkway,
	5 neon event arches spanning the deck, dual walkable ramps, event stage,
	amber lantern corridor, Key 10+ zone).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)
local OrganicCSGBuilder = require(script.Parent.OrganicCSGBuilder)

local EternityCityTwilightOverpassLandmark = {}

export type BuildContext = {
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
	origin: CFrame,
}

-- ──────────────────────────────────────────────
-- Helpers
-- ──────────────────────────────────────────────

local function addPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	transparency: number?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.Color = color
	part.Material = material
	part.Transparency = transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addLabel(parent: BasePart, text: string)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.Parent = gui
end

-- ──────────────────────────────────────────────
-- Constants
-- ──────────────────────────────────────────────

local DECK_HALF_Z = 35 -- half-length of overpass deck along z
local DECK_Y = 16 -- deck elevation
local DECK_WIDTH = 8 -- deck width along x
local RAMP_RUN = 45 -- ramp horizontal run
local RAMP_RISE = DECK_Y - 1 -- ramp vertical rise
local RAMP_SLOPE = RAMP_RISE / RAMP_RUN

-- ──────────────────────────────────────────────
-- Overpass deck + dual walkable ramps + railings
-- ──────────────────────────────────────────────

local function buildOverpass(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local center = ctx.origin.Position
	local partCount = 0

	-- Main deck
	addPart(
		district,
		"OverpassDeck",
		Vector3.new(DECK_WIDTH, 1.2, DECK_HALF_Z * 2),
		CFrame.new(center + Vector3.new(0, DECK_Y, 0)),
		palette.Pearl,
		Enum.Material.SmoothPlastic
	)
	partCount += 1

	-- Neon edge strips along deck
	for _, xSide in { -(DECK_WIDTH / 2 + 0.6), (DECK_WIDTH / 2 + 0.6) } do
		addPart(
			district,
			"DeckEdgeX_" .. tostring(xSide),
			Vector3.new(0.6, 0.6, DECK_HALF_Z * 2),
			CFrame.new(center + Vector3.new(xSide, DECK_Y + 0.9, 0)),
			palette.Amber,
			Enum.Material.Neon,
			0.06
		)
		partCount += 1
	end

	-- Deck end caps (x-beams at z ends)
	for _, zEnd in { -DECK_HALF_Z, DECK_HALF_Z } do
		addPart(
			district,
			"DeckCap_" .. tostring(zEnd),
			Vector3.new(DECK_WIDTH + 2, 0.8, 1),
			CFrame.new(center + Vector3.new(0, DECK_Y + 0.4, zEnd)),
			palette.Gold,
			Enum.Material.Neon,
			0.08
		)
		partCount += 1
	end

	-- Dual ramps: south (z negative, going up) and north (z positive, going down)
	local rampHalfWidth = DECK_WIDTH / 2
	local rampEnds = {
		{
			label = "South",
			deckZ = -DECK_HALF_Z,
			groundZ = -DECK_HALF_Z - RAMP_RUN,
			rampAngle = -math.atan(RAMP_SLOPE), -- z+ end higher (up from south)
		},
		{
			label = "North",
			deckZ = DECK_HALF_Z,
			groundZ = DECK_HALF_Z + RAMP_RUN,
			rampAngle = math.atan(RAMP_SLOPE), -- z+ end lower (down to north)
		},
	}

	for _, ramp in rampEnds do
		local rampCenterY = 1 + RAMP_RISE / 2
		local rampCenterZ = (ramp.deckZ + ramp.groundZ) / 2

		-- Ramp deck
		addPart(
			district,
			"OverpassRamp_" .. ramp.label,
			Vector3.new(DECK_WIDTH, 0.8, RAMP_RUN),
			CFrame.new(center + Vector3.new(0, rampCenterY, rampCenterZ)) * CFrame.Angles(ramp.rampAngle, 0, 0),
			palette.Pearl,
			Enum.Material.SmoothPlastic
		)
		partCount += 1

		-- Ramp edge rails (Neon strips along both sides)
		for _, xRail in { -(rampHalfWidth + 0.6), (rampHalfWidth + 0.6) } do
			local railLabel = if xRail < 0 then "L" else "R"
			addPart(
				district,
				"RampRail_" .. ramp.label .. "_" .. railLabel,
				Vector3.new(0.3, 0.2, RAMP_RUN - 1),
				CFrame.new(center + Vector3.new(xRail, rampCenterY + 1.8, rampCenterZ)) * CFrame.Angles(ramp.rampAngle, 0, 0),
				palette.Gold,
				Enum.Material.Neon,
				0.05
			)
			partCount += 1
		end

		-- Ramp support pillars (2 per ramp)
		for _, pillarFrac in { 0.25, 0.75 } do
			local pillarZ = ramp.groundZ + (ramp.deckZ - ramp.groundZ) * pillarFrac
			local pillarY = 1 + RAMP_RISE * pillarFrac
			addPart(
				district,
				"RampPillar_" .. ramp.label .. "_" .. tostring(pillarFrac),
				Vector3.new(1.5, pillarY, 1.5),
				CFrame.new(center + Vector3.new(0, pillarY / 2, pillarZ)),
				palette.Pearl,
				Enum.Material.SmoothPlastic
			)
			partCount += 1
		end
	end

	-- Deck support pillars (3 along main span)
	for _, zPillar in { -15, 0, 15 } do
		addPart(
			district,
			"DeckPillar_" .. tostring(zPillar),
			Vector3.new(2, DECK_Y - 1, 2),
			CFrame.new(center + Vector3.new(0, (DECK_Y - 1) / 2, zPillar)),
			palette.Pearl,
			Enum.Material.SmoothPlastic
		)
		partCount += 1
	end

	WorldBuildBudget:add(ctx.budget, partCount)
end

-- ──────────────────────────────────────────────
-- 5 event neon arches spanning overpass (gradient: Cyan→Gold→Amber→Gold→Cyan)
-- ──────────────────────────────────────────────

local ARCH_SPACING = 16 -- studs between arch centers along z
local ARCH_HALF_SPAN = 18 -- half-width x-direction
local ARCH_HEIGHT = 24 -- height above ground

local function buildEventArches(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local center = ctx.origin.Position
	local archCount = 5

	-- Color gradient: Cyan → Gold → Amber → Gold → Cyan
	local archColors: { Color3 } = {
		palette.Cyan,
		palette.Gold,
		palette.Amber,
		palette.Gold,
		palette.Cyan,
	}

	for i = 1, archCount do
		local zOffset = (i - 3) * ARCH_SPACING -- centers at -32, -16, 0, 16, 32
		local archOrigin = CFrame.new(center + Vector3.new(0, DECK_Y, zOffset))
		local archColor = archColors[i]

		-- Build arch using OrganicCSGBuilder
		OrganicCSGBuilder:createArch(archOrigin, ARCH_HALF_SPAN * 2, ARCH_HEIGHT, 2.5, {
			color = palette.Pearl,
			material = Enum.Material.SmoothPlastic,
			parent = district,
			name = "EventArch_" .. i,
		})

		-- Neon arch highlight (MicroCurveBuilder arc following the arch curve)
		local arcPoints: { Vector3 } = {}
		local steps = 16
		for s = 0, steps do
			local t = s / steps
			local angle = math.pi * t
			local x = math.cos(angle) * ARCH_HALF_SPAN
			local y = math.sin(angle) * ARCH_HEIGHT
			table.insert(arcPoints, (archOrigin * CFrame.new(x, y, 0)).Position)
		end
		MicroCurveBuilder:fillArc(arcPoints, 0.8, {
			voxelStuds = ctx.profile.VoxelStuds * 0.8,
			color = archColor,
			material = Enum.Material.Neon,
			parent = district,
			collision = false,
			budget = ctx.budget,
		})

		-- Keystone light at arch apex
		local keystone = addPart(
			district,
			"ArchKeystone_" .. i,
			Vector3.new(3, 3, 3),
			archOrigin * CFrame.new(0, ARCH_HEIGHT - 2, 0),
			archColor,
			Enum.Material.Neon,
			0.1
		)
		local light = Instance.new("PointLight")
		light.Color = archColor
		light.Brightness = 1.8
		light.Range = 24
		light.Parent = keystone
	end

	WorldBuildBudget:add(ctx.budget, archCount * 5)
end

-- ──────────────────────────────────────────────
-- Event stage — platform below overpass
-- ──────────────────────────────────────────────

local function buildEventStage(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local center = ctx.origin.Position

	-- Stage platform (below overpass, on east side)
	local stageCenter = center + Vector3.new(18, 1.2, 0)
	local stageDeck = addPart(
		district,
		"EventStagePlatform",
		Vector3.new(24, 0.8, 16),
		CFrame.new(stageCenter),
		palette.Pearl,
		Enum.Material.SmoothPlastic
	)
	stageDeck:SetAttribute("EventStage", true)

	-- Stage neon edge trim
	for _, zSide in { -8.6, 8.6 } do
		addPart(
			district,
			"StageTrimZ_" .. tostring(zSide),
			Vector3.new(24, 0.2, 0.6),
			CFrame.new(stageCenter + Vector3.new(0, 0.5, zSide)),
			palette.Cyan,
			Enum.Material.Neon,
			0.05
		)
	end
	for _, xSide in { -12.6, 12.6 } do
		addPart(
			district,
			"StageTrimX_" .. tostring(xSide),
			Vector3.new(0.6, 0.2, 16),
			CFrame.new(stageCenter + Vector3.new(xSide, 0.5, 0)),
			palette.Cyan,
			Enum.Material.Neon,
			0.05
		)
	end

	-- Backdrop neon wall (behind stage, facing the overpass)
	local backdrop = addPart(
		district,
		"EventStageBackdrop",
		Vector3.new(28, 12, 0.6),
		CFrame.new(stageCenter + Vector3.new(0, 6.5, -8)),
		palette.Twilight,
		Enum.Material.SmoothPlastic
	)

	-- Neon accent strips on backdrop
	for _, yStrip in { 3, 7, 10 } do
		addPart(
			district,
			"StageBackdropStrip_" .. yStrip,
			Vector3.new(26, 0.3, 0.7),
			CFrame.new(stageCenter + Vector3.new(0, yStrip, -7.9)),
			palette.Amber,
			Enum.Material.Neon,
			0.08
		)
	end

	-- Stage sign
	local signPart = addPart(
		district,
		"EventStageSign",
		Vector3.new(14, 3, 1),
		CFrame.new(stageCenter + Vector3.new(0, 9, -8)),
		palette.Gold,
		Enum.Material.Neon,
		0.08
	)
	addLabel(signPart, "Twilight Stage")

	-- Stage point light
	local stageLight = Instance.new("PointLight")
	stageLight.Name = "StageSpotlight"
	stageLight.Color = palette.Amber
	stageLight.Brightness = 2.2
	stageLight.Range = 40
	stageLight.Parent = signPart

	WorldBuildBudget:add(ctx.budget, 9)
end

-- ──────────────────────────────────────────────
-- Amber lantern corridor along approach path
-- ──────────────────────────────────────────────

local function buildLanternCorridor(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local center = ctx.origin.Position
	local partCount = 0

	for i = -3, 3 do
		local zOff = i * 12
		for _, xSide in { -30, 30 } do
			addPart(
				district,
				"OverpassPost_" .. i .. "_" .. tostring(xSide),
				Vector3.new(0.8, 14, 0.8),
				CFrame.new(center + Vector3.new(xSide, 7, zOff)),
				palette.Pearl,
				Enum.Material.SmoothPlastic
			)
			partCount += 1

			local lamp = addPart(
				district,
				"OverpassLamp_" .. i .. "_" .. tostring(xSide),
				Vector3.new(2.2, 2.2, 2.2),
				CFrame.new(center + Vector3.new(xSide, 15, zOff)),
				palette.Amber,
				Enum.Material.Neon,
				0.12
			)
			partCount += 1

			local light = Instance.new("PointLight")
			light.Color = palette.Amber
			light.Brightness = 1.6
			light.Range = 20
			light.Parent = lamp
		end
	end

	WorldBuildBudget:add(ctx.budget, partCount)
end

-- ──────────────────────────────────────────────
-- Entry: build()
-- ──────────────────────────────────────────────

function EternityCityTwilightOverpassLandmark.build(ctx: BuildContext): Folder
	local district = Instance.new("Folder")
	district.Name = "TwilightOverpass"
	district:SetAttribute("LandmarkArtPass", "v6_twilight_overpass")
	district:SetAttribute("VisualBibleDistrict", "TwilightOverpass")

	buildOverpass(district, ctx)
	buildEventArches(district, ctx)
	buildEventStage(district, ctx)
	buildLanternCorridor(district, ctx)

	district.Parent = ctx.parent
	return district
end

return EternityCityTwilightOverpassLandmark