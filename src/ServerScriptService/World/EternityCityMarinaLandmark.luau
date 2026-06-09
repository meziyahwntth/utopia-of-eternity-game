--!strict
--[[
	Eternity City art pass #1 — Marina Ring (Visual Bible: curved dock segments, pearl hulls, cyan water edge).
	Keeps MarinaRing district folder + gate key 11 zone id.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))

local EternityCityMarinaLandmark = {}

export type BuildContext = {
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: any,
	center: Vector3,
}

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
	gui.Size = UDim2.fromOffset(220, 48)
	gui.StudsOffset = Vector3.new(0, 6, 0)
	gui.AlwaysOnTop = false
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(15, 25, 40)
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextColor3 = Color3.fromRGB(0, 229, 255)
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
end

local function buildDockArc(marina: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local segmentCount = 10
	local innerR = 42
	local outerR = 58
	local baseY = 2.2

	for i = 0, segmentCount - 1 do
		local t0 = (i / segmentCount) * math.pi * 0.85 + math.pi * 0.575
		local t1 = ((i + 1) / segmentCount) * math.pi * 0.85 + math.pi * 0.575
		local mid = (t0 + t1) * 0.5
		local midR = (innerR + outerR) * 0.5
		local pos = ctx.center + Vector3.new(math.cos(mid) * midR, baseY, math.sin(mid) * midR)
		local tangent = Vector3.new(-math.sin(mid), 0, math.cos(mid))
		local width = (outerR - innerR) + 4
		local length = (outerR + innerR) * (t1 - t0) * 0.35 + 6

		addPart(
			marina,
			"DockSegment_" .. i,
			Vector3.new(width, 1.2, length),
			CFrame.lookAt(pos, pos + tangent),
			palette.Pearl,
			Enum.Material.SmoothPlastic
		)

		local railPos = pos + Vector3.new(0, 1.1, 0)
		addPart(
			marina,
			"DockRail_" .. i,
			Vector3.new(0.35, 1.4, length * 0.92),
			CFrame.lookAt(railPos, railPos + tangent),
			palette.Gold,
			Enum.Material.Neon,
			0.08
		)
	end
end

local function buildWaterBasin(marina: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local water = addPart(
		marina,
		"MarinaBasin",
		Vector3.new(96, 1.5, 96),
		CFrame.new(ctx.center + Vector3.new(0, 0.2, 0)),
		palette.Cyan,
		Enum.Material.Glass,
		0.35
	)
	water.CanCollide = false

	MicroCurveBuilder:fillCircle(ctx.center + Vector3.new(0, 0.55, 0), 50, 1.2, {
		voxelStuds = ctx.profile.VoxelStuds,
		color = palette.Cyan,
		material = Enum.Material.Neon,
		parent = marina,
		filled = false,
		collision = false,
		budget = ctx.budget,
	})
end

local function buildBoardwalk(marina: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	MicroCurveBuilder:fillCircle(ctx.center + Vector3.new(0, 1.4, 0), 62, 2.4, {
		voxelStuds = ctx.profile.VoxelStuds,
		color = palette.Pearl,
		material = Enum.Material.Slate,
		parent = marina,
		filled = false,
		budget = ctx.budget,
	})
	MicroCurveBuilder:fillCircle(ctx.center + Vector3.new(0, 1.55, 0), 60, 1.8, {
		voxelStuds = ctx.profile.VoxelStuds * 0.85,
		color = palette.Gold,
		material = Enum.Material.Neon,
		parent = marina,
		filled = false,
		collision = false,
		budget = ctx.budget,
	})
end

local function buildYachtSilhouettes(marina: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local slots = {
		{ angle = math.rad(215), radius = 46 },
		{ angle = math.rad(245), radius = 50 },
		{ angle = math.rad(275), radius = 47 },
	}

	for index, slot in ipairs(slots) do
		local pos = ctx.center + Vector3.new(math.cos(slot.angle) * slot.radius, 2.8, math.sin(slot.angle) * slot.radius)
		local hull = addPart(
			marina,
			"YachtHull_" .. index,
			Vector3.new(14, 4, 28),
			CFrame.new(pos) * CFrame.Angles(0, slot.angle + math.pi / 2, 0),
			palette.Pearl,
			Enum.Material.SmoothPlastic
		)
		addPart(
			marina,
			"YachtCabin_" .. index,
			Vector3.new(8, 5, 10),
			hull.CFrame * CFrame.new(0, 3.5, -4),
			Color3.fromRGB(230, 235, 245),
			Enum.Material.Glass,
			0.25
		)
		local light = Instance.new("PointLight")
		light.Color = palette.Cyan
		light.Brightness = 1.2
		light.Range = 18
		light.Parent = hull
	end
end

local function buildLandmarkBeacon(marina: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local beaconPos = ctx.center + Vector3.new(0, 0, -68)
	local pillar = addPart(
		marina,
		"MarinaBeacon",
		Vector3.new(4, 22, 4),
		CFrame.new(beaconPos + Vector3.new(0, 11, 0)),
		palette.Gold,
		Enum.Material.Neon,
		0.05
	)
	addBillboard(pillar, "Marina Ring · Keys 11+")
	local light = Instance.new("PointLight")
	light.Color = palette.Amber
	light.Brightness = 2
	light.Range = 40
	light.Parent = pillar
end

function EternityCityMarinaLandmark.build(ctx: BuildContext): Folder
	local marina = Instance.new("Folder")
	marina.Name = "MarinaRing"
	marina:SetAttribute("LandmarkArtPass", "v1_marina")
	marina:SetAttribute("VisualBibleDistrict", "MarinaRing")

	buildWaterBasin(marina, ctx)
	buildBoardwalk(marina, ctx)
	buildDockArc(marina, ctx)
	buildYachtSilhouettes(marina, ctx)
	buildLandmarkBeacon(marina, ctx)

	marina.Parent = ctx.parent
	return marina
end

return EternityCityMarinaLandmark
