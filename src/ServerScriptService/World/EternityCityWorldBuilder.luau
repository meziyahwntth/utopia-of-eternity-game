--!strict
--[[
	Utopia of Eternity flagship — Aurora Spire cluster, marina, Sky Rail, gates, Sky Lounge.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))

local OrganicCSGBuilder = require(script.Parent.OrganicCSGBuilder)
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)
local WorldBuildShared = require(script.Parent.WorldBuildShared)
local WorldBuilderTypes = require(script.Parent.WorldBuilderTypes)
local WorldPlaceGuard = require(script.Parent.WorldPlaceGuard)
local EternityCityLighting = require(script.Parent.EternityCityLighting)
local EternityCityAccessGuard = require(script.Parent.EternityCityAccessGuard)

local ShuttleGreyboxBuilder = require(ServerScriptService:WaitForChild("ShuttleGreyboxBuilder"))
local CommerceDistrictBuilder = require(script.Parent.CommerceDistrictBuilder)

local LoadoutPlazaKit = require(script.Parent.LoadoutPlazaKit)
local PrismKeyPickupKit = require(script.Parent.PrismKeyPickupKit)
local EternityCityMarinaLandmark = require(script.Parent.EternityCityMarinaLandmark)
local EternityCityAuroraSpireLandmark = require(script.Parent.EternityCityAuroraSpireLandmark)
local EternityCityCanalPromenadeLandmark = require(script.Parent.EternityCityCanalPromenadeLandmark)
local EternityCitySkyRailPlazaLandmark = require(script.Parent.EternityCitySkyRailPlazaLandmark)
local EternityCityAuroraMegaMallLandmark = require(script.Parent.EternityCityAuroraMegaMallLandmark)
local EternityCityTwilightOverpassLandmark = require(script.Parent.EternityCityTwilightOverpassLandmark)
local EternityCityMarinaShowroomLandmark = require(script.Parent.EternityCityMarinaShowroomLandmark)
local ShowroomVehicleDisplay = require(ServerScriptService:WaitForChild("Mount"):WaitForChild("ShowroomVehicleDisplay"))
local EternityCityFestivalStage = require(script.Parent.EternityCityFestivalStage)
local EternityCityPhotoZones = require(script.Parent.EternityCityPhotoZones)
local FestivalCountdownService = require(ServerScriptService:WaitForChild("FestivalCountdownService"))
local EternityCityQuestBoard = require(script.Parent.EternityCityQuestBoard)

local EternityCityWorldBuilder = {}

-- Hybrid static-skip: ถ้ามี static model ใน UtopiaStatic folder ให้ข้าม greybox
local function hasStatic(staticName: string): boolean
	local staticFolder = workspace:FindFirstChild("UtopiaStatic")
	if not staticFolder or not staticFolder:IsA("Folder") then
		return false
	end
	return staticFolder:FindFirstChild(staticName) ~= nil
end

local MARINA_CENTER = Vector3.new(180, 0, -80)
local AURORA_ORIGIN = CFrame.new(0, 0, -120)

local function orientSanctuarySpawns(parent: Instance)
	for _, inst in parent:GetDescendants() do
		if inst:IsA("SpawnLocation") and string.find(inst.Name, "SanctuarySpawn") then
			local pos = inst.Position
			inst.CFrame = CFrame.lookAt(pos, Vector3.new(MARINA_CENTER.X, pos.Y, MARINA_CENTER.Z))
		end
	end
end

local function buildMountainBackdrop(_profile: WorldBuildConfig.PlaceProfile)
	local terrain = workspace.Terrain
	if not terrain then
		return
	end
	terrain:FillBlock(CFrame.new(-220, 40, -280), Vector3.new(280, 120, 180), Enum.Material.Rock)
	terrain:FillBlock(CFrame.new(-180, 70, -320), Vector3.new(200, 80, 140), Enum.Material.Snow)
end

local function buildCoastline(profile: WorldBuildConfig.PlaceProfile)
	local terrain = workspace.Terrain
	if not terrain then
		return
	end
	terrain:FillBlock(CFrame.new(200, -4, 0), Vector3.new(220, 8, 620), Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(0, -2, 0), Vector3.new(620, 4, 36), Enum.Material.Water)
	terrain:FillBlock(CFrame.new(160, -3, -120), Vector3.new(120, 6, 120), Enum.Material.Water)
end

