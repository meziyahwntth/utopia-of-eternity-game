--!strict
--[[
	Neon Utopia — เมืองมนุษย์ neon (จุดเกิดแรกของผู้เล่นใหม่, V2)

	ผู้เล่นใหม่ onboarding ที่นี่ แล้วขึ้น Air Transport (P2) ไป Utopia ลอยฟ้า
	greybox ก่อน — hero mesh/รายละเอียดทีหลังเหมือนเมืองอื่น

	TODO(P2): AirTransportService มาต่อ logic ที่ part "AirTransportDeparturePad"
	TODO(Place): ใส่ Place ID ใน PlaceSecrets.NeonUtopia เมื่อสร้าง Roblox Place แล้ว
	           — ระหว่างนี้ preview ใน Studio ได้ด้วย GameConfig.StudioDev.SimulatePlaceKey = "NeonUtopia"
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))

local OrganicCSGBuilder = require(script.Parent.OrganicCSGBuilder)
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)
local WorldBuildShared = require(script.Parent.WorldBuildShared)
local WorldBuilderTypes = require(script.Parent.WorldBuilderTypes)
local WorldPlaceGuard = require(script.Parent.WorldPlaceGuard)
local LoadoutPlazaKit = require(script.Parent.LoadoutPlazaKit)
local PrismKeyPickupKit = require(script.Parent.PrismKeyPickupKit)

local NeonUtopiaWorldBuilder = {}

-- แท่นขึ้นยานขนส่งทางอากาศ (placeholder — P2 จะมาต่อ logic การขึ้นเครื่อง + ค่าโดยสาร)
type Palette = {
	Pearl: Color3,
	Gold: Color3,
	Cyan: Color3,
	Twilight: Color3,
	Amber: Color3,
	Steel: Color3,
	Slate: Color3,
	Midnight: Color3,
	Teal: Color3,
}

local function buildDeparturePad(model: Model, palette: Palette, budget: WorldBuildBudget.Budget)
	local pad = Instance.new("Part")
	pad.Name = "AirTransportDeparturePad"
	pad.Anchored = true
	pad.Shape = Enum.PartType.Cylinder
	pad.Size = Vector3.new(2, 44, 44) -- cylinder: แกน X = ความหนา → แท่นกลมแบน
	pad.CFrame = CFrame.new(0, 1, -90) * CFrame.Angles(0, 0, math.rad(90))
	pad.Material = Enum.Material.Marble
	pad.Color = palette.Pearl
	pad.Parent = model
	WorldBuildBudget:add(budget, 1)

	-- พอร์ทัลเรืองแสงตั้งฉาก (ตา/ประตูมิติ ตามภาพ ref) — ใช้เป็นจุดขึ้นยาน/ข้ามมิติ P2
	local portal = Instance.new("Part")
	portal.Name = "TransitPortalDisc"
	portal.Anchored = true
	portal.CanCollide = false
	portal.Shape = Enum.PartType.Cylinder
	portal.Size = Vector3.new(1.5, 24, 24)
	portal.CFrame = CFrame.new(0, 14, -90) * CFrame.Angles(0, math.rad(90), 0)
	portal.Material = Enum.Material.Neon
	portal.Color = Color3.fromRGB(70, 150, 255)
	portal.Transparency = 0.15
	portal.Parent = model
	WorldBuildBudget:add(budget, 1)

	local ringPoints: { Vector3 } = {}
	for i = 0, 28 do
		local a = (i / 28) * math.pi * 2
		table.insert(ringPoints, Vector3.new(math.cos(a) * 18, 2.2, -90 + math.sin(a) * 18))
	end
	MicroCurveBuilder:fillArc(ringPoints, 1.2, {
		voxelStuds = 0.12,
		color = palette.Cyan,
		material = Enum.Material.Neon,
		parent = model,
		budget = budget,
	})

	local pylon = Instance.new("Part")
	pylon.Name = "TransitPylon"
	pylon.Anchored = true
	pylon.Size = Vector3.new(2, 26, 2)
	pylon.Position = Vector3.new(0, 14, -108)
	pylon.Material = Enum.Material.Neon
	pylon.Color = palette.Cyan
	pylon.Parent = model
	WorldBuildBudget:add(budget, 1)

	local sign = Instance.new("Part")
	sign.Name = "TransitSign"
	sign.Anchored = true
	sign.Size = Vector3.new(22, 6, 1)
	sign.Position = Vector3.new(0, 28, -108)
	sign.Material = Enum.Material.SmoothPlastic
	sign.Color = palette.Midnight
	sign.Parent = model
	WorldBuildBudget:add(budget, 1)

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "\u{2708}  TO UTOPIA  \u{2192}"
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = palette.Cyan
	label.Parent = gui
end

