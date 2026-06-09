--!strict
--[[
	Eternity City art pass #6 — Twilight Overpass
	(Visual Bible: dramatic event arch, cyan neon ring, suspended walkway,
	 amber lantern corridor, Key 10+ zone).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local function addBillboard(parent: BasePart, text: string)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(250, 50)
	gui.StudsOffset = Vector3.new(0, 7, 0)
	gui.AlwaysOnTop = false
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(10, 16, 30)
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextColor3 = Color3.fromRGB(255, 180, 60)
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
end

-- ──────────────────────────────────────────────
-- Main event arch + cyan neon ring
-- ──────────────────────────────────────────────

local function buildEventArch(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local archPos = ctx.origin

	OrganicCSGBuilder:createArch(archPos, 50, 22, 3, {
		color = palette.Pearl,
		parent = district,
		name = "EventArch",
	})

	-- Cyan neon ring at arch apex
	MicroCurveBuilder:fillCircle(
		(archPos * CFrame.new(0, 12, 0)).Position,
		28,
		12,
		{
			voxelStuds = ctx.profile.VoxelStuds,
			color = palette.Cyan,
			material = Enum.Material.Neon,
			parent = district,
			filled = false,
			budget = ctx.budget,
		}
	)

	-- Keystone beacon with billboard
	local keystone = addPart(
		district,
		"ArchKeystone",
		Vector3.new(6, 4, 3),
		archPos * CFrame.new(0, 22, 0),
		palette.Gold,
		Enum.Material.Neon,
		0.08
	)
	addBillboard(keystone, "Twilight Overpass · Key 10+")

	local light = Instance.new("PointLight")
	light.Color = palette.Amber
	light.Brightness = 2.4
	light.Range = 60
	light.Parent = keystone

	WorldBuildBudget:add(ctx.budget, 4)
end

-- ──────────────────────────────────────────────
-- Suspended walkway through the arch
-- ──────────────────────────────────────────────

local function buildSuspendedWalkway(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local center = ctx.origin.Position

	-- Walkway deck
	addPart(
		district,
		"OverpassDeck",
		Vector3.new(8, 1.2, 70),
		CFrame.new(center + Vector3.new(0, 12, 0)),
		palette.Pearl,
		Enum.Material.SmoothPlastic
	)

	-- Neon edge strips
	for _, xSide in { -4.6, 4.6 } do
		addPart(
			district,
			"DeckEdge_" .. tostring(xSide),
			Vector3.new(0.6, 0.6, 70),
			CFrame.new(center + Vector3.new(xSide, 13, 0)),
			palette.Amber,
			Enum.Material.Neon,
			0.06
		)
	end

	-- Suspension cables (4 pairs)
	for i = -1, 1, 2 do
		for j = -15, 15, 10 do
			addPart(
				district,
				"SuspCable_" .. i .. "_" .. j,
				Vector3.new(0.4, 12, 0.4),
				CFrame.new(center + Vector3.new(i * 4, 18, j)),
				palette.Pearl,
				Enum.Material.Metal
			)
		end
	end

	WorldBuildBudget:add(ctx.budget, 6)
end

-- ──────────────────────────────────────────────
-- Amber lantern corridor along approach path
-- ──────────────────────────────────────────────

local function buildLanternCorridor(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local center = ctx.origin.Position

	for i = -3, 3 do
		local zOff = i * 12
		for _, xSide in { -30, 30 } do
			local post = addPart(
				district,
				"OverpassPost_" .. i .. "_" .. xSide,
				Vector3.new(0.8, 14, 0.8),
				CFrame.new(center + Vector3.new(xSide, 7, zOff)),
				palette.Pearl,
				Enum.Material.SmoothPlastic
			)
			local lamp = addPart(
				district,
				"OverpassLamp_" .. i .. "_" .. xSide,
				Vector3.new(2.2, 2.2, 2.2),
				CFrame.new(center + Vector3.new(xSide, 15, zOff)),
				palette.Amber,
				Enum.Material.Neon,
				0.12
			)
			local light = Instance.new("PointLight")
			light.Color = palette.Amber
			light.Brightness = 1.6
			light.Range = 20
			light.Parent = lamp
			WorldBuildBudget:add(ctx.budget, 2)
		end
	end
end

-- ──────────────────────────────────────────────
-- Entry
-- ──────────────────────────────────────────────

function EternityCityTwilightOverpassLandmark.build(ctx: BuildContext): Folder
	local district = Instance.new("Folder")
	district.Name = "TwilightOverpass"
	district:SetAttribute("LandmarkArtPass", "v6_twilight_overpass")
	district:SetAttribute("VisualBibleDistrict", "TwilightOverpass")

	buildEventArch(district, ctx)
	buildSuspendedWalkway(district, ctx)
	buildLanternCorridor(district, ctx)

	district.Parent = ctx.parent
	return district
end

return EternityCityTwilightOverpassLandmark