local function buildMarinaRing(parent: Instance, profile: WorldBuildConfig.PlaceProfile, budget: WorldBuildBudget.Budget)
	if hasStatic("Static_MarinaRing") then
		print("[Utopia] skip greybox: MarinaRing (static found)")
		return
	end
	local marina = EternityCityMarinaLandmark.build({
		parent = parent,
		profile = profile,
		budget = budget,
		center = MARINA_CENTER,
	})
	EternityCityAccessGuard.tagDistrict(marina, 11, "MarinaRing")
end

local function buildAuroraSpireCluster(parent: Instance, profile: WorldBuildConfig.PlaceProfile, budget: WorldBuildBudget.Budget)
	if hasStatic("Static_AuroraSpire") then
		print("[Utopia] skip greybox: AuroraSpire (static found)")
		return
	end
	local district = EternityCityAuroraSpireLandmark.build({
		parent = parent,
		profile = profile,
		budget = budget,
		origin = AURORA_ORIGIN,
	})
	EternityCityAccessGuard.tagDistrict(district, 0, "AuroraSpire")
end

local MEGAMALL_BASE = CFrame.new(-30, 0, -150)

local function buildAuroraMegaMall(parent: Instance, profile: WorldBuildConfig.PlaceProfile, budget: WorldBuildBudget.Budget)
	if hasStatic("Static_AuroraMegaMall") then
		print("[Utopia] skip greybox: AuroraMegaMall (static found)")
		return
	end
	local district = EternityCityAuroraMegaMallLandmark.build({
		parent = parent,
		profile = profile,
		budget = budget,
		base = MEGAMALL_BASE,
	})
	EternityCityAccessGuard.tagDistrict(district, 20, "AuroraMegaMall")
end

local function buildCanalPromenade(parent: Instance, profile: WorldBuildConfig.PlaceProfile, budget: WorldBuildBudget.Budget)
	if hasStatic("Static_CanalPromenade") then
		print("[Utopia] skip greybox: CanalPromenade (static found)")
		return
	end
	local district = EternityCityCanalPromenadeLandmark.build({
		parent = parent,
		profile = profile,
		budget = budget,
	})
	EternityCityAccessGuard.tagDistrict(district, 11, "CanalPromenade")
end

local function buildReflectivePlaza(parent: Instance, profile: WorldBuildConfig.PlaceProfile, budget: WorldBuildBudget.Budget)
	if hasStatic("Static_ReflectivePlaza") then
		print("[Utopia] skip greybox: ReflectivePlaza (static found)")
		return
	end
	local plaza = Instance.new("Folder")
	plaza.Name = "ReflectivePlaza"
	plaza.Parent = parent

	local pad = Instance.new("Part")
	pad.Name = "ReflectivePad"
	pad.Size = Vector3.new(90, 0.4, 90)
	pad.CFrame = CFrame.new(0, 0.3, -35)
	pad.Anchored = true
	pad.Color = profile.Palette.Midnight
	pad.Material = Enum.Material.Glass
	pad.Reflectance = 0.35
	pad.Parent = plaza
	WorldBuildBudget:add(budget, 1)

	for i = -2, 2 do
		local lane = Instance.new("Part")
		lane.Name = "GlowLane_" .. i
		lane.Size = Vector3.new(80, 0.2, 1.2)
		lane.CFrame = CFrame.new(i * 8, 0.45, -35)
		lane.Anchored = true
		lane.Color = profile.Palette.Gold
		lane.Material = Enum.Material.Neon
		lane.Parent = plaza
		WorldBuildBudget:add(budget, 1)
	end
end

local SKYRAIL_ORIGIN = CFrame.new(0, 0, 40)

local function buildSkyRailPlaza(parent: Instance, profile: WorldBuildConfig.PlaceProfile, budget: WorldBuildBudget.Budget)
	if hasStatic("Static_SkyRailPlaza") then
		print("[Utopia] skip greybox: SkyRailPlaza (static found)")
		return
	end
	local district = EternityCitySkyRailPlazaLandmark.build({
		parent = parent,
		profile = profile,
		budget = budget,
		origin = SKYRAIL_ORIGIN,
	})
	EternityCityAccessGuard.tagDistrict(district, 15, "SkyRailPlaza")

	-- Shuttle transit stop within the plaza
	local shuttleFolder = Instance.new("Folder")
	shuttleFolder.Name = "EternityTransit"
	shuttleFolder.Parent = district
	ShuttleGreyboxBuilder:BuildEternityVariant(shuttleFolder, SKYRAIL_ORIGIN * CFrame.new(0, 0, -35))
	WorldBuildBudget:add(budget, 60)
