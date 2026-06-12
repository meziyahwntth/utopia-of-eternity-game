--!strict
--[[
	UtopiaPlaza — mall (F1-5) + hotel (F6+) + rooftop restaurant.
	Hero mesh shell + procedural interior (walkable floors, escalators, express lift).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)
local CityArtKit = require(script.Parent.CityArtKit)
local ShopUnitKit = require(script.Parent.ShopUnitKit)

local UtopiaPlazaBuilder = {}

export type BuildContext = {
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
	base: CFrame,
}

local MALL_FLOOR_H = 16
local HOTEL_FLOOR_H = 12
local FLOOR_HALF = 46
local ATRIUM_HALF = 11
local MALL_FLOORS = 5
local HOTEL_FLOORS = 4
local ROOFTOP_Y = 140
local MESH_HEIGHT = 177.5

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

local function buildAtriumFloor(district: Folder, ctx: BuildContext, floorY: number, label: string, isGlass: boolean, escSide: number)
	local palette = ctx.profile.Palette
	local base = ctx.base
	local outer = FLOOR_HALF
	local inner = ATRIUM_HALF
	local thickness = 1.2
	local mat = if isGlass then Enum.Material.Glass else Enum.Material.Marble
	local col = if isGlass then palette.Cyan else palette.Pearl
	local trans = if isGlass then 0.42 else 0

	-- Four quadrants around open atrium
	-- quadrant ฝั่งบันไดเลื่อนขาเข้า (escSide=±1) แบ่ง 3 ชิ้น เว้นช่อง x[3,9] (รอบ x=6*s) z|36..46| ให้ ramp ทะลุ + landing
	local function quadrantNS(s: number)
		local qName = if s == 1 then "N" else "S"
		local cz = s * (inner + (outer - inner) / 2)
		if escSide ~= s then
			addPart(district, "Floor_" .. label .. "_" .. qName, Vector3.new(outer * 2, thickness, outer - inner), base * CFrame.new(0, floorY, cz), col, mat, { transparency = trans })
			return
		end
		local xc = 6 * s
		-- ชิ้นซ้ายของช่อง (x -46..xc-3), ชิ้นขวา (xc+3..46), ชิ้นแถบใกล้ atrium (x ช่อง, z 11..36)
		addPart(district, "Floor_" .. label .. "_" .. qName .. "1", Vector3.new((xc - 3) + outer, thickness, outer - inner), base * CFrame.new(((xc - 3) - outer) / 2, floorY, cz), col, mat, { transparency = trans })
		addPart(district, "Floor_" .. label .. "_" .. qName .. "2", Vector3.new(outer - (xc + 3), thickness, outer - inner), base * CFrame.new(((xc + 3) + outer) / 2, floorY, cz), col, mat, { transparency = trans })
		-- แถบใกล้ atrium (z 11..32) + แถบรับปลาย ramp (z 42.5..46) — ช่องโล่ง z 32..42.5 ให้ ramp+หัวผู้เล่นผ่าน
		addPart(district, "Floor_" .. label .. "_" .. qName .. "3", Vector3.new(6, thickness, 21), base * CFrame.new(xc, floorY, s * (inner + 10.5)), col, mat, { transparency = trans })
		addPart(district, "Floor_" .. label .. "_" .. qName .. "4", Vector3.new(6, thickness, 3.5), base * CFrame.new(xc, floorY, s * 44.25), col, mat, { transparency = trans })
	end
	quadrantNS(1)
	quadrantNS(-1)
	addPart(district, "Floor_" .. label .. "_E", Vector3.new(outer - inner, thickness, inner * 2), base * CFrame.new(inner + (outer - inner) / 2, floorY, 0), col, mat, { transparency = trans })
	addPart(district, "Floor_" .. label .. "_W", Vector3.new(outer - inner, thickness, inner * 2), base * CFrame.new(-(inner + (outer - inner) / 2), floorY, 0), col, mat, { transparency = trans })

	-- Gold trim + level sign
	for _, zSide in { -outer + 1, outer - 1 } do
		addPart(district, "TrimZ_" .. label .. "_" .. zSide, Vector3.new(outer * 2 - 2, 0.25, 0.5), base * CFrame.new(0, floorY + 0.7, zSide), palette.Gold, Enum.Material.Metal)
	end

	local sign = addPart(district, "LevelSign_" .. label, Vector3.new(8, 3, 0.4), base * CFrame.new(-outer + 6, floorY + 4, outer - 2), palette.Gold, Enum.Material.Neon, { transparency = 0.1 })
	addLabel(sign, label)

	-- Curved balcony rail around atrium
	CityArtKit.glassRail({ parent = district, palette = palette, budget = nil }, base * CFrame.new(0, floorY + 3.5, inner + 1), inner * 2 + 2, 3.5, "X")
	CityArtKit.glassRail({ parent = district, palette = palette, budget = nil }, base * CFrame.new(inner + 1, floorY + 3.5, 0), inner * 2 + 2, 3.5, "Z")
end

local function buildEscalator(district: Folder, ctx: BuildContext, fromY: number, toY: number, side: number)
	local palette = ctx.profile.Palette
	local rise = toY - fromY
	-- run 1.75×rise (slope ~30°) span z 14..42: โคนบนวงพื้นล่าง, ปลายบนโผล่ช่องพื้น (32..42.5) ต่อแถบรับ z 42.5..46
	local run = rise * 1.75
	local midY = fromY + rise / 2
	local z = side * 28
	local angle = math.atan(rise / run)

	addPart(
		district,
		string.format("Escalator_%d_%d", fromY, toY),
		Vector3.new(5, 0.5, run),
		ctx.base * CFrame.new(6 * side, midY, z) * CFrame.Angles(-angle * side, 0, 0),
		palette.Steel,
		Enum.Material.Metal
	)
	addPart(
		district,
		string.format("EscalatorRail_%d", fromY),
		Vector3.new(5.4, 2.5, 0.3),
		ctx.base * CFrame.new(6 * side, midY + 1.5, z - side * run / 2),
		palette.Gold,
		Enum.Material.Neon,
		{ transparency = 0.05 }
	)
end

-- บันไดโรงแรมแบบ switchback ในช่องบันได x[-3,3] z[-42,-18] (corridor เริ่ม z=-14 จึงเปิดโล่งทุกชั้น)
local function buildHotelStairs(district: Folder, ctx: BuildContext, fromY: number, toY: number)
	local palette = ctx.profile.Palette
	local half = (toY - fromY) / 2
	local steps = 10
	local depth = 2.2
	-- flight 1 (x=-1.6): z -18 → -40 ขึ้นครึ่งแรก
	for i = 1, steps do
		addPart(
			district,
			string.format("HotelStairA_%d_%d", fromY, i),
			Vector3.new(2.9, half / steps, depth),
			ctx.base * CFrame.new(-1.6, fromY + (half / steps) * (i - 0.5), -18 - (i - 0.5) * depth),
			palette.Pearl,
			Enum.Material.Marble
		)
	end
	-- ชานพักกลาง (เต็มกว้าง) ที่ z[-43,-40]
	addPart(district, string.format("HotelStairMid_%d", fromY), Vector3.new(6, 1, 3.4), ctx.base * CFrame.new(0, fromY + half - 0.5, -41.5), palette.Pearl, Enum.Material.Marble)
	-- flight 2 (x=+1.6): z -40 → -18 ขึ้นครึ่งหลัง
	for i = 1, steps do
		addPart(
			district,
			string.format("HotelStairB_%d_%d", fromY, i),
			Vector3.new(2.9, half / steps, depth),
			ctx.base * CFrame.new(1.6, fromY + half + (half / steps) * (i - 0.5), -40 + (i - 0.5) * depth),
			palette.Pearl,
			Enum.Material.Marble
		)
	end
	-- ชานพักทางออก เชื่อมเข้า corridor (z -18..-14)
	addPart(district, string.format("HotelStairTop_%d", fromY), Vector3.new(6, 1, 4.4), ctx.base * CFrame.new(0, toY - 0.5, -16), palette.Pearl, Enum.Material.Marble)
end

local function buildShopFacades(district: Folder, ctx: BuildContext, floorY: number, floorNum: number)
	local palette = ctx.profile.Palette
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local r = FLOOR_HALF - 3
		local pos = Vector3.new(math.cos(angle) * r, floorY + 4, math.sin(angle) * r)
		local facade = addPart(
			district,
			string.format("Shop_F%d_%d", floorNum, i),
			Vector3.new(8, 7, 0.6),
			ctx.base * CFrame.new(pos) * CFrame.Angles(0, -angle + math.pi / 2, 0),
			palette.Pearl,
			Enum.Material.Marble
		)
		addLabel(facade, string.format("SHOP %d-%d", floorNum, i))
		addPart(
			district,
			string.format("ShopTrim_F%d_%d", floorNum, i),
			Vector3.new(8.4, 0.3, 0.8),
			ctx.base * CFrame.new(pos + Vector3.new(0, 3.8, 0)) * CFrame.Angles(0, -angle + math.pi / 2, 0),
			palette.Gold,
			Enum.Material.Metal
		)
	end
end

local function buildAtriumWaterGarden(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local y = 1.5
	addPart(district, "AtriumPool", Vector3.new(ATRIUM_HALF * 1.6, 0.8, ATRIUM_HALF * 1.6), ctx.base * CFrame.new(0, y, 0), palette.Cyan, Enum.Material.Glass, { transparency = 0.35 })
	CityArtKit.goldPlanter({ parent = district, palette = palette, budget = nil }, ctx.base * CFrame.new(ATRIUM_HALF - 2, 0, ATRIUM_HALF - 2), 2.5)
	CityArtKit.goldPlanter({ parent = district, palette = palette, budget = nil }, ctx.base * CFrame.new(-ATRIUM_HALF + 2, 0, -ATRIUM_HALF + 2), 2.5)
	CityArtKit.palmTree({ parent = district, palette = palette, budget = nil }, ctx.base * CFrame.new(0, 0, 0))
end

local function buildSkylight(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	addPart(
		district,
		"Skylight",
		Vector3.new(ATRIUM_HALF * 2.2, 0.6, ATRIUM_HALF * 2.2),
		ctx.base * CFrame.new(0, MESH_HEIGHT - 4, 0),
		palette.Cyan,
		Enum.Material.Glass,
		{ transparency = 0.25, collide = false }
	)
end

local function buildExpressElevator(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local shaftX = FLOOR_HALF - 10
	local floor1Y = 2
	local roofY = ROOFTOP_Y + 2

	addPart(district, "LiftShaft", Vector3.new(8, MESH_HEIGHT, 8), ctx.base * CFrame.new(shaftX, MESH_HEIGHT / 2, 0), palette.Midnight, Enum.Material.SmoothPlastic, { transparency = 1, collide = false })

	local platform = addPart(district, "ExpressLiftPlatform", Vector3.new(6, 0.8, 6), ctx.base * CFrame.new(shaftX, floor1Y, 0), palette.Gold, Enum.Material.Metal)
	platform:SetAttribute("ExpressLift", true)

	for _, y in { floor1Y, roofY } do
		local door = addPart(district, "LiftDoor_" .. y, Vector3.new(6, 6, 0.4), ctx.base * CFrame.new(shaftX, y + 3, 4.2), palette.Pearl, Enum.Material.Marble, { transparency = 0.2 })
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ExpressLiftPrompt"
		prompt.ActionText = if y == floor1Y then "Express to Rooftop" else "Express to Lobby"
		prompt.ObjectText = "Utopia Express"
		prompt.MaxActivationDistance = 10
		prompt.Parent = door

		prompt.Triggered:Connect(function()
			if platform:GetAttribute("LiftMoving") == true then
				return
			end
			platform:SetAttribute("LiftMoving", true)
			local targetY = if y == floor1Y then roofY else floor1Y

			-- เก็บผู้เล่นที่ยืนบนแท่น แล้วพาไปด้วยระหว่าง tween (tween แท่น Anchored ไม่พา character เอง)
			local riders: { [Model]: CFrame } = {}
			for _, pl in Players:GetPlayers() do
				local chr = pl.Character
				if chr then
					local pivot = chr:GetPivot()
					if (pivot.Position - platform.Position).Magnitude < 9 then
						riders[chr] = platform.CFrame:ToObjectSpace(pivot)
					end
				end
			end

			local tween = TweenService:Create(platform, TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				CFrame = ctx.base * CFrame.new(shaftX, targetY, 0),
			})
			local conn = RunService.Heartbeat:Connect(function()
				for chr, rel in riders do
					if chr.Parent then
						chr:PivotTo(platform.CFrame * rel)
					end
				end
			end)
			tween.Completed:Once(function()
				conn:Disconnect()
				platform:SetAttribute("LiftMoving", false)
			end)
			tween:Play()
		end)
	end
end

local function buildRooftopRestaurant(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	local base = ctx.base * CFrame.new(0, ROOFTOP_Y, 0)

	addPart(district, "RooftopDeck", Vector3.new(FLOOR_HALF * 2 - 4, 0.8, FLOOR_HALF * 2 - 4), base * CFrame.new(0, 0.4, 0), palette.Pearl, Enum.Material.Marble)

	for i = 0, 15 do
		local angle = (i / 16) * math.pi * 2
		local r = FLOOR_HALF - 2
		CityArtKit.glassRail({ parent = district, palette = palette, budget = nil }, base * CFrame.new(math.cos(angle) * r, 0, math.sin(angle) * r) * CFrame.Angles(0, angle, 0), 8, 4, "X")
	end

	CityArtKit.cafeSet({ parent = district, palette = palette, budget = nil }, base * CFrame.new(-12, 0, 10))
	CityArtKit.cafeSet({ parent = district, palette = palette, budget = nil }, base * CFrame.new(14, 0, -8))

	addPart(district, "RooftopBar", Vector3.new(16, 2.5, 4), base * CFrame.new(0, 1.5, -FLOOR_HALF + 8), palette.Slate, Enum.Material.SmoothPlastic)
	addPart(district, "RooftopBarTrim", Vector3.new(16, 0.3, 4.4), base * CFrame.new(0, 2.8, -FLOOR_HALF + 8), palette.Gold, Enum.Material.Neon, { transparency = 0.08 })

	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		local light = addPart(district, "RooftopLight_" .. i, Vector3.new(1, 1, 1), base * CFrame.new(math.cos(angle) * 20, 5, math.sin(angle) * 20), palette.Amber, Enum.Material.Neon, { collide = false })
		local pl = Instance.new("PointLight")
		pl.Brightness = 1.2
		pl.Range = 18
		pl.Color = palette.Gold
		pl.Parent = light
	end

	local sign = addPart(district, "RooftopSign", Vector3.new(20, 4, 1), base * CFrame.new(0, 8, FLOOR_HALF - 4), palette.Gold, Enum.Material.Neon, { transparency = 0.1 })
	addLabel(sign, "UTOPIA SKY DINING · 360°")
end

local function buildEntrances(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	-- พื้น threshold เชื่อมขอบพื้น F1 (z=46) กับลานหน้าตึก — กันตกช่องว่างหน้าประตู
	addPart(district, "EntranceThreshold", Vector3.new(44, 1.2, 10), ctx.base * CFrame.new(0, 0.6, FLOOR_HALF + 4), palette.Pearl, Enum.Material.Marble)
	for _, x in { -14, 14 } do
		CityArtKit.archRib({ parent = district, palette = palette, budget = ctx.budget }, ctx.base * CFrame.new(x, 0, FLOOR_HALF + 2), 16)
		addPart(district, "EntranceVoid_" .. x, Vector3.new(10, 10, 2), ctx.base * CFrame.new(x, 5, FLOOR_HALF + 1), palette.Midnight, Enum.Material.SmoothPlastic, { transparency = 1, collide = false })
	end
end

local function buildApproachPlaza(district: Folder, ctx: BuildContext)
	local palette = ctx.profile.Palette
	CityArtKit.laneRoad({ parent = district, palette = palette, budget = ctx.budget }, ctx.base * CFrame.new(0, 0, FLOOR_HALF + 28), 48, 3)
	for i = -2, 2 do
		CityArtKit.palmTree({ parent = district, palette = palette, budget = ctx.budget }, ctx.base * CFrame.new(i * 14, 0, FLOOR_HALF + 38))
		CityArtKit.goldPlanter({ parent = district, palette = palette, budget = ctx.budget }, ctx.base * CFrame.new(i * 10, 0, FLOOR_HALF + 18), 2.8)
	end
	CityArtKit.cafeSet({ parent = district, palette = palette, budget = ctx.budget }, ctx.base * CFrame.new(-22, 0, FLOOR_HALF + 22))
end

local function buildHotelFloor(district: Folder, ctx: BuildContext, floorY: number, floorNum: number)
	local palette = ctx.profile.Palette
	-- corridor เริ่ม z=-14 เว้นช่องบันได switchback (z -42..-18)
	addPart(district, "HotelHall_" .. floorNum, Vector3.new(10, 0.8, 56), ctx.base * CFrame.new(0, floorY, 14), palette.Pearl, Enum.Material.Marble)
	for _, side in { -1, 1 } do
		for room = 1, 4 do
			local z = -10 + room * 12
			local door = addPart(
				district,
				string.format("Room_F%d_%d", floorNum, room),
				Vector3.new(0.4, 6, 4),
				ctx.base * CFrame.new(side * 12, floorY + 3.5, z),
				palette.Cyan,
				Enum.Material.Glass,
				{ transparency = 0.3 }
			)
			addLabel(door, string.format("SUITE %d%02d", floorNum, room))
		end
	end
end

function UtopiaPlazaBuilder.build(ctx: BuildContext): Folder
	partCount = 0
	local district = Instance.new("Folder")
	district.Name = "UtopiaPlaza"
	district:SetAttribute("LandmarkArtPass", "v1_utopia_plaza")
	district:SetAttribute("VisualBibleDistrict", "UtopiaPlaza")

	buildApproachPlaza(district, ctx)
	buildEntrances(district, ctx)
	buildAtriumWaterGarden(district, ctx)

	for floor = 1, MALL_FLOORS do
		local floorY = (floor - 1) * MALL_FLOOR_H + 0.6
		local escSide = if floor == 1 then 0 else (if (floor - 1) % 2 == 0 then 1 else -1)
		buildAtriumFloor(district, ctx, floorY, "LEVEL " .. floor, floor >= 3, escSide)
		buildShopFacades(district, ctx, floorY, floor)
		if floor < MALL_FLOORS then
			local nextY = floor * MALL_FLOOR_H + 0.6
			buildEscalator(district, ctx, floorY, nextY, if floor % 2 == 0 then 1 else -1)
		end
	end

	local hotelBaseY = MALL_FLOORS * MALL_FLOOR_H
	-- บันไดเชื่อม mall F5 → hotel F6 (สเปก: ชั้นโรงแรมขึ้นด้วยบันไดเท่านั้น)
	local mallTopY = (MALL_FLOORS - 1) * MALL_FLOOR_H + 0.6
	buildHotelStairs(district, ctx, mallTopY, hotelBaseY + 0.6)
	for h = 1, HOTEL_FLOORS do
		local floorY = hotelBaseY + (h - 1) * HOTEL_FLOOR_H + 0.6
		buildHotelFloor(district, ctx, floorY, 5 + h)
		if h < HOTEL_FLOORS then
			buildHotelStairs(district, ctx, floorY, floorY + HOTEL_FLOOR_H)
		end
	end

	buildSkylight(district, ctx)
	buildExpressElevator(district, ctx)
	buildRooftopRestaurant(district, ctx)
	ShopUnitKit.addShopUnits(district, ctx, "UP")

	local savedParts = partCount
	district:SetAttribute("PartCount", savedParts)
	district:SetAttribute("BasePosition", ctx.base.Position)
	district:SetAttribute("MeshHeight", MESH_HEIGHT)
	trackBudget(ctx)
	district.Parent = ctx.parent
	return district
end

return UtopiaPlazaBuilder
