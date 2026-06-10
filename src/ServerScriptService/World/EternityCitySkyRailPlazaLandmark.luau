--!strict
--[[
	Eternity City art pass #4 — Sky Rail Plaza (Visual Bible: elevated maglev rail loop,
	pearl-and-gold transit hub, observation deck, neon undercarriage lighting).
	Key 15+ zone. Replaces the inline stub in EternityCityWorldBuilder.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)

local EternityCitySkyRailPlazaLandmark = {}

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
-- Rail loop (elevated maglev track)
-- ──────────────────────────────────────────────

local TRACK_SAMPLES = 32

local function sampleTrack(t: number, origin: CFrame): Vector3
	local x = math.cos(t * math.pi * 1.2) * 85
	local z = -40 + math.sin(t * math.pi * 1.1) * 55
	local y = 25 + math.sin(t * math.pi * 2) * 10
	return (origin * CFrame.new(x, y, z)).Position
end

local function buildRailTrack(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette

	-- Two parallel rails with neon strip
	for _, lateralOffset in { -2, 2 } do
		local points: { Vector3 } = {}
		for i = 0, TRACK_SAMPLES do
			local p = sampleTrack(i / TRACK_SAMPLES, ctx.origin)
			-- Lateral offset perpendicular to travel direction
			local tNext = math.min((i + 1) / TRACK_SAMPLES, 1)
			local pNext = sampleTrack(tNext, ctx.origin)
			local forward = (pNext - p)
			local mag = forward.Magnitude
			local fwd = if mag > 0.001 then forward / mag else Vector3.new(1, 0, 0)
			local right = fwd:Cross(Vector3.new(0, 1, 0)).Unit
			table.insert(points, p + right * lateralOffset)
		end
		MicroCurveBuilder:fillArc(points, 1.8, {
			voxelStuds = ctx.profile.VoxelStuds * 1.1,
			color = palette.Steel,
			material = Enum.Material.SmoothPlastic,
			parent = district,
			collision = true,
			budget = ctx.budget,
		})
		-- Neon undercarriage strip
		local neonPoints: { Vector3 } = {}
		for _, p in points do
			table.insert(neonPoints, p + Vector3.new(0, -1.2, 0))
		end
		MicroCurveBuilder:fillArc(neonPoints, 0.5, {
			voxelStuds = ctx.profile.VoxelStuds,
			color = palette.Gold,
			material = Enum.Material.Neon,
			parent = district,
			collision = false,
			budget = ctx.budget,
		})
	end

	WorldBuildBudget:add(ctx.budget, TRACK_SAMPLES * 2)
end

-- ──────────────────────────────────────────────
-- Support pylons below the rail loop
-- ──────────────────────────────────────────────

local function buildPylons(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local pylonStep = 4 -- every 4 samples

	for i = 0, TRACK_SAMPLES - 1, pylonStep do
		local apex = sampleTrack(i / TRACK_SAMPLES, ctx.origin)
		-- Pylon drops to ground (y=0)
		local groundY = (ctx.origin * CFrame.new(0, 0, 0)).Position.Y
		local height = apex.Y - groundY
		if height < 4 then continue end

		local midPos = Vector3.new(apex.X, groundY + height / 2, apex.Z)
		addPart(
			district,
			"Pylon_" .. i,
			Vector3.new(2.5, height, 2.5),
			CFrame.new(midPos),
			palette.Slate,
			Enum.Material.SmoothPlastic
		)
		-- Pylon cap neon ring
		addPart(
			district,
			"PylonCap_" .. i,
			Vector3.new(5, 1.2, 5),
			CFrame.new(apex + Vector3.new(0, 0.6, 0)),
			palette.Gold,
			Enum.Material.Neon,
			0.1
		)
		WorldBuildBudget:add(ctx.budget, 2)
	end
end

-- ReflectivePlaza — ลานสะท้อน ~90 studs, Glass Reflectance สูง, Neon edge trim
-- ──────────────────────────────────────────────

local function buildReflectivePlaza(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local base = ctx.origin.Position

	-- Main reflective surface
	local plaza = addPart(
		district,
		"ReflectivePad",
		Vector3.new(90, 0.5, 90),
		CFrame.new(base + Vector3.new(0, 0.4, 0)),
		palette.Midnight,
		Enum.Material.Glass,
		0.25
	)
	plaza.Reflectance = 0.4

	-- Neon edge trim (4 sides)
	local edgeLength = 90
	local halfEdge = edgeLength / 2
	local edgeSides = {
		{ pos = Vector3.new(0, 0.65, -halfEdge + 1), size = Vector3.new(edgeLength - 2, 0.3, 1) },
		{ pos = Vector3.new(0, 0.65, halfEdge - 1), size = Vector3.new(edgeLength - 2, 0.3, 1) },
		{ pos = Vector3.new(-halfEdge + 1, 0.65, 0), size = Vector3.new(1, 0.3, edgeLength - 2) },
		{ pos = Vector3.new(halfEdge - 1, 0.65, 0), size = Vector3.new(1, 0.3, edgeLength - 2) },
	}
	for i, side in edgeSides do
		addPart(
			district,
			"PlazaTrim_" .. i,
			side.size,
			CFrame.new(base + side.pos),
			palette.Cyan,
			Enum.Material.Neon,
			0.05
		)
	end

	-- Radial glow lanes from center
	for i = -2, 2 do
		addPart(
			district,
			"GlowLane_" .. i,
			Vector3.new(80, 0.2, 1.2),
			CFrame.new(base + Vector3.new(i * 8, 0.55, 0)),
			palette.Gold,
			Enum.Material.Neon,
			0.15
		)
	end

	-- Inner accent circle
	MicroCurveBuilder:fillCircle(base + Vector3.new(0, 0.65, 0), 18, 1.2, {
		voxelStuds = ctx.profile.VoxelStuds * 0.85,
		color = palette.Gold,
		material = Enum.Material.Neon,
		parent = district,
		filled = false,
		collision = false,
		budget = ctx.budget,
	})

	WorldBuildBudget:add(ctx.budget, 11)
end

-- ──────────────────────────────────────────────
-- Transit stops — 2 แห่งบนราง: ชานชาลา + canopy + ป้าย + ProximityPrompt
-- ──────────────────────────────────────────────

local STOP_INDICES = { 5, 16 } -- roughly opposing sides of the 32-sample loop

local function buildTransitStops(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette

	for _, si in STOP_INDICES do
		local t = si / TRACK_SAMPLES
		local trackPos = sampleTrack(t, ctx.origin)

		-- Platform deck
		local platform = addPart(
			district,
			"TransitPlatform_" .. si,
			Vector3.new(12, 1, 8),
			CFrame.new(trackPos + Vector3.new(0, -1, 0)),
			palette.Slate,
			Enum.Material.SmoothPlastic
		)
		platform:SetAttribute("SkyRailStop", true)

		-- Canopy
		local canopy = addPart(
			district,
			"TransitCanopy_" .. si,
			Vector3.new(14, 0.5, 10),
			CFrame.new(trackPos + Vector3.new(0, 6, 0)),
			palette.Cyan,
			Enum.Material.Glass,
			0.4
		)

		-- Sign pillar
		local signPart = addPart(
			district,
			"StopSign_" .. si,
			Vector3.new(1.5, 4, 1.5),
			CFrame.new(trackPos + Vector3.new(0, 2, 4)),
			palette.Gold,
			Enum.Material.SmoothPlastic
		)
		addLabel(signPart, "Sky Rail Stop " .. si)

		-- ProximityPrompt on platform
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "BoardSkyRail"
		prompt.ActionText = "Board Sky Rail"
		prompt.ObjectText = "Transit Stop"
		prompt.MaxActivationDistance = 10
		prompt.Parent = platform

		-- Light beacon
		local beacon = addPart(
			district,
			"StopBeacon_" .. si,
			Vector3.new(1, 1, 1),
			CFrame.new(trackPos + Vector3.new(0, 8, 0)),
			palette.Gold,
			Enum.Material.Neon,
			0.08
		)
		local stopLight = Instance.new("PointLight")
		stopLight.Color = palette.Cyan
		stopLight.Brightness = 1.5
		stopLight.Range = 30
		stopLight.Parent = beacon

		WorldBuildBudget:add(ctx.budget, 6)
	end
end

-- ──────────────────────────────────────────────
-- Entry: build()
-- ──────────────────────────────────────────────

function EternityCitySkyRailPlazaLandmark.build(ctx: BuildContext): Folder
	local district = Instance.new("Folder")
	district.Name = "SkyRailPlaza"
	district:SetAttribute("LandmarkArtPass", "v4_skyrail")
	district:SetAttribute("VisualBibleDistrict", "SkyRailPlaza")

	buildReflectivePlaza(district, ctx)
	buildPylons(district, ctx)
	buildRailTrack(district, ctx)
	buildTransitStops(district, ctx)

	district.Parent = ctx.parent
	return district
end

return EternityCitySkyRailPlazaLandmark
