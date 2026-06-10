--!strict
--[[
	Eternity City art pass #5 — Aurora Mega Mall (Visual Bible: 5-floor glass atrium,
	pillars, walkable ramps, Sky Lounge 50 rooftop, Live Mirror + Prism Key 25).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)
local OrganicCSGBuilder = require(script.Parent.OrganicCSGBuilder)
local PrismKeyPickupKit = require(script.Parent.PrismKeyPickupKit)

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

local FLOOR_HEIGHTS = { 12, 28, 44, 60, 76 } -- 5 floors (ground retail = podium at y=4)
local FLOOR_SIZE = 56
local ATRIUM_HALF = 10 -- half-size of open atrium center
local COLUMN_SPACING = { -22, -12, 0, 12, 22 } -- column positions along x/z

-- ──────────────────────────────────────────────
-- Central spire + podium base (ground retail)
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
		Vector3.new(68, 8, 68),
		ctx.base * CFrame.new(0, 4, 0),
		palette.Pearl,
		Enum.Material.SmoothPlastic
	)

	-- Podium neon base trim
	for _, zSide in { -35, 35 } do
		addPart(
			district,
			"PodiumTrimZ_" .. tostring(zSide),
			Vector3.new(68, 0.6, 2),
			ctx.base * CFrame.new(0, 8.3, zSide),
			palette.Gold,
			Enum.Material.Neon,
			0.05
		)
	end
	for _, xSide in { -35, 35 } do
		addPart(
			district,
			"PodiumTrimX_" .. tostring(xSide),
			Vector3.new(2, 0.6, 68),
			ctx.base * CFrame.new(xSide, 8.3, 0),
			palette.Gold,
			Enum.Material.Neon,
			0.05
		)
	end

	-- Main entrance arch (front side, z = + of base)
	addPart(
		district,
		"MallEntranceArch",
		Vector3.new(18, 10, 0.6),
		ctx.base * CFrame.new(0, 5, 34),
		palette.Cyan,
		Enum.Material.Neon,
		0.12
	)
	WorldBuildBudget:add(ctx.budget, 6)
end

-- ──────────────────────────────────────────────
-- 5-floor mall: glass floor plates + pillars + railings + walkable ramps
-- ──────────────────────────────────────────────

