--!strict
--[[
	Death Valley Peak Colony Builder — Hellbound Summit Plateau
	Landing pad · Colony Domes · Shuttle · walkable ramp from pipeline level
	Docs: docs/death-valley/HELLBOUND-TRAVEL-AND-DEATH-VALLEY.md §4
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)
local OrganicCSGBuilder = require(script.Parent.OrganicCSGBuilder)

local ShuttleGreyboxBuilder = require(ServerScriptService:WaitForChild("ShuttleGreyboxBuilder"))

local DeathValleyPeakColonyBuilder = {}

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

-- Mountain peak: FillBlock at CFrame(0, 30, -80) with 200×80×40 → peak top ~y=70 at z≈-80
-- Place colony plateau slightly off-center on the mountain
local PEAK_CENTER = Vector3.new(-50, 68, -85)
local PEAK_HALF = 40 -- plateau half-size

local PALETTE = {
	Pearl = Color3.fromRGB(245, 245, 240),
	Gold = Color3.fromRGB(212, 175, 55),
	Cyan = Color3.fromRGB(0, 229, 255),
	Amber = Color3.fromRGB(255, 179, 71),
	Twilight = Color3.fromRGB(20, 12, 30),
}

-- ──────────────────────────────────────────────
-- Peak plateau (platform on mountain summit)
-- ──────────────────────────────────────────────

local function buildPeakPlateau(parent: Instance, budget: WorldBuildBudget.Budget)
	-- Main plateau deck
	addPart(
		parent,
		"SummitPlateau",
		Vector3.new(PEAK_HALF * 2, 1.5, PEAK_HALF * 2),
		CFrame.new(PEAK_CENTER + Vector3.new(0, 0.75, 0)),
		Color3.fromRGB(40, 35, 45),
		Enum.Material.Slate
	)

	-- Plateau edge neon trim (4 sides)
	for _, xEdge in { -PEAK_HALF + 1, PEAK_HALF - 1 } do
		addPart(
			parent,
			"PlateauEdgeX_" .. tostring(xEdge),
			Vector3.new(1, 0.4, PEAK_HALF * 2 - 2),
			CFrame.new(PEAK_CENTER + Vector3.new(xEdge, 1.5, 0)),
			PALETTE.Amber,
			Enum.Material.Neon,
			0.1
		)
	end
	for _, zEdge in { -PEAK_HALF + 1, PEAK_HALF - 1 } do
		addPart(
			parent,
			"PlateauEdgeZ_" .. tostring(zEdge),
			Vector3.new(PEAK_HALF * 2 - 2, 0.4, 1),
			CFrame.new(PEAK_CENTER + Vector3.new(0, 1.5, zEdge)),
			PALETTE.Amber,
			Enum.Material.Neon,
			0.1
		)
	end

	WorldBuildBudget:add(budget, 5)
end

-- ──────────────────────────────────────────────
-- Walkable ramp from plateau down to pipeline level (~y=4)
-- ──────────────────────────────────────────────

local function buildRamp(parent: Instance, budget: WorldBuildBudget.Budget)
	local rampStart = Vector3.new(PEAK_CENTER.X, 68, PEAK_CENTER.Z + PEAK_HALF)
	local rampEnd = Vector3.new(PEAK_CENTER.X + 80, 4, PEAK_CENTER.Z + PEAK_HALF + 60)
	local delta = rampEnd - rampStart
	local rampLength = delta.Magnitude
	local rampMid = rampStart:Lerp(rampEnd, 0.5)
	local rampDir = delta.Unit
	local rampAngle = math.atan(-delta.Y / rampLength)

	-- Ramp deck
	local rampDeck = addPart(
		parent,
		"ColonyRamp",
		Vector3.new(6, 0.8, rampLength),
		CFrame.new(rampMid) * CFrame.Angles(rampAngle, 0, 0),
		Color3.fromRGB(45, 40, 55),
		Enum.Material.Slate
	)

	-- Ramp edge rails (Neon Amber, both sides)
	for _, xOff in { -3.3, 3.3 } do
		local railLabel = if xOff < 0 then "L" else "R"
		addPart(
			parent,
			"RampRail_" .. railLabel,
			Vector3.new(0.3, 0.2, rampLength - 1),
			CFrame.new(rampMid + Vector3.new(xOff, 1.8, 0)) * CFrame.Angles(rampAngle, 0, 0),
			PALETTE.Amber,
			Enum.Material.Neon,
			0.08
		)
	end

	-- Support pillars every ~20 studs
	local pillarCount = math.floor(rampLength / 20)
	for i = 1, pillarCount do
		local t = i / (pillarCount + 1)
		local pillarPos = rampStart:Lerp(rampEnd, t)
		local pillarHeight = pillarPos.Y - 1
		addPart(
			parent,
			"RampPillar_" .. i,
			Vector3.new(2, pillarHeight, 2),
			CFrame.new(Vector3.new(pillarPos.X, pillarHeight / 2, pillarPos.Z)),
			Color3.fromRGB(30, 25, 40),
			Enum.Material.Slate
		)
	end

	-- Landing platform at ramp bottom (connects to ground)
	addPart(
		parent,
		"RampLanding",
		Vector3.new(10, 1, 8),
		CFrame.new(rampEnd + Vector3.new(0, -0.5, 0)),
		Color3.fromRGB(40, 35, 45),
		Enum.Material.Slate
	)

	WorldBuildBudget:add(budget, 4 + pillarCount + 1)
end

-- ──────────────────────────────────────────────
-- Landing pad (circular, neon edge, beacon)
-- ──────────────────────────────────────────────

local function buildLandingPad(parent: Instance, budget: WorldBuildBudget.Budget)
	local padCenter = PEAK_CENTER + Vector3.new(30, 0, 20)
	local padRadius = 16

	-- Circular pad base
	local pad = addPart(
		parent,
		"LandingPad",
		Vector3.new(padRadius * 2, 0.8, padRadius * 2),
		CFrame.new(padCenter + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, math.rad(45), 0),
		Color3.fromRGB(60, 55, 70),
		Enum.Material.Slate
	)
	pad:SetAttribute("LandingPad", true)
	pad:SetAttribute("ColonyLandingPad", true)

	-- Neon edge ring
	MicroCurveBuilder:fillCircle(padCenter + Vector3.new(0, 0.9, 0), padRadius - 1, 1.2, {
		voxelStuds = 0.15,
		color = PALETTE.Cyan,
		material = Enum.Material.Neon,
		parent = parent,
		filled = false,
		collision = false,
		budget = budget,
	})

	-- Inner marker circle
	MicroCurveBuilder:fillCircle(padCenter + Vector3.new(0, 0.85, 0), 6, 1, {
		voxelStuds = 0.15,
		color = PALETTE.Amber,
		material = Enum.Material.Neon,
		parent = parent,
		filled = true,
		budget = budget,
	})

	-- Beacon light
	local beacon = addPart(
		parent,
		"LandingBeacon",
		Vector3.new(2, 8, 2),
		CFrame.new(padCenter + Vector3.new(0, 4, 10)),
		PALETTE.Amber,
		Enum.Material.Neon,
		0.1
	)
	local beaconLight = Instance.new("PointLight")
	beaconLight.Name = "BeaconLight"
	beaconLight.Color = PALETTE.Cyan
	beaconLight.Brightness = 2.5
	beaconLight.Range = 60
	beaconLight.Parent = beacon

	WorldBuildBudget:add(budget, 4)
end

-- ──────────────────────────────────────────────
-- Colony Domes (2 residential domes)
-- ──────────────────────────────────────────────

local function buildDomes(parent: Instance, budget: WorldBuildBudget.Budget)
	local domePositions = {
		{ pos = PEAK_CENTER + Vector3.new(-20, 68, -20), radius = 14, index = 1 },
		{ pos = PEAK_CENTER + Vector3.new(5, 68, -25), radius = 14, index = 2 },
	}

	for _, dome in domePositions do
		local domeModel = OrganicCSGBuilder:createDome(dome.pos, dome.radius, {
			color = Color3.fromRGB(45, 40, 60),
			material = Enum.Material.SmoothPlastic,
			parent = parent,
			name = "ColonyDome_" .. dome.index,
		})
		domeModel:SetAttribute("ColonyDome", true)
		domeModel:SetAttribute("DomeIndex", dome.index)

		-- Entrance arch
		local entrance = addPart(
			parent,
			"DomeEntrance_" .. dome.index,
			Vector3.new(6, 8, 0.6),
			CFrame.new(dome.pos + Vector3.new(0, 4, dome.radius)),
			PALETTE.Gold,
			Enum.Material.Metal
		)
		entrance:SetAttribute("ColonyDomeEntrance", true)

		-- Interior light
		local domeLight = Instance.new("PointLight")
		domeLight.Name = "DomeLight_" .. dome.index
		domeLight.Color = PALETTE.Amber
		domeLight.Brightness = 1.5
		domeLight.Range = dome.radius
		domeLight.Parent = domeModel
	end

	WorldBuildBudget:add(budget, 4)
end

-- ──────────────────────────────────────────────
-- Shuttle stop (reuse ShuttleGreyboxBuilder)
-- ──────────────────────────────────────────────

local function buildShuttle(parent: Instance, budget: WorldBuildBudget.Budget)
	local shuttleOrigin = CFrame.new(PEAK_CENTER + Vector3.new(-30, 68, 20))
	local build = ShuttleGreyboxBuilder:BuildEternityVariant(parent, shuttleOrigin)

	if build and build.Root then
		build.Root:SetAttribute("ColonyShuttle", true)
	end

	WorldBuildBudget:add(budget, 25)
end

-- ──────────────────────────────────────────────
-- Colony sign
-- ──────────────────────────────────────────────

local function buildSign(parent: Instance, budget: WorldBuildBudget.Budget)
	local signPos = PEAK_CENTER + Vector3.new(0, 70, -42)

	local signBoard = addPart(
		parent,
		"PeakColonySign",
		Vector3.new(20, 5, 1),
		CFrame.new(signPos),
		PALETTE.Amber,
		Enum.Material.Neon,
		0.1
	)
	addLabel(signBoard, "Peak Colony · Hellbound Summit")

	WorldBuildBudget:add(budget, 1)
end

-- ──────────────────────────────────────────────
-- Outer perimeter railing (12 posts)
-- ──────────────────────────────────────────────

local function buildPerimeterRail(parent: Instance, budget: WorldBuildBudget.Budget)
	for i = 0, 11 do
		local angle = (i / 12) * math.pi * 2
		local r = PEAK_HALF - 2
		local postPos = PEAK_CENTER + Vector3.new(math.cos(angle) * r, 69, math.sin(angle) * r)

		local post = addPart(
			parent,
			"PerimeterPost_" .. i,
			Vector3.new(0.6, 4, 0.6),
			CFrame.new(postPos),
			Color3.fromRGB(50, 45, 55),
			Enum.Material.Slate
		)

		-- Amber light at top of each post
		local lightTop = addPart(
			parent,
			"PerimeterLamp_" .. i,
			Vector3.new(1.5, 1.5, 1.5),
			CFrame.new(postPos + Vector3.new(0, 2, 0)),
			PALETTE.Amber,
			Enum.Material.Neon,
			0.2
		)
	end

	-- Neon ring connecting posts
	MicroCurveBuilder:fillCircle(PEAK_CENTER + Vector3.new(0, 71.5, 0), PEAK_HALF - 3, 0.5, {
		voxelStuds = 0.15,
		color = PALETTE.Cyan,
		material = Enum.Material.Neon,
		parent = parent,
		filled = false,
		collision = false,
		budget = budget,
	})

	WorldBuildBudget:add(budget, 24)
end

-- ──────────────────────────────────────────────
-- Public: Build(model, profile, budget)
-- ──────────────────────────────────────────────

function DeathValleyPeakColonyBuilder:Build(model: Model, profile: WorldBuildConfig.PlaceProfile, budget: WorldBuildBudget.Budget)
	local colony = Instance.new("Model")
	colony.Name = "PeakColony"
	colony:SetAttribute("Planet", "Hellbound")
	colony:SetAttribute("ColonyZone", "SummitPlateau")
	colony.Parent = model

	buildPeakPlateau(colony, budget)
	buildPerimeterRail(colony, budget)
	buildLandingPad(colony, budget)
	buildDomes(colony, budget)
	buildShuttle(colony, budget)
	buildRamp(colony, budget)
	buildSign(colony, budget)
end

return DeathValleyPeakColonyBuilder