--!strict
--[[
	Eternity City art pass #7 — Marina Showroom Strip (Visual Bible: glass showrooms,
	vehicle pedestals, pier railings + lamps).
	Builds art around existing CommerceDistrictBuilder kiosks — does not touch commerce wiring.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)

local EternityCityMarinaShowroomLandmark = {}

export type BuildContext = {
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
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
-- Pier positions
-- ──────────────────────────────────────────────

local PIER_CENTER = Vector3.new(220, 1, -40)
local PIER_HALF_X = 60  -- pier extends ±60 from center (total 120)
local PIER_HALF_Z = 15  -- pier extends ±15 from center (total 30)
local SHOP_POSITIONS = {
	Vector3.new(180, 0, -40),  -- prism_motors
	Vector3.new(220, 0, -40),  -- prism_service_center
	Vector3.new(260, 0, -40),  -- neon_alley_tune
}

-- ──────────────────────────────────────────────
-- Pier railings + lamps
-- ──────────────────────────────────────────────

local function buildPierRailings(district: Folder, palette: any, budget: any)
	-- Railings along both north (z=-25) and south (z=-55) edges of the pier
	-- Pier spans x ∈ [160, 280], deck surface at y=1.5
	-- Railing posts every 10 studs, connected by top rail beam

	for _, zEdge in { PIER_CENTER.Z - PIER_HALF_Z + 1, PIER_CENTER.Z + PIER_HALF_Z - 1 } do
		local zLabel = if zEdge < PIER_CENTER.Z then "South" else "North"

		-- Top rail beam (continuous along entire pier)
		addPart(
			district,
			"PierRailBeam_" .. zLabel,
			Vector3.new(PIER_HALF_X * 2 - 2, 0.4, 1),
			CFrame.new(PIER_CENTER.X, PIER_CENTER.Y + 3.5, zEdge),
			palette.Steel,
			Enum.Material.SmoothPlastic
		)

		-- Bottom rail beam
		addPart(
			district,
			"PierRailLower_" .. zLabel,
			Vector3.new(PIER_HALF_X * 2 - 2, 0.3, 0.8),
			CFrame.new(PIER_CENTER.X, PIER_CENTER.Y + 1.8, zEdge),
			palette.Slate,
			Enum.Material.SmoothPlastic
		)

		WorldBuildBudget:add(budget, 2)

		-- Posts + lamps every 16 studs
		for step = PIER_CENTER.X - PIER_HALF_X + 4, PIER_CENTER.X + PIER_HALF_X - 4, 16 do
			addPart(
				district,
				"PierPost_" .. zLabel .. "_" .. tostring(step),
				Vector3.new(0.8, 3.2, 0.8),
				CFrame.new(step, PIER_CENTER.Y + 1.9, zEdge),
				palette.Midnight,
				Enum.Material.SmoothPlastic
			)

			-- Lamp on top of post
			local lamp = addPart(
				district,
				"PierLamp_" .. zLabel .. "_" .. tostring(step),
				Vector3.new(1.6, 1.2, 1.6),
				CFrame.new(step, PIER_CENTER.Y + 4.4, zEdge),
				palette.Gold,
				Enum.Material.Neon,
				0.1
			)
			lamp:SetAttribute("PierLamp", true)

			-- Point light
			local light = Instance.new("PointLight")
			light.Color = palette.Amber
			light.Brightness = 1.2
			light.Range = 16
			light.Parent = lamp

			WorldBuildBudget:add(budget, 2)
		end
	end
end

-- ──────────────────────────────────────────────
-- Deck surface lines (wood plank lines on pier floor)
-- ──────────────────────────────────────────────

local function buildDeckLines(district: Folder, palette: any, budget: any)
	for step = PIER_CENTER.X - PIER_HALF_X + 4, PIER_CENTER.X + PIER_HALF_X - 4, 4 do
		addPart(
			district,
			"DeckLine_" .. tostring(step),
			Vector3.new(0.15, 0.1, PIER_HALF_Z * 2 - 2),
			CFrame.new(step, PIER_CENTER.Y + 0.7, PIER_CENTER.Z),
			palette.Slate,
			Enum.Material.SmoothPlastic
		)
	end
	WorldBuildBudget:add(budget, 30)
end

-- ──────────────────────────────────────────────
-- Vehicle showroom buildings (3 wings)
-- ──────────────────────────────────────────────

local function buildShowroom(shopIndex: number, pos: Vector3, district: Folder, palette: any, budget: any)
	local label = tostring(shopIndex)

	-- Floor plate (raised slightly above pier)
	addPart(
		district,
		"ShowroomFloor_" .. label,
		Vector3.new(24, 0.3, 20),
		CFrame.new(pos.X, PIER_CENTER.Y + 1, pos.Z),
		palette.Midnight,
		Enum.Material.Slate
	)

	-- Back wall (north side, z+ direction from shop)
	addPart(
		district,
		"ShowroomBackWall_" .. label,
		Vector3.new(22, 10, 1),
		CFrame.new(pos.X, PIER_CENTER.Y + 6.5, pos.Z + 9),
		palette.Steel,
		Enum.Material.SmoothPlastic
	)

	-- Side walls (left/right)
	for _, xOff in { -11, 11 } do
		addPart(
			district,
			"ShowroomSideWall_" .. label .. "_" .. tostring(xOff),
			Vector3.new(1, 10, 18),
			CFrame.new(pos.X + xOff, PIER_CENTER.Y + 6.5, pos.Z),
			palette.Slate,
			Enum.Material.SmoothPlastic
		)
	end

	-- Glass front panel (south side, facing pier public walkway z- direction)
	local glassFront = addPart(
		district,
		"ShowroomGlass_" .. label,
		Vector3.new(20, 8, 0.4),
		CFrame.new(pos.X, PIER_CENTER.Y + 5.5, pos.Z - 10),
		palette.Cyan,
		Enum.Material.Glass,
		0.35
	)
	glassFront.Reflectance = 0.25

	-- Neon frame around glass
	addPart(
		district,
		"ShowroomFrameTop_" .. label,
		Vector3.new(21, 0.3, 0.6),
		CFrame.new(pos.X, PIER_CENTER.Y + 10, pos.Z - 9.7),
		palette.Gold,
		Enum.Material.Neon,
		0.05
	)
	addPart(
		district,
		"ShowroomFrameBot_" .. label,
		Vector3.new(21, 0.3, 0.6),
		CFrame.new(pos.X, PIER_CENTER.Y + 1, pos.Z - 9.7),
		palette.Gold,
		Enum.Material.Neon,
		0.05
	)

	-- Roof
	addPart(
		district,
		"ShowroomRoof_" .. label,
		Vector3.new(24, 0.6, 20),
		CFrame.new(pos.X, PIER_CENTER.Y + 11.5, pos.Z),
		palette.Slate,
		Enum.Material.SmoothPlastic
	)

	-- Vehicle display pedestal (raised platform in front of showroom)
	local pedPos = pos + Vector3.new(0, 0, -12)
	addPart(
		district,
		"VehiclePedestal_" .. label,
		Vector3.new(10, 1.5, 6),
		CFrame.new(pedPos.X, PIER_CENTER.Y + 2.2, pedPos.Z),
		palette.Midnight,
		Enum.Material.Slate
	):SetAttribute("VehiclePad", true)

	-- Neon ring around pedestal edge
	MicroCurveBuilder:fillCircle(
		pedPos + Vector3.new(0, 2.5, 0),
		5,
		0.5,
		{
			voxelStuds = 0.085,
			color = palette.Gold,
			material = Enum.Material.Neon,
			parent = district,
			filled = false,
			collision = false,
			budget = budget,
		}
	)

	-- Mock vehicle block-art (placeholder until ShowroomVehicleDisplay replaces them)
	local bodyColor = if shopIndex == 2 then palette.Teal else palette.Steel
	local vehicleRoot = Instance.new("Folder")
	vehicleRoot.Name = "DisplayVehiclePlaceholder_" .. label
	vehicleRoot.Parent = district

	addPart(
		vehicleRoot,
		"VehicleBody_" .. label,
		Vector3.new(6, 2, 3.5),
		CFrame.new(pedPos.X, PIER_CENTER.Y + 3.5, pedPos.Z),
		bodyColor,
		Enum.Material.SmoothPlastic
	)

	-- Cabin/glass top
	addPart(
		vehicleRoot,
		"VehicleCabin_" .. label,
		Vector3.new(4, 1.4, 2),
		CFrame.new(pedPos.X - 0.8, PIER_CENTER.Y + 4.8, pedPos.Z),
		palette.Cyan,
		Enum.Material.Glass,
		0.3
	)

	-- Wheels (4 small cylinders represented as cubes)
	for _, wx in { -2.2, 2.2 } do
		for _, wz in { -1.2, 1.2 } do
			addPart(
				vehicleRoot,
				"VehicleWheel_" .. label .. "_" .. tostring(wx) .. "_" .. tostring(wz),
				Vector3.new(1, 1, 1),
				CFrame.new(pedPos.X + wx, PIER_CENTER.Y + 1.2, pedPos.Z + wz),
				palette.Twilight,
				Enum.Material.SmoothPlastic
			)
		end
	end

	WorldBuildBudget:add(budget, 14)
end

-- ──────────────────────────────────────────────
-- Signage
-- ──────────────────────────────────────────────

local function buildSign(district: Folder, palette: any, budget: any)
	-- Sign post at west end of pier
	local signBase = Vector3.new(PIER_CENTER.X - PIER_HALF_X + 4, PIER_CENTER.Y, PIER_CENTER.Z - PIER_HALF_Z + 1)

	-- Post
	addPart(
		district,
		"ShowroomSignPost",
		Vector3.new(1.5, 14, 1.5),
		CFrame.new(signBase.X, signBase.Y + 7, signBase.Z),
		palette.Steel,
		Enum.Material.SmoothPlastic
	)

	-- Sign board
	local sign = addPart(
		district,
		"ShowroomSign",
		Vector3.new(24, 5, 1.5),
		CFrame.new(signBase.X + 14, signBase.Y + 11, signBase.Z + 2),
		palette.Gold,
		Enum.Material.Neon,
		0.05
	)
	sign:SetAttribute("ShowroomSign", true)
	addLabel(sign, "Marina Showroom Strip")

	-- Point light under sign
	local light = Instance.new("PointLight")
	light.Color = palette.Cyan
	light.Brightness = 2
	light.Range = 32
	light.Parent = sign

	-- Small accent posts flanking the sign
	for _, xOff in { -12, 12 } do
		addPart(
			district,
			"ShowroomSignFlank_" .. tostring(xOff),
			Vector3.new(0.8, 5, 0.8),
			CFrame.new(signBase.X + 14 + xOff, signBase.Y + 9.5, signBase.Z + 2),
			palette.Amber,
			Enum.Material.Neon,
			0.1
		)
	end

	WorldBuildBudget:add(budget, 5)
end

-- ──────────────────────────────────────────────
-- Entry: build()
-- ──────────────────────────────────────────────

function EternityCityMarinaShowroomLandmark.build(ctx: BuildContext): Folder
	local palette = ctx.profile.Palette
	local budget = ctx.budget

	local district = Instance.new("Folder")
	district.Name = "MarinaShowroomStripArt"
	district:SetAttribute("LandmarkArtPass", "v7_marina_showroom")
	district:SetAttribute("VisualBibleDistrict", "MarinaShowroom")

	buildPierRailings(district, palette, budget)
	buildDeckLines(district, palette, budget)

	-- 3 Showroom buildings — wrap around existing commerce kiosks
	for i, pos in SHOP_POSITIONS do
		buildShowroom(i, pos, district, palette, budget)
	end

	buildSign(district, palette, budget)

	district.Parent = ctx.parent
	return district
end

return EternityCityMarinaShowroomLandmark