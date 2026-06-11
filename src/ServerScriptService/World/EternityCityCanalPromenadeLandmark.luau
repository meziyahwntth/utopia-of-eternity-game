--!strict
--[[
	Eternity City art pass #3 — Canal Promenade (Visual Bible: S-curve water + boardwalk, key 11+).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)

local EternityCityCanalPromenadeLandmark = {}

export type BuildContext = {
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
	pathOffset: Vector3?,
}

local SAMPLE_COUNT = 24

local function samplePath(t: number, offset: Vector3): Vector3
	local x = offset.X + 20 + t * 140
	local z = offset.Z + 60 + math.sin(t * math.pi * 2.5) * 16
	local y = offset.Y + 1.2
	return Vector3.new(x, y, z)
end

local function buildBoardwalkPoints(offset: Vector3): { Vector3 }
	local points: { Vector3 } = {}
	for i = 0, SAMPLE_COUNT do
		table.insert(points, samplePath(i / SAMPLE_COUNT, offset))
	end
	return points
end

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
	gui.Size = UDim2.fromOffset(240, 48)
	gui.StudsOffset = Vector3.new(0, 7, 0)
	gui.AlwaysOnTop = false
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.32
	label.BackgroundColor3 = Color3.fromRGB(12, 22, 38)
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextColor3 = Color3.fromRGB(0, 229, 255)
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
end

local function pathOffset(ctx: BuildContext): Vector3
	return if ctx.pathOffset then ctx.pathOffset else Vector3.new(0, 0, 0)
end

local function buildCanalWater(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local offset = pathOffset(ctx)
	for i = 0, SAMPLE_COUNT - 1 do
		local t0 = i / SAMPLE_COUNT
		local t1 = (i + 1) / SAMPLE_COUNT
		local p0 = samplePath(t0, offset)
		local p1 = samplePath(t1, offset)
		local mid = (p0 + p1) * 0.5
		local delta = p1 - p0
		local length = delta.Magnitude + 2
		local segment = addPart(
			district,
			"CanalSegment_" .. i,
			Vector3.new(length, 1.8, 38),
			CFrame.lookAt(mid + Vector3.new(0, -0.7, 0), mid + delta),
			palette.Cyan,
			Enum.Material.Glass,
			0.38
		)
		segment.CanCollide = false
	end
	WorldBuildBudget:add(ctx.budget, SAMPLE_COUNT)
end

local function buildBoardwalk(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local points = buildBoardwalkPoints(pathOffset(ctx))
	MicroCurveBuilder:fillArc(points, 3, {
		voxelStuds = ctx.profile.VoxelStuds,
		color = palette.Pearl,
		material = Enum.Material.Marble,
		parent = district,
		collision = true,
		budget = ctx.budget,
	})
	MicroCurveBuilder:fillArc(points, 0.8, {
		voxelStuds = ctx.profile.VoxelStuds,
		color = palette.Cyan,
		material = Enum.Material.Neon,
		parent = district,
		collision = false,
		budget = ctx.budget,
	})
end

local function buildLanterns(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local offset = pathOffset(ctx)
	for i = 0, SAMPLE_COUNT, 3 do
		local pos = samplePath(i / SAMPLE_COUNT, offset) + Vector3.new(0, 2.5, 5)
		local post = addPart(
			district,
			"LanternPost_" .. i,
			Vector3.new(0.6, 5, 0.6),
			CFrame.new(pos),
			palette.Gold,
			Enum.Material.Metal,
			0.05
		)
		local lamp = addPart(
			district,
			"LanternGlow_" .. i,
			Vector3.new(1.8, 1.8, 1.8),
			CFrame.new(pos + Vector3.new(0, 3.2, 0)),
			palette.Amber,
			Enum.Material.Neon,
			0.15
		)
		local light = Instance.new("PointLight")
		light.Color = palette.Amber
		light.Brightness = 1.4
		light.Range = 16
		light.Parent = lamp
		WorldBuildBudget:add(ctx.budget, 2)
	end
end

local function buildGateArch(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local gatePos = samplePath(0, pathOffset(ctx)) + Vector3.new(0, 0, -8)
	local left = addPart(
		district,
		"CanalGateLeft",
		Vector3.new(2, 14, 2),
		CFrame.new(gatePos + Vector3.new(-12, 7, 0)),
		palette.Pearl,
		Enum.Material.Marble
	)
	local right = addPart(
		district,
		"CanalGateRight",
		Vector3.new(2, 14, 2),
		CFrame.new(gatePos + Vector3.new(12, 7, 0)),
		palette.Pearl,
		Enum.Material.Marble
	)
	local lintel = addPart(
		district,
		"CanalGateLintel",
		Vector3.new(28, 2, 3),
		CFrame.new(gatePos + Vector3.new(0, 14.5, 0)),
		palette.Gold,
		Enum.Material.Neon,
		0.08
	)
	addBillboard(lintel, "Canal Promenade · Key 11+")
	local light = Instance.new("PointLight")
	light.Color = palette.Cyan
	light.Brightness = 2
	light.Range = 32
	light.Parent = lintel
	WorldBuildBudget:add(ctx.budget, 3)
end

local function buildBridges(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local offset = pathOffset(ctx)
	for _, t in { 0.35, 0.72 } do
		local center = samplePath(t, offset)
		local deck = addPart(
			district,
			"CanalBridge_" .. tostring(math.floor(t * 100)),
			Vector3.new(18, 1.2, 8),
			CFrame.new(center + Vector3.new(0, 4.5, 0)),
			palette.Pearl,
			Enum.Material.Marble
		)
		addPart(
			district,
			"BridgeRail_" .. tostring(math.floor(t * 100)),
			Vector3.new(18, 0.4, 0.4),
			deck.CFrame * CFrame.new(0, 1.2, 3.6),
			palette.Gold,
			Enum.Material.Neon,
			0.1
		)
		WorldBuildBudget:add(ctx.budget, 2)
	end
end

function EternityCityCanalPromenadeLandmark.build(ctx: BuildContext): Folder
	local district = Instance.new("Folder")
	district.Name = "CanalPromenade"
	district:SetAttribute("LandmarkArtPass", "v3_canal")
	district:SetAttribute("VisualBibleDistrict", "CanalPromenade")

	buildCanalWater(district, ctx)
	buildBoardwalk(district, ctx)
	buildLanterns(district, ctx)
	buildGateArch(district, ctx)
	buildBridges(district, ctx)

	district.Parent = ctx.parent
	return district
end

return EternityCityCanalPromenadeLandmark