function NeonUtopiaWorldBuilder:Build(_ctx: WorldBuilderTypes.BuildContext?): WorldBuilderTypes.BuildResult
	if not WorldPlaceGuard:ShouldBuild("NeonUtopia") then
		return WorldBuilderTypes.skip("not this place")
	end
	if WorldPlaceGuard:ModelExists("UtopiaNeonCity") then
		return WorldBuilderTypes.skip("UtopiaNeonCity already built")
	end

	local profile = WorldBuildConfig:GetProfile("NeonUtopia")
	local budget = WorldBuildBudget:new(profile.MaxParts)

	-- โทนภาพ ref: มหานครหรูหราขาว-ทอง-กระจก กลางวันสว่าง (neon = ไฟ accent ฟ้า ไม่ใช่ cyberpunk มืด)
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(180, 200, 220)

	local model = Instance.new("Model")
	model.Name = "UtopiaNeonCity"
	model.Parent = workspace

	-- พื้นหินอ่อนสว่าง
	WorldBuildShared:makeGround(model, profile.GroundSizeStuds, profile.Palette.Pearl, Enum.Material.Marble)
	WorldBuildBudget:add(budget, 1)

	-- คลองน้ำเทอร์ควอยซ์กลางเมือง (translucent) + ขอบไฟฟ้า cyan
	local canal = Instance.new("Part")
	canal.Name = "TurquoiseCanal"
	canal.Anchored = true
	canal.CanCollide = false
	canal.Size = Vector3.new(profile.GroundSizeStuds * 0.9, 1, 120)
	canal.Position = Vector3.new(0, 0.7, 40)
	canal.Material = Enum.Material.Glass
	canal.Color = Color3.fromRGB(64, 196, 224)
	canal.Transparency = 0.35
	canal.Parent = model
	WorldBuildBudget:add(budget, 1)

	local radius = WorldBuildShared:getSanctuaryRadius("NeonUtopia")
	WorldBuildShared:makeSanctuaryZone(model, radius, budget, profile)
	WorldBuildShared:addSanctuarySpawns(model, 4, radius, budget)
	WorldBuildShared:buildOrganicCanopy(CFrame.new(0, 0, 0), model, profile, budget)

	-- ตึก neon greybox รอบจัตุรัส
	for i = 1, 6 do
		local a = (i / 6) * math.pi * 2
		local x = math.cos(a) * 70
		local z = math.sin(a) * 70
		local height = 40 + i * 6
		local tower = Instance.new("Part")
		tower.Name = "NeonTower_" .. i
		tower.Anchored = true
		tower.Size = Vector3.new(16, height, 16)
		tower.Position = Vector3.new(x, height / 2, z)
		tower.Material = Enum.Material.Glass
		tower.Color = profile.Palette.Pearl -- ตึกขาว-กระจก
		tower.Reflectance = 0.25
		tower.Parent = model
		WorldBuildBudget:add(budget, 1)

		-- แถบขอบทอง
		local goldTrim = Instance.new("Part")
		goldTrim.Name = "GoldTrim_" .. i
		goldTrim.Anchored = true
		goldTrim.Size = Vector3.new(16.6, 2, 16.6)
		goldTrim.Position = Vector3.new(x, height - 6, z)
		goldTrim.Material = Enum.Material.Metal
		goldTrim.Color = profile.Palette.Gold
		goldTrim.Parent = model
		WorldBuildBudget:add(budget, 1)

		-- แถบไฟ neon ฟ้า (accent)
		local strip = Instance.new("Part")
		strip.Name = "NeonStrip_" .. i
		strip.Anchored = true
		strip.Size = Vector3.new(1.2, height - 2, 1.2)
		strip.Position = Vector3.new(x + 8.4, height / 2, z)
		strip.Material = Enum.Material.Neon
		strip.Color = profile.Palette.Cyan
		strip.Parent = model
		WorldBuildBudget:add(budget, 1)
	end

	-- จุด onboarding กลางจัตุรัส (สอนแต่งตัว)
	LoadoutPlazaKit.addPlaza(model, {
		origin = Vector3.new(0, 0, 24),
		wardrobeLabel = "Neon Wardrobe",
		mirrorLabel = "City Mirror",
		autoRotate = true,
	})

	buildDeparturePad(model, profile.Palette, budget)

	-- กุญแจ #1 สำหรับผู้เล่นใหม่ (เริ่ม progression — Level 1)
	PrismKeyPickupKit.addPickup({
		pickupId = "neon_welcome_key_1",
		keyNumber = 1,
		position = Vector3.new(0, 4, 24),
		parent = model,
	})

	-- Racing: สร้างสนาม Neon Grand Prix (loop รอบเมือง)
	pcall(function()
		require(script.Parent.NeonUtopiaRaceTrackBuilder).build(model)
	end)

	WorldBuildBudget:report("NeonUtopia", budget)
	print("[Utopia] Neon Utopia (human city) greybox built — departure pad \u{2192} Utopia")
	return WorldBuilderTypes.success(model)
end

return NeonUtopiaWorldBuilder
