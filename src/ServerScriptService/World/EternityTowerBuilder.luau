--!strict
--[[
	Eternity Tower — vehicle & weapon showroom (F1-4) + rooftop concert + helipad.
	Hero mesh shell + procedural walkable interior.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)
local CityArtKit = require(script.Parent.CityArtKit)

local EternityTowerBuilder = {}

export type BuildContext = {
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
	base: CFrame,
}

local FLOOR_H = 16
local FLOORS = 5
local FLOOR_HALF_X = 44
local FLOOR_HALF_Z = 32
local MESH_HEIGHT = 111.4
local GLASS_RAIL_H = 5

local partCount = 0

local function addPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	opts: { transparency: number?, collide: boolean? }?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.Color = color
	part.Material = material
	part.Transparency = if opts then opts.transparency or 0 else 0
	part.CanCollide = if opts and opts.collide ~= nil then opts.collide else true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	partCount += 1
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

local function trackBudget(ctx: BuildContext)
	WorldBuildBudget:add(ctx.budget, partCount)
	partCount = 0
end

-- พื้นชั้น: ชั้น 1 เต็มแผ่น / ชั้น 2+ แบ่ง 5 ชิ้นเว้นช่องบันได (East z[-27,1]) และ escalator (West z[12,26])
local function buildFloorPlate(district: Folder, ctx: BuildContext, name: string, plateY: number, thickness: number, withOpenings: boolean)
	local palette = ctx.profile.Palette
	if not withOpenings then
		addPart(district, name, Vector3.new(FLOOR_HALF_X * 2, thickness, FLOOR_HALF_Z * 2), ctx.base * CFrame.new(0, plateY, 0), palette.Pearl, Enum.Material.Marble)
		return
	end
	local segs = {
		{ sx = 14, sz = 44, cx = -37, cz = -10 }, -- W1 (ถึงขอบช่อง escalator z=12)
		{ sx = 14, sz = 6, cx = -37, cz = 29 }, -- W2 (หลังช่อง z=26)
		{ sx = 60, sz = FLOOR_HALF_Z * 2, cx = 0, cz = 0 }, -- MID เต็ม
		{ sx = 14, sz = 5, cx = 37, cz = -29.5 }, -- E1 (ก่อนช่องบันได z=-27)
		{ sx = 14, sz = 31, cx = 37, cz = 16.5 }, -- E2 (หลังช่อง z=1)
	}
	for i, s in segs do
		addPart(district, name .. "_" .. i, Vector3.new(s.sx, thickness, s.sz), ctx.base * CFrame.new(s.cx, plateY, s.cz), palette.Pearl, Enum.Material.Marble)
	end
end

local function buildShowroomFloor(district: Folder, ctx: BuildContext, floorIndex: number)
	local palette = ctx.profile.Palette
	local floorY = (floorIndex - 1) * FLOOR_H + 0.5
	local label = "SHOWROOM " .. floorIndex

	buildFloorPlate(district, ctx, "FloorPlate_" .. floorIndex, floorY, 1, floorIndex >= 2)

	for _, zSide in { -FLOOR_HALF_Z + 1, FLOOR_HALF_Z - 1 } do
		addPart(
			district,
			"FloorTrimZ_" .. floorIndex .. "_" .. zSide,
			Vector3.new(FLOOR_HALF_X * 2 - 2, 0.25, 0.5),
			ctx.base * CFrame.new(0, floorY + 0.7, zSide),
			palette.Gold,
			Enum.Material.Metal
		)
	end

	-- Glass band around tier (curved stacked tiers visual)
	addPart(
		district,
		"GlassBand_" .. floorIndex,
		Vector3.new(FLOOR_HALF_X * 2 + 2, FLOOR_H - 2, FLOOR_HALF_Z * 2 + 2),
		ctx.base * CFrame.new(0, floorY + FLOOR_H / 2, 0),
		palette.Cyan,
		Enum.Material.Glass,
		{ transparency = 0.55, collide = false }
	)

	for i = 1, 4 do
		local x = -FLOOR_HALF_X + 12 + (i - 1) * 18
		local pad = addPart(
			district,
			string.format("ShowPad_F%d_%d", floorIndex, i),
			Vector3.new(10, 0.4, 8),
			ctx.base * CFrame.new(x, floorY + 0.8, 0),
			palette.Gold,
			Enum.Material.Neon,
			{ transparency = 0.35 }
		)
		pad:SetAttribute("ShowroomPad", true)
		local sign = addPart(district, string.format("ShowSign_F%d_%d", floorIndex, i), Vector3.new(6, 2, 0.3), ctx.base * CFrame.new(x, floorY + 3, -5), palette.Pearl, Enum.Material.Marble)
		addLabel(sign, if floorIndex <= 2 then "VEHICLES" else "WEAPONS")
	end

	if floorIndex < FLOORS then
		local nextY = floorIndex * FLOOR_H + 0.5
		-- บันได: z -26 → -2 (12 ขั้น) + ชานพักเชื่อมพื้นชั้นถัดไป (ช่องพื้นฝั่ง East z[-27,1])
		local steps = 12
		local rise = FLOOR_H / steps
		for s = 1, steps do
			addPart(
				district,
				string.format("Stair_F%d_%d", floorIndex, s),
				Vector3.new(6, rise, 2.0),
				ctx.base * CFrame.new(FLOOR_HALF_X - 8, floorY + rise * (s - 0.5), -26 + (s - 0.5) * 2.0),
				palette.Pearl,
				Enum.Material.Marble
			)
		end
		addPart(district, string.format("StairLanding_F%d", floorIndex), Vector3.new(6, 1, 3.5), ctx.base * CFrame.new(FLOOR_HALF_X - 8, nextY + 0.05, -0.5), palette.Pearl, Enum.Material.Marble)
		-- Escalator ฝั่ง West: z -4 → 24 (run 28, ~30°) + ชานพักบน (ช่องพื้นฝั่ง West z[12,26])
		local run = FLOOR_H * 1.75
		local angle = math.atan(FLOOR_H / run)
		addPart(
			district,
			string.format("Escalator_F%d", floorIndex),
			Vector3.new(5, 0.5, run),
			ctx.base * CFrame.new(-FLOOR_HALF_X + 8, floorY + FLOOR_H / 2, 10) * CFrame.Angles(-angle, 0, 0),
			palette.Steel,
			Enum.Material.Metal
		)
		addPart(district, string.format("EscalatorLanding_F%d", floorIndex), Vector3.new(5, 1, 3), ctx.base * CFrame.new(-FLOOR_HALF_X + 8, nextY + 0.05, 24.5), palette.Steel, Enum.Material.Metal)
	end

	local levelSign = addPart(district, "LevelSign_" .. floorIndex, Vector3.new(10, 3, 0.4), ctx.base * CFrame.new(0, floorY + 6, -FLOOR_HALF_Z + 3), palette.Gold, Enum.Material.Neon, { transparency = 0.1 })
	addLabel(levelSign, label)
end

local function buildConcertZone(district: Folder, ctx: BuildContext, roofY: number)
	local palette = ctx.profile.Palette
	local base = ctx.base * CFrame.new(0, roofY, FLOOR_HALF_Z - 8)

	addPart(district, "StageDeck", Vector3.new(28, 1.2, 14), base * CFrame.new(0, 0.6, 0), palette.Pearl, Enum.Material.Marble)
	-- backdrop/arch อยู่ขอบนอก (+Z) — คนดูฝั่งใจกลางดาดฟ้ามองเห็นเวทีเต็ม
	addPart(district, "StageBackdrop", Vector3.new(30, 12, 1.5), base * CFrame.new(0, 7, 7), palette.Midnight, Enum.Material.SmoothPlastic)
	addPart(district, "StageArch", Vector3.new(32, 14, 1), base * CFrame.new(0, 8, 7.5), palette.Gold, Enum.Material.Neon, { transparency = 0.12 })

	for i = 1, 4 do
		local x = (i - 2.5) * 6
		local truss = addPart(district, "StageLight_" .. i, Vector3.new(1, 8, 1), base * CFrame.new(x, 10, 4), palette.Steel, Enum.Material.Metal)
		local lamp = addPart(district, "StageLamp_" .. i, Vector3.new(2, 1, 2), base * CFrame.new(x, 14.5, 4), palette.Amber, Enum.Material.Neon, { transparency = 0.1 })
		local spot = Instance.new("SpotLight")
		spot.Brightness = 2
		spot.Range = 24
		spot.Angle = 40
		spot.Face = Enum.NormalId.Bottom
		spot.Parent = lamp
		truss.CanCollide = false
	end

	-- ลานคนดูขั้นบันได หันหน้าเข้าเวที (ฝั่งใจกลางดาดฟ้า ไล่ลาดออกจากเวที)
	for row = 1, 4 do
		for col = 1, 6 do
			local x = (col - 3.5) * 4.5
			local z = 10 + row * 5
			addPart(
				district,
				string.format("AudienceStep_R%d_C%d", row, col),
				Vector3.new(4, 0.8 + row * 0.35, 3.5),
				ctx.base * CFrame.new(x, roofY + 0.5 + row * 0.35, FLOOR_HALF_Z - 8 - z),
				palette.Slate,
				Enum.Material.Slate
			)
		end
	end

	-- Glass rail ~5 studs on front viewing edge (+Z)
	local frontZ = FLOOR_HALF_Z - 2
	for seg = 1, 8 do
		local x = -FLOOR_HALF_X + 6 + (seg - 1) * 10
		CityArtKit.glassRail({ parent = district, palette = palette, budget = nil }, ctx.base * CFrame.new(x, roofY, frontZ), 10, GLASS_RAIL_H, "X")
	end
end

local function buildHelicopter(parent: Folder, baseCf: CFrame, palette: any): Model
	local model = Instance.new("Model")
	model.Name = "StaticHelicopter"
	model.Parent = parent

	local body = addPart(model, "Fuselage", Vector3.new(14, 4, 6), baseCf * CFrame.new(0, 2.5, 0), palette.Pearl, Enum.Material.SmoothPlastic)
	local cockpit = addPart(model, "Cockpit", Vector3.new(5, 3, 4), baseCf * CFrame.new(5, 3.5, 0), palette.Cyan, Enum.Material.Glass, { transparency = 0.35 })
	local tail = addPart(model, "TailBoom", Vector3.new(10, 1.5, 1.5), baseCf * CFrame.new(-10, 3, 0), palette.Pearl, Enum.Material.SmoothPlastic)
	local tailRotor = addPart(model, "TailRotor", Vector3.new(0.3, 3, 3), baseCf * CFrame.new(-15, 3, 0), palette.Steel, Enum.Material.Metal, { collide = false })
	local mainRotorHub = addPart(model, "RotorHub", Vector3.new(2, 1, 2), baseCf * CFrame.new(0, 5.5, 0), palette.Gold, Enum.Material.Metal)
	for b = 1, 4 do
		local angle = (b / 4) * math.pi * 2
		addPart(
			model,
			"Blade_" .. b,
			Vector3.new(16, 0.25, 1.2),
			baseCf * CFrame.new(math.cos(angle) * 7, 5.8, math.sin(angle) * 7) * CFrame.Angles(0, angle, 0),
			palette.Midnight,
			Enum.Material.SmoothPlastic,
			{ collide = false }
		)
	end
	local skidL = addPart(model, "SkidL", Vector3.new(10, 0.5, 0.5), baseCf * CFrame.new(0, 0.8, 2.5), palette.Gold, Enum.Material.Metal)
	local skidR = addPart(model, "SkidR", Vector3.new(10, 0.5, 0.5), baseCf * CFrame.new(0, 0.8, -2.5), palette.Gold, Enum.Material.Metal)
	model.PrimaryPart = body
	skidL.CanCollide = false
	skidR.CanCollide = false
	cockpit.CanCollide = false
	return model
end

local function buildHelipadZone(district: Folder, ctx: BuildContext, roofY: number)
	local palette = ctx.profile.Palette
	local padCenter = ctx.base * CFrame.new(0, roofY, -FLOOR_HALF_Z + 13) -- deck 26 กว้าง: ขอบหลังพอดี z=-32 ไม่ยื่นพ้นดาดฟ้า

	addPart(district, "HelipadDeck", Vector3.new(26, 0.6, 26), padCenter * CFrame.new(0, 0.3, 0), palette.Pearl, Enum.Material.Marble)
	addPart(district, "HelipadMark", Vector3.new(20, 0.15, 20), padCenter * CFrame.new(0, 0.65, 0), palette.Gold, Enum.Material.Neon, { transparency = 0.2 })

	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2
		addPart(
			district,
			"HelipadRing_" .. i,
			Vector3.new(3, 0.12, 0.8),
			padCenter * CFrame.new(math.cos(angle) * 11, 0.7, math.sin(angle) * 11) * CFrame.Angles(0, angle, 0),
			palette.Gold,
			Enum.Material.Neon,
			{ transparency = 0.15 }
		)
	end

	buildHelicopter(district, padCenter * CFrame.new(0, 0.5, 0), palette)
	-- No glass rail on helipad zone (per spec)
end

local function buildRooftop(district: Folder, ctx: BuildContext)
	local roofY = (FLOORS - 1) * FLOOR_H + 1
	local palette = ctx.profile.Palette

	buildFloorPlate(district, ctx, "RooftopPlate", roofY, 0.8, true)

	buildConcertZone(district, ctx, roofY + 0.8)
	buildHelipadZone(district, ctx, roofY + 0.8)

	local sign = addPart(district, "TowerRooftopSign", Vector3.new(18, 3, 1), ctx.base * CFrame.new(0, roofY + 10, 0), palette.Gold, Enum.Material.Neon, { transparency = 0.1 })
	addLabel(sign, "ETERNITY TOWER · SKY DECK")
end

local function buildApproach(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	CityArtKit.laneRoad({ parent = district, palette = palette, budget = ctx.budget }, ctx.base * CFrame.new(0, 0, FLOOR_HALF_Z + 22), 36, 2)
	for i = -1, 1 do
		CityArtKit.palmTree({ parent = district, palette = palette, budget = ctx.budget }, ctx.base * CFrame.new(i * 16, 0, FLOOR_HALF_Z + 30))
	end
	CityArtKit.archRib({ parent = district, palette = palette, budget = ctx.budget }, ctx.base * CFrame.new(0, 0, FLOOR_HALF_Z + 4), 18)
end

function EternityTowerBuilder.build(ctx: BuildContext): Folder
	partCount = 0
	local district = Instance.new("Folder")
	district.Name = "EternityTower"
	district:SetAttribute("LandmarkArtPass", "v1_eternity_tower")
	district:SetAttribute("VisualBibleDistrict", "EternityTower")

	buildApproach(district, ctx)
	for floor = 1, FLOORS - 1 do
		buildShowroomFloor(district, ctx, floor)
	end
	buildRooftop(district, ctx)

	local savedParts = partCount
	district:SetAttribute("PartCount", savedParts)
	district:SetAttribute("BasePosition", ctx.base.Position)
	district:SetAttribute("MeshHeight", MESH_HEIGHT)
	trackBudget(ctx)
	district.Parent = ctx.parent
	return district
end

return EternityTowerBuilder
