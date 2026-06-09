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

local function addBillboard(parent: BasePart, text: string)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(260, 52)
	gui.StudsOffset = Vector3.new(0, 8, 0)
	gui.AlwaysOnTop = false
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(10, 18, 32)
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 19
	label.TextColor3 = Color3.fromRGB(212, 175, 55)
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label
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
			color = palette.Pearl,
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
			palette.Pearl,
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

-- ──────────────────────────────────────────────
-- Transit hub — central station platform
-- ──────────────────────────────────────────────

local function buildTransitHub(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local base = ctx.origin.Position

	-- Elevated platform deck
	local platformY = base.Y + 20
	local platform = addPart(
		district,
		"HubDeck",
		Vector3.new(52, 2, 28),
		CFrame.new(base + Vector3.new(0, platformY, 0)),
		palette.Pearl,
		Enum.Material.SmoothPlastic
	)

	-- Neon edge trim
	for _, xSide in { -27, 27 } do
		addPart(
			district,
			"HubEdge_" .. tostring(xSide),
			Vector3.new(2, 0.8, 28),
			CFrame.new(platform.CFrame * CFrame.new(xSide, 1.4, 0)),
			palette.Cyan,
			Enum.Material.Neon,
			0.05
		)
	end

	-- Roof canopy (glass)
	addPart(
		district,
		"HubCanopy",
		Vector3.new(56, 1, 32),
		CFrame.new(base + Vector3.new(0, platformY + 14, 0)),
		palette.Cyan,
		Enum.Material.Glass,
		0.45
	)

	-- Canopy support arches
	for _, xArch in { -20, 0, 20 } do
		addPart(
			district,
			"CanopyArch_" .. tostring(xArch),
			Vector3.new(1.2, 14, 1.2),
			CFrame.new(base + Vector3.new(xArch, platformY + 7, 14)),
			palette.Pearl,
			Enum.Material.SmoothPlastic
		)
		addPart(
			district,
			"CanopyArch2_" .. tostring(xArch),
			Vector3.new(1.2, 14, 1.2),
			CFrame.new(base + Vector3.new(xArch, platformY + 7, -14)),
			palette.Pearl,
			Enum.Material.SmoothPlastic
		)
	end

	-- Departure board beacon with billboard
	local boardPos = base + Vector3.new(0, platformY + 7, -12)
	local board = addPart(
		district,
		"DepartureBoard",
		Vector3.new(14, 5, 1),
		CFrame.new(boardPos),
		Color3.fromRGB(12, 18, 32),
		Enum.Material.SmoothPlastic
	)
	addBillboard(board, "Sky Rail Plaza · Key 15+")

	local light = Instance.new("PointLight")
	light.Color = palette.Gold
	light.Brightness = 2.2
	light.Range = 50
	light.Parent = board

	WorldBuildBudget:add(ctx.budget, 10)
end

-- ──────────────────────────────────────────────
-- Observation deck on top of hub
-- ──────────────────────────────────────────────

local function buildObservationDeck(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local base = ctx.origin.Position

	local deckY = base.Y + 36
	addPart(
		district,
		"ObsDeck",
		Vector3.new(28, 1.2, 28),
		CFrame.new(base + Vector3.new(0, deckY, 0)),
		palette.Pearl,
		Enum.Material.Slate
	)

	-- Circular railing (8 posts + neon cap rails)
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2
		local r = 13
		local pos = base + Vector3.new(math.cos(angle) * r, deckY + 2.5, math.sin(angle) * r)
		addPart(
			district,
			"ObsPost_" .. i,
			Vector3.new(0.6, 4, 0.6),
			CFrame.new(pos),
			palette.Pearl,
			Enum.Material.SmoothPlastic
		)
	end
	MicroCurveBuilder:fillCircle(base + Vector3.new(0, deckY + 4.8, 0), 13, 0.6, {
		voxelStuds = ctx.profile.VoxelStuds * 0.8,
		color = palette.Cyan,
		material = Enum.Material.Neon,
		parent = district,
		filled = false,
		collision = false,
		budget = ctx.budget,
	})

	-- Central spire beacon
	local spire = addPart(
		district,
		"ObsSpire",
		Vector3.new(2.5, 18, 2.5),
		CFrame.new(base + Vector3.new(0, deckY + 10, 0)),
		palette.Gold,
		Enum.Material.Neon,
		0.06
	)
	local spireLight = Instance.new("PointLight")
	spireLight.Color = palette.Gold
	spireLight.Brightness = 2.8
	spireLight.Range = 70
	spireLight.Parent = spire

	WorldBuildBudget:add(ctx.budget, 8)
end

-- ──────────────────────────────────────────────
-- Ground-level plaza with radial pattern
-- ──────────────────────────────────────────────

local function buildGroundPlaza(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local base = ctx.origin.Position

	-- Outer ring plaza floor
	MicroCurveBuilder:fillCircle(base + Vector3.new(0, 0.6, 0), 56, 3, {
		voxelStuds = ctx.profile.VoxelStuds,
		color = palette.Pearl,
		material = Enum.Material.Slate,
		parent = district,
		filled = false,
		budget = ctx.budget,
	})
	-- Neon accent ring
	MicroCurveBuilder:fillCircle(base + Vector3.new(0, 0.8, 0), 54, 1.2, {
		voxelStuds = ctx.profile.VoxelStuds * 0.85,
		color = palette.Gold,
		material = Enum.Material.Neon,
		parent = district,
		filled = false,
		collision = false,
		budget = ctx.budget,
	})
	-- Inner circle (solid)
	MicroCurveBuilder:fillCircle(base + Vector3.new(0, 0.5, 0), 24, 24, {
		voxelStuds = ctx.profile.VoxelStuds,
		color = palette.Pearl,
		material = Enum.Material.SmoothPlastic,
		parent = district,
		filled = true,
		budget = ctx.budget,
	})

	-- Radial spoke lights
	for i = 0, 5 do
		local angle = (i / 6) * math.pi * 2
		local nearPos = base + Vector3.new(math.cos(angle) * 26, 1.2, math.sin(angle) * 26)
		addPart(
			district,
			"SpokeLight_" .. i,
			Vector3.new(0.8, 0.8, 22),
			CFrame.lookAt(nearPos, nearPos + Vector3.new(math.cos(angle + math.pi / 2), 0, math.sin(angle + math.pi / 2))),
			palette.Cyan,
			Enum.Material.Neon,
			0.12
		)
	end

	WorldBuildBudget:add(ctx.budget, 6)
end

-- ──────────────────────────────────────────────
-- Entry: build()
-- ──────────────────────────────────────────────

function EternityCitySkyRailPlazaLandmark.build(ctx: BuildContext): Folder
	local district = Instance.new("Folder")
	district.Name = "SkyRailPlaza"
	district:SetAttribute("LandmarkArtPass", "v4_skyrail")
	district:SetAttribute("VisualBibleDistrict", "SkyRailPlaza")

	buildGroundPlaza(district, ctx)
	buildPylons(district, ctx)
	buildRailTrack(district, ctx)
	buildTransitHub(district, ctx)
	buildObservationDeck(district, ctx)

	district.Parent = ctx.parent
	return district
end

return EternityCitySkyRailPlazaLandmark