end

local function buildHoverShowroom(parent: Instance, profile: WorldBuildConfig.PlaceProfile, budget: WorldBuildBudget.Budget)
	if hasStatic("Static_HoverShowroom") then
		print("[Utopia] skip greybox: HoverShowroom (static found)")
		return
	end
	local showroom = Instance.new("Folder")
	showroom.Name = "HoverShowroom"
	showroom.Parent = parent
	EternityCityAccessGuard.tagDistrict(showroom, 11, "HoverShowroom")

	local pad = Instance.new("Part")
	pad.Name = "ShowroomPad"
	pad.Size = Vector3.new(100, 1, 60)
	pad.CFrame = CFrame.new(-90, 0.5, 20)
	pad.Anchored = true
	pad.Color = profile.Palette.Midnight
	pad.Material = Enum.Material.SmoothPlastic
	pad.Parent = showroom
	WorldBuildBudget:add(budget, 1)

	for i = 1, 4 do
		local slot = Instance.new("Part")
		slot.Name = "VehiclePad_" .. i
		slot.Size = Vector3.new(18, 0.5, 10)
		slot.CFrame = CFrame.new(-110 + i * 22, 1.2, 20)
		slot.Anchored = true
		slot.Color = profile.Palette.Gold
		slot.Material = Enum.Material.Neon
		slot.Transparency = 0.4
		slot.Parent = showroom
		slot:SetAttribute("ShowroomSlot", i)
		WorldBuildBudget:add(budget, 1)
	end
end

local function buildVehicleShop(parent: Instance, profile: WorldBuildConfig.PlaceProfile, budget: WorldBuildBudget.Budget)
	if hasStatic("Static_VehicleShop") then
		print("[Utopia] skip greybox: VehicleShop (static found)")
		return
	end
local shop = Instance.new("Folder")
shop.Name = "EternityPremiumShop"
shop.Parent = parent
	EternityCityAccessGuard.tagDistrict(shop, 15, "PremiumShop")

	local building = Instance.new("Part")
	building.Name = "ShopHall"
	building.Size = Vector3.new(36, 16, 24)
	building.CFrame = CFrame.new(50, 8, -20)
	building.Anchored = true
	building.Color = profile.Palette.Slate
	building.Material = Enum.Material.SmoothPlastic
	building.Parent = shop
	WorldBuildBudget:add(budget, 1)

	local advisor = Instance.new("Part")
	advisor.Name = "VehicleAdvisor"
	advisor.Size = Vector3.new(4, 8, 4)
	advisor.CFrame = CFrame.new(50, 4, -8)
	advisor.Anchored = true
	advisor.Color = profile.Palette.Cyan
	advisor.Material = Enum.Material.Neon
	advisor.Parent = shop
	advisor:SetAttribute("NpcRole", "VehicleAdvisor")

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PremiumShopPrompt"
	prompt.ActionText = "Open Premium Shop"
	prompt.ObjectText = "Vehicle Advisor"
	prompt.MaxActivationDistance = 12
	prompt.Parent = advisor

	local weaponPedestal = Instance.new("Part")
	weaponPedestal.Name = "WeaponShowcase"
	weaponPedestal.Size = Vector3.new(20, 1, 20)
	weaponPedestal.CFrame = CFrame.new(70, 0.5, -20)
	weaponPedestal.Anchored = true
	weaponPedestal.Color = profile.Palette.Gold
	weaponPedestal.Material = Enum.Material.Neon
	weaponPedestal.Transparency = 0.5
	weaponPedestal.Parent = shop
	weaponPedestal:SetAttribute("WeaponGalleryGreybox", true)
	WorldBuildBudget:add(budget, 2)
end

local TWILIGHT_ORIGIN = CFrame.new(-100, 0, 80)

local function buildTwilightOverpass(parent: Instance, profile: WorldBuildConfig.PlaceProfile, budget: WorldBuildBudget.Budget)
	if hasStatic("Static_TwilightOverpass") then
		print("[Utopia] skip greybox: TwilightOverpass (static found)")
		return
	end
	local district = EternityCityTwilightOverpassLandmark.build({
		parent = parent,
		profile = profile,
		budget = budget,
		origin = TWILIGHT_ORIGIN,
	})
	EternityCityAccessGuard.tagDistrict(district, 10, "TwilightOverpass")
end