local function buildMallFloors(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local partCount = 0

	for floorIndex, fy in FLOOR_HEIGHTS do
		local fStr = tostring(floorIndex + 1) -- floors labeled 2-6

		-- Glass floor plate (solid — atrium is visual)
		local floorPlate = addPart(
			district,
			"MallFloor_" .. fStr,
			Vector3.new(FLOOR_SIZE, 1, FLOOR_SIZE),
			ctx.base * CFrame.new(0, fy, 0),
			palette.Cyan,
			Enum.Material.Glass,
			0.5
		)
		partCount += 1

		-- Neon trim around outer edge (4 sides)
		local halfFloor = FLOOR_SIZE / 2
		for _, zSide in { -halfFloor + 1, halfFloor - 1 } do
			addPart(
				district,
				"MallFloorTrimZ_" .. fStr .. "_" .. tostring(zSide),
				Vector3.new(FLOOR_SIZE - 2, 0.3, 1),
				ctx.base * CFrame.new(0, fy + 0.5, zSide),
				palette.Gold,
				Enum.Material.Neon,
				0.08
			)
			partCount += 1
		end
		for _, xSide in { -halfFloor + 1, halfFloor - 1 } do
			addPart(
				district,
				"MallFloorTrimX_" .. fStr .. "_" .. tostring(xSide),
				Vector3.new(1, 0.3, FLOOR_SIZE - 2),
				ctx.base * CFrame.new(xSide, fy + 0.5, 0),
				palette.Gold,
				Enum.Material.Neon,
				0.08
			)
			partCount += 1
		end

		-- Pillars: 4 corner + 4 interior around atrium edge
		for _, cx in { -ATRIUM_HALF, ATRIUM_HALF } do
			for _, cz in { -ATRIUM_HALF, ATRIUM_HALF } do
				addPart(
					district,
					"MallColumn_" .. fStr .. "_" .. tostring(cx) .. "_" .. tostring(cz),
					Vector3.new(2, 2, 2),
					ctx.base * CFrame.new(cx, fy + 1, cz),
					palette.Pearl,
					Enum.Material.SmoothPlastic
				)
				partCount += 1
			end
		end

		-- Additional perimeter pillars (4 mid-span)
		for _, cz in { -ATRIUM_HALF, ATRIUM_HALF } do
			addPart(
				district,
				"MallColumnMidZ_" .. fStr .. "_0_" .. tostring(cz),
				Vector3.new(2, 2, 2),
				ctx.base * CFrame.new(0, fy + 1, cz),
				palette.Pearl,
				Enum.Material.SmoothPlastic
			)
			partCount += 1
		end
		for _, cx in { -ATRIUM_HALF, ATRIUM_HALF } do
			addPart(
				district,
				"MallColumnMidX_" .. fStr .. "_" .. tostring(cx) .. "_0",
				Vector3.new(2, 2, 2),
				ctx.base * CFrame.new(cx, fy + 1, 0),
				palette.Pearl,
				Enum.Material.SmoothPlastic
			)
			partCount += 1
		end

		-- Atrium inner railing neon ring (marks open center)
		MicroCurveBuilder:fillCircle(
			(ctx.base * CFrame.new(0, fy + 1.4, 0)).Position,
			ATRIUM_HALF + 1,
			0.5,
			{
				voxelStuds = ctx.profile.VoxelStuds * 0.75,
				color = palette.Cyan,
				material = Enum.Material.Neon,
				parent = district,
				filled = false,
				collision = false,
				budget = ctx.budget,
			}
		)

		-- Walkable ramps between floors (skip last floor — no ramp up)
		if floorIndex < #FLOOR_HEIGHTS then
			local nextFy = FLOOR_HEIGHTS[floorIndex + 1]
			local rampHeight = nextFy - fy
			local rampRun = rampHeight * 3 -- slope ~0.33 → walkable
			local rampHalfWidth = 4
			local rampY = fy + rampHeight / 2

			-- Ramp on north side (z positive) and south side (z negative), alternating per floor
			local rampZ = if floorIndex % 2 == 0 then (FLOOR_SIZE / 2 + rampRun / 2) else -(FLOOR_SIZE / 2 + rampRun / 2)
			local rampAngle = if floorIndex % 2 == 0 then -math.atan(rampHeight / rampRun) else math.atan(rampHeight / rampRun)

			addPart(
				district,
				"MallRamp_" .. fStr .. "_to_" .. tostring(floorIndex + 2),
				Vector3.new(rampRun, 0.6, rampHalfWidth * 2),
				ctx.base * CFrame.new(0, rampY, rampZ) * CFrame.Angles(-rampAngle, 0, 0),
				palette.Pearl,
				Enum.Material.SmoothPlastic
			)
			-- Ramp edge rails (neon strips along ramp sides)
			addPart(
				district,
				"MallRampRail_" .. fStr .. "_L",
				Vector3.new(rampRun - 1, 0.2, 0.3),
				ctx.base * CFrame.new(0, rampY + 1.5, rampZ - rampHalfWidth + 0.5) * CFrame.Angles(-rampAngle, 0, 0),
				palette.Gold,
				Enum.Material.Neon,
				0.05
			)
			addPart(
				district,
				"MallRampRail_" .. fStr .. "_R",
				Vector3.new(rampRun - 1, 0.2, 0.3),
				ctx.base * CFrame.new(0, rampY + 1.5, rampZ + rampHalfWidth - 0.5) * CFrame.Angles(-rampAngle, 0, 0),
				palette.Gold,
				Enum.Material.Neon,
				0.05
			)
			partCount += 3
		end
	end

	WorldBuildBudget:add(ctx.budget, partCount)
end

-- ──────────────────────────────────────────────
-- Sky Lounge 50 — rooftop at ~88 studs (top of 5th floor)
-- ──────────────────────────────────────────────

local SKY_LOUNGE_Y = 88

local function buildSkyLounge50(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local loungeBase = ctx.base * CFrame.new(0, SKY_LOUNGE_Y, 0)

	-- Glass floor deck
	local floor = addPart(
		district,
		"SkyLoungeFloor",
		Vector3.new(58, 0.8, 58),
		loungeBase * CFrame.new(0, 0.4, 0),
		palette.Cyan,
		Enum.Material.Glass,
		0.35
	)
	floor.Reflectance = 0.3

	-- Neon edge trim around lounge perimeter
	for _, zSide in { -30, 30 } do
		addPart(
			district,
			"SkyLoungeTrimZ_" .. tostring(zSide),
			Vector3.new(58, 0.2, 1),
			loungeBase * CFrame.new(0, 0.9, zSide),
			palette.Gold,
			Enum.Material.Neon,
			0.05
		)
	end
	for _, xSide in { -30, 30 } do
		addPart(
			district,
			"SkyLoungeTrimX_" .. tostring(xSide),
			Vector3.new(1, 0.2, 58),
			loungeBase * CFrame.new(xSide, 0.9, 0),
			palette.Gold,
			Enum.Material.Neon,
			0.05
		)
	end

	-- Greybox sofas — 3 seating clusters
	local sofaClusters = {
		{ pos = Vector3.new(12, 1.5, 0), rot = 0 },
		{ pos = Vector3.new(-12, 1.5, 12), rot = math.rad(60) },
		{ pos = Vector3.new(0, 1.5, -12), rot = math.rad(-30) },
	}
	for i, cluster in sofaClusters do
		-- Sofa seat
		addPart(
			district,
			"SkyLoungeSofa_" .. i,
			Vector3.new(8, 1.5, 3),
			loungeBase * CFrame.new(cluster.pos) * CFrame.Angles(0, cluster.rot, 0),
			palette.Pearl,
			Enum.Material.SmoothPlastic
		)
		-- Sofa backrest
		addPart(
			district,
			"SkyLoungeSofaBack_" .. i,
			Vector3.new(8, 3, 0.5),
			loungeBase * CFrame.new(cluster.pos + Vector3.new(0, 2, -1.5)) * CFrame.Angles(0, cluster.rot, 0),
			palette.Twilight,
			Enum.Material.SmoothPlastic
		)
		-- Coffee table
		addPart(
			district,
			"SkyLoungeTable_" .. i,
			Vector3.new(5, 0.5, 3),
			loungeBase * CFrame.new(cluster.pos + Vector3.new(0, 0.5, 3)) * CFrame.Angles(0, cluster.rot, 0),
			palette.Gold,
			Enum.Material.Glass,
			0.3
		)
	end

	-- Central bar counter
	addPart(
		district,
		"SkyLoungeBar",
		Vector3.new(10, 2, 3),
		loungeBase * CFrame.new(0, 1, -8),
		palette.Pearl,
		Enum.Material.SmoothPlastic
	)
	addPart(
		district,
		"SkyLoungeBarTop",
		Vector3.new(10, 0.4, 3.5),
		loungeBase * CFrame.new(0, 2.2, -8),
		palette.Gold,
		Enum.Material.Neon,
		0.1
	)

	-- Outer railing posts (12 posts)
	for i = 0, 11 do
		local angle = (i / 12) * math.pi * 2
		local r = 28
		local postPos = (loungeBase * CFrame.new(math.cos(angle) * r, 2, math.sin(angle) * r)).Position
		addPart(
			district,
			"SkyLoungePost_" .. i,
			Vector3.new(0.6, 4, 0.6),
			CFrame.new(postPos),
			palette.Pearl,
			Enum.Material.SmoothPlastic
		)
	end

	-- Signage
	local sign = addPart(
		district,
		"SkyLoungeSign",
		Vector3.new(28, 5, 1),
		loungeBase * CFrame.new(0, 6, -26),
		palette.Gold,
		Enum.Material.Neon,
		0.08
	)
	addLabel(sign, "Sky Lounge 50")

	-- Point light beacon
	local light = Instance.new("PointLight")
	light.Name = "SkyLoungeLight"
	light.Color = palette.Gold
	light.Brightness = 2.8
	light.Range = 60
	light.Parent = sign

	-- Mini canopy (glass dome suggestion)
	addPart(
		district,
		"SkyLoungeCanopy",
		Vector3.new(62, 0.8, 62),
		loungeBase * CFrame.new(0, 12, 0),
		palette.Pearl,
		Enum.Material.Glass,
		0.55
	)

	WorldBuildBudget:add(ctx.budget, 24)
end

-- ──────────────────────────────────────────────
-- Live Mirror + Prism Key 25 pickup
-- ──────────────────────────────────────────────

local function buildLiveMirror(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local mirrorBase = ctx.base * CFrame.new(0, 4, 30) -- front of podium, near entrance

	-- Reflective mirror surface
	local mirrorPart = addPart(
		district,
		"LiveMirror",
		Vector3.new(10, 12, 1),
		mirrorBase * CFrame.new(0, 6, 0),
		palette.Pearl,
		Enum.Material.Glass,
		0.15
	)
	mirrorPart.Reflectance = 0.6

	-- Mirror frame neon
	addPart(
		district,
		"LiveMirrorFrame",
		Vector3.new(11, 13, 0.5),
		mirrorBase * CFrame.new(0, 6, -0.3),
		palette.Cyan,
		Enum.Material.Neon,
		0.1
	)

	-- Label
	addLabel(mirrorPart, "Live Mirror · Key 25")

	-- Prism Key 25 pickup
	PrismKeyPickupKit.addPickup({
		pickupId = "eternity_mall_live_mirror_key_25",
		keyNumber = 25,
		position = (mirrorBase * CFrame.new(0, 2, -4)).Position,
		parent = district,
	})

	WorldBuildBudget:add(ctx.budget, 3)
end

-- ──────────────────────────────────────────────
-- Entry: build()
-- ──────────────────────────────────────────────

function EternityCityAuroraMegaMallLandmark.build(ctx: BuildContext): Folder
	local district = Instance.new("Folder")
	district.Name = "AuroraMegaMall"
	district:SetAttribute("LandmarkArtPass", "v5_megamall")
	district:SetAttribute("VisualBibleDistrict", "AuroraMegaMall")

	buildMallSpireAndPodium(district, ctx)
	buildMallFloors(district, ctx)
	buildSkyLounge50(district, ctx)
	buildLiveMirror(district, ctx)

	district.Parent = ctx.parent
	return district
end

return EternityCityAuroraMegaMallLandmark