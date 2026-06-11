--!strict
--[[
	Eternity City art pass #2 — Aurora Spire (Visual Bible: needle cluster, geodesic domes, gold trim).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))

local OrganicCSGBuilder = require(script.Parent.OrganicCSGBuilder)
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)
local ArchRibKit = require(ServerStorage:WaitForChild("WorldKits"):WaitForChild("ArchRibKit"))

local EternityCityAuroraSpireLandmark = {}

export type BuildContext = {
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
	origin: CFrame,
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
	gui.Size = UDim2.fromOffset(260, 52)
	gui.StudsOffset = Vector3.new(0, 8, 0)
	gui.AlwaysOnTop = false
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(12, 20, 36)
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 20
	label.TextColor3 = Color3.fromRGB(212, 175, 55)
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label
end

local function buildCentralNeedle(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local base = ctx.origin.Position

	OrganicCSGBuilder:createSpire(base, 128, 16, {
		color = palette.Pearl,
		material = Enum.Material.Marble,
		parent = district,
		name = "AuroraCentralNeedle",
	})

	addPart(
		district,
		"AuroraCap",
		Vector3.new(10, 6, 10),
		CFrame.new(base + Vector3.new(0, 131, 0)),
		palette.Gold,
		Enum.Material.Neon,
		0.1
	)

	local beacon = addPart(
		district,
		"AuroraBeacon",
		Vector3.new(5, 28, 5),
		CFrame.new(base + Vector3.new(0, 18, 0)),
		palette.Cyan,
		Enum.Material.Neon,
		0.08
	)
	addBillboard(beacon, "Aurora Spire · Eternity City")
	local light = Instance.new("PointLight")
	light.Color = palette.Cyan
	light.Brightness = 2.4
	light.Range = 90
	light.Parent = beacon

	WorldBuildBudget:add(ctx.budget, 3)
end

local function buildSatelliteSpires(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	for i = 0, 5 do
		local angle = (i / 6) * math.pi * 2
		local radius = if i == 0 then 0 else 28 + (i % 3) * 8
		local height = 90 + (i % 4) * 18
		local pos = ctx.origin * CFrame.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		OrganicCSGBuilder:createSpire(pos.Position, height, 12 + (i % 3) * 2, {
			color = if i % 2 == 0 then palette.Pearl else palette.Steel,
			material = Enum.Material.Marble,
			parent = district,
			name = "Spire_" .. i,
		})
		if i % 2 == 0 then
			OrganicCSGBuilder:createDome(pos.Position + Vector3.new(0, height * 0.35, 0), 14 + i, {
				color = palette.Teal,
				parent = district,
				name = "GeoDome_" .. i,
			})
		end
		WorldBuildBudget:add(ctx.budget, 2)
	end
end

local function buildAuroraRibbons(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local center = ctx.origin.Position + Vector3.new(0, 52, 0)

	for ring = 1, 3 do
		local ringRadius = 22 + ring * 8
		local ringY = center.Y + (ring - 2) * 14
		MicroCurveBuilder:fillCircle(center + Vector3.new(0, ringY - center.Y, 0), ringRadius, 1.6, {
			voxelStuds = ctx.profile.VoxelStuds * 0.9,
			color = if ring % 2 == 0 then palette.Cyan else palette.Amber,
			material = Enum.Material.Neon,
			parent = district,
			filled = false,
			collision = false,
			budget = ctx.budget,
		})
	end

	OrganicCSGBuilder:createGlassBand((ctx.origin * CFrame.new(0, 45, 0)).Position, 36, 8, {
		parent = district,
		color = palette.Cyan,
	})
	WorldBuildBudget:add(ctx.budget, 2)
end

local function buildBasePlaza(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local base = ctx.origin.Position

	MicroCurveBuilder:fillCircle(base + Vector3.new(0, 0.8, 0), 44, 2.2, {
		voxelStuds = ctx.profile.VoxelStuds,
		color = palette.Pearl,
		material = Enum.Material.Marble,
		parent = district,
		filled = false,
		budget = ctx.budget,
	})
	MicroCurveBuilder:fillCircle(base + Vector3.new(0, 1, 0), 42, 1.4, {
		voxelStuds = ctx.profile.VoxelStuds * 0.85,
		color = palette.Gold,
		material = Enum.Material.Neon,
		parent = district,
		filled = false,
		collision = false,
		budget = ctx.budget,
	})

	ArchRibKit:CreateAll(ctx.origin * CFrame.new(0, 0, 25), 22, district, ctx.budget, {
		palette = {
			Pearl = Color3.fromRGB(90, 105, 125),
			PearlAlt = Color3.fromRGB(55, 68, 88),
			Gold = palette.Gold,
			Cyan = palette.Cyan,
		}
	})
end

function EternityCityAuroraSpireLandmark.build(ctx: BuildContext): Folder
	local district = Instance.new("Folder")
	district.Name = "AuroraSpireDistrict"
	district:SetAttribute("LandmarkArtPass", "v2_aurora_spire")
	district:SetAttribute("VisualBibleDistrict", "AuroraSpire")

	buildBasePlaza(district, ctx)
	buildSatelliteSpires(district, ctx)
	buildCentralNeedle(district, ctx)
	buildAuroraRibbons(district, ctx)

	district.Parent = ctx.parent
	return district
end

return EternityCityAuroraSpireLandmark