local function buildMarinaShowroomStrip(parent: Instance, profile: WorldBuildConfig.PlaceProfile, budget: WorldBuildBudget.Budget)
	if hasStatic("Static_MarinaShowroom") then
		print("[Utopia] skip greybox: MarinaShowroom (static found)")
		return
	end
	EternityCityMarinaShowroomLandmark.build({
		parent = parent,
		profile = profile,
		budget = budget,
	})
end

-- Blueprint §4.1: pure builder — สร้าง part แล้วคืน BuildResult
-- pcall + WorldBuildState ย้ายขึ้น BuildOrchestrator (จุดเดียวที่ set state)
function EternityCityWorldBuilder:Build(_ctx: WorldBuilderTypes.BuildContext?): WorldBuilderTypes.BuildResult
	if not WorldPlaceGuard:ShouldBuild("EternityCity") then
		warn("[Utopia] EternityCityWorldBuilder skipped — ShouldBuild=false PlaceId=", game.PlaceId)
		return WorldBuilderTypes.skip("not this place")
	end
	if WorldPlaceGuard:ModelExists("UtopiaEternityCity") then
		print("[Utopia] Eternity City already built — skipping")
		return WorldBuilderTypes.skip("UtopiaEternityCity already built")
	end

	print("[Utopia] Eternity City build starting… PlaceId=", game.PlaceId)

	local profile = WorldBuildConfig:GetProfile("EternityCity")
	local budget = WorldBuildBudget:new(profile.MaxParts)

	local model = Instance.new("Model")
	model.Name = "UtopiaEternityCity"
	model.Parent = workspace

	WorldBuildShared:makeGround(model, profile.GroundSizeStuds, profile.Palette.Twilight, Enum.Material.Slate)
	WorldBuildBudget:add(budget, 1)

	local sanctuaryRadius = WorldBuildShared:getSanctuaryRadius("EternityCity")
	WorldBuildShared:makeSanctuaryZone(model, sanctuaryRadius, budget, profile)
	WorldBuildShared:addSanctuarySpawns(model, GameConfig.Sanctuary.EternityCityMinSpawnPoints, sanctuaryRadius, budget)
	orientSanctuarySpawns(model)
	WorldBuildShared:buildOrganicCanopy(CFrame.new(0, 0, 0), model, profile, budget)

	buildCoastline(profile)
	buildMountainBackdrop(profile)
	buildMarinaRing(model, profile, budget)
	buildAuroraSpireCluster(model, profile, budget)
	buildAuroraMegaMall(model, profile, budget)
	buildCanalPromenade(model, profile, budget)
	buildSkyRailPlaza(model, profile, budget)
	buildHoverShowroom(model, profile, budget)
	buildVehicleShop(model, profile, budget)
	buildTwilightOverpass(model, profile, budget)
	buildMarinaShowroomStrip(model, profile, budget)
	CommerceDistrictBuilder:BuildAll(model, profile, budget)

	LoadoutPlazaKit.addPlaza(model, {
		origin = Vector3.new(0, 0, 42),
		wardrobeLabel = "Eternity Wardrobe",
		mirrorLabel = "Plaza Mirror",
		autoRotate = true,
	})

	EternityCityLighting.apply(model, profile.Palette)

	PrismKeyPickupKit.addPickup({
		pickupId = "eternity_canal_gate_key_11",
		keyNumber = 11,
		position = Vector3.new(80, 3, -40),
		parent = model,
	})
	PrismKeyPickupKit.addPickup({
		pickupId = "eternity_skyrail_gate_key_15",
		keyNumber = 15,
		position = Vector3.new(-40, 6, 60),
		parent = model,
	})
	PrismKeyPickupKit.addPickup({
		pickupId = "eternity_mall_gate_key_20",
		keyNumber = 20,
		position = Vector3.new(-30, 12, -140),
		parent = model,
	})

	EternityCityAccessGuard.start(model)

	ShowroomVehicleDisplay.setup(model)
	EternityCityFestivalStage.setup(model, profile.Palette)
	EternityCityPhotoZones.setup(model, profile.Palette)
	FestivalCountdownService.setup(model, profile.Palette)
	EternityCityQuestBoard.setup(model, profile.Palette)

	WorldBuildBudget:report("EternityCity", budget)

	print("[Utopia] Eternity City built — aurora · marina · canal · gates · Sky Lounge 50 · loadout plaza")
	return WorldBuilderTypes.success(model)
end

return EternityCityWorldBuilder
