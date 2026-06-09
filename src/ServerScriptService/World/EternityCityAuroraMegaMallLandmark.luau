--!strict
--[[
	Eternity City art pass #5 — Aurora Mega Mall + Sky Lounge Floor 50
	(Visual Bible: 160-stud pearl spire, retail podium, glass atrium floors,
	 Sky Lounge at y=155 with panoramic neon ring, Key 20+ VIP zone).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)
local OrganicCSGBuilder = require(script.Parent.OrganicCSGBuilder)

local EternityCityAuroraMegaMallLandmark = {}

export type BuildContext = {
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
	base: CFrame,
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

-- ──────────────────────────────────────────────
-- Central spire + podium base
-- ──────────────────────────────────────────────

local function buildMallSpireAndPodium(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette

	OrganicCSGBuilder:createSpire(ctx.base.Position, 160, 28, {
		color = palette.Pearl,
		material = Enum.Material.SmoothPlastic,
		parent = district,
		name = "MallSpire",
	})

	-- Podium (ground retail level)
	addPart(
		district,
		"MallPodium",
		Vector3.new(80, 8, 80),
		ctx.base * CFrame.new(0, 4, 0),
		palette.Pearl,
		Enum.Material.SmoothPlastic
	)

	-- Podium neon base trim
	for _, zSide in { -41, 41 } do
		addPart(
			district,
			"PodiumTrim_" .. tostring(zSide),
			Vector3.new(80, 0.6, 2),
			ctx.base * CFrame.new(0, 8.3, zSide),
			palette.Gold,
			Enum.Material.Neon,
			0.05
		)
	end
	for _, xSide in { -41, 41 } do
		addPart(
			district,
			"PodiumTrimX_" .. tostring(xSide),
			Vector3.new(2, 0.6, 80),
			ctx.base * CFrame.new(xSide, 8.3, 0),
			palette.Gold,
			Enum.Material.Neon,
			0.05
		)
	end

	WorldBuildBudget:add(ctx.budget, 5)
end

-- ──────────────────────────────────────────────
-- Retail atrium floors (levels 1–4)
-- ──────────────────────────────────────────────

local function buildAtriumFloors(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local floorHeights = { 20, 40, 60, 80 }

	for _, fy in floorHeights do
		-- Glass floor panel
		local floor = addPart(
			district,
			"AtriumFloor_" .. fy,
			Vector3.new(56, 1, 56),
			ctx.base * CFrame.new(0, fy, 0),
			palette.Cyan,
			Enum.Material.Glass,
			0.55
		)
		floor.CanCollide = true

		-- Balcony rail neon strip
		MicroCurveBuilder:fillCircle(
			(ctx.base * CFrame.new(0, fy + 1.2, 0)).Position,
			29,
			0.7,
			{
				voxelStuds = ctx.profile.VoxelStuds * 0.8,
				color = palette.Gold,
				material = Enum.Material.Neon,
				parent = district,
				filled = false,
				collision = false,
				budget = ctx.budget,
			}
		)
		WorldBuildBudget:add(ctx.budget, 1)
	end
end

-- ──────────────────────────────────────────────
-- Sky Lounge — Floor 50 (y=155, Key 20+)
-- ──────────────────────────────────────────────

local function buildSkyLounge(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local loungeBase = ctx.base * CFrame.new(0, 155, 0)

	-- Main glass floor
	local floor = addPart(
		district,
		"LoungeFloor",
		Vector3.new(70, 1, 70),
		loungeBase,
		palette.Cyan,
		Enum.Material.Glass,
		0.4
	)
	floor:SetAttribute("SelfieZone", true)
	floor:SetAttribute("MinPrismKeys", 20)

	-- Outer railing posts (12 posts)
	for i = 0, 11 do
		local angle = (i / 12) * math.pi * 2
		local r = 34
		local postPos = (loungeBase * CFrame.new(math.cos(angle) * r, 2, math.sin(angle) * r)).Position
		addPart(district, "LoungePost_" .. i, Vector3.new(0.6, 4, 0.6), CFrame.new(postPos), palette.Pearl, Enum.Material.SmoothPlastic)
	end

	-- Panoramic neon ring
	MicroCurveBuilder:fillCircle(
		(loungeBase * CFrame.new(0, 3.8, 0)).Position,
		34,
		0.8,
		{
			voxelStuds = ctx.profile.VoxelStuds * 0.85,
			color = palette.Cyan,
			material = Enum.Material.Neon,
			parent = district,
			filled = false,
			collision = false,
			budget = ctx.budget,
		}
	)

	-- Canopy dome (glass hemisphere suggestion via flat panel)
	addPart(
		district,
		"LoungeCanopy",
		Vector3.new(74, 1, 74),
		loungeBase * CFrame.new(0, 16, 0),
		palette.Pearl,
		Enum.Material.Glass,
		0.6
	)

	-- Signage board
	local sign = addPart(
		district,
		"SkyLoungeSign",
		Vector3.new(40, 6, 1),
		loungeBase * CFrame.new(0, 7, -30),
		palette.Gold,
		Enum.Material.Neon,
		0
	)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = "Sky Lounge · Floor 50 · Keys 20+"
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Parent = gui

	-- VIP point light
	local light = Instance.new("PointLight")
	light.Color = palette.Cyan
	light.Brightness = 2.6
	light.Range = 80
	light.Parent = sign

	WorldBuildBudget:add(ctx.budget, 6)
end

-- ──────────────────────────────────────────────
-- Entry
-- ──────────────────────────────────────────────

function EternityCityAuroraMegaMallLandmark.build(ctx: BuildContext): Folder
	local district = Instance.new("Folder")
	district.Name = "AuroraMegaMall"
	district:SetAttribute("LandmarkArtPass", "v5_megamall")
	district:SetAttribute("VisualBibleDistrict", "AuroraMegaMall")

	buildMallSpireAndPodium(district, ctx)
	buildAtriumFloors(district, ctx)
	buildSkyLounge(district, ctx)

	district.Parent = ctx.parent
	return district
end

return EternityCityAuroraMegaMallLandmark
