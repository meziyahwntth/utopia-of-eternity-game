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
local EternityCityFashionStage = require(script.Parent.EternityCityFashionStage)
local EternityTerrainSetup = require(script.Parent.EternityTerrainSetup)
local UtopiaPlazaBuilder = require(script.Parent.UtopiaPlazaBuilder)
local EternityTowerBuilder = require(script.Parent.EternityTowerBuilder)
local HeroMeshKit = require(script.Parent.HeroMeshKit)
local ShopPromoterNpcKit = require(script.Parent.ShopPromoterNpcKit)
local SkyCityLift = require(script.Parent.SkyCityLift)

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

local function buildMarinaRing(
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
	center: Vector3
)
	if hasStatic("Static_MarinaRing") then
		print("[Utopia] skip greybox: MarinaRing (static found)")
		return
	end
	local marina = EternityCityMarinaLandmark.build({
		parent = parent,
		profile = profile,
		budget = budget,
		center = center,
	})
	EternityCityAccessGuard.tagDistrict(marina, 11, "MarinaRing")
end

local function buildAuroraSpireCluster(
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
	origin: CFrame
)
	if hasStatic("Static_AuroraSpire") then
		print("[Utopia] skip greybox: AuroraSpire (static found)")
		return
	end
	local district = EternityCityAuroraSpireLandmark.build({
		parent = parent,
		profile = profile,
		budget = budget,
		origin = origin,
	})
	EternityCityAccessGuard.tagDistrict(district, 0, "AuroraSpire")
end

local function buildAuroraMegaMall(
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
	base: CFrame
)
	if hasStatic("Static_AuroraMegaMall") then
		print("[Utopia] skip greybox: AuroraMegaMall (static found)")
		return
	end
	local district = EternityCityAuroraMegaMallLandmark.build({
		parent = parent,
		profile = profile,
		budget = budget,
		base = base,
	})
	EternityCityAccessGuard.tagDistrict(district, 20, "AuroraMegaMall")
end

local function buildCanalPromenade(
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
	pathOffset: Vector3
)
	if hasStatic("Static_CanalPromenade") then
		print("[Utopia] skip greybox: CanalPromenade (static found)")
		return
	end
	local district = EternityCityCanalPromenadeLandmark.build({
		parent = parent,
		profile = profile,
		budget = budget,
		pathOffset = pathOffset,
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

local function buildSkyRailPlaza(
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
	origin: CFrame
)
	if hasStatic("Static_SkyRailPlaza") then
		print("[Utopia] skip greybox: SkyRailPlaza (static found)")
		return
	end
	local district = EternityCitySkyRailPlazaLandmark.build({
		parent = parent,
		profile = profile,
		budget = budget,
		origin = origin,
	})
	EternityCityAccessGuard.tagDistrict(district, 15, "SkyRailPlaza")

	local shuttleFolder = Instance.new("Folder")
	shuttleFolder.Name = "UtopiaShuttle"
	shuttleFolder.Parent = district
	ShuttleGreyboxBuilder:BuildEternityVariant(shuttleFolder, origin * CFrame.new(0, 0, -35))
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

local function buildTwilightOverpass(
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
	origin: CFrame
)
	if hasStatic("Static_TwilightOverpass") then
		print("[Utopia] skip greybox: TwilightOverpass (static found)")
		return
	end
	local district = EternityCityTwilightOverpassLandmark.build({
		parent = parent,
		profile = profile,
		budget = budget,
		origin = origin,
	})
	EternityCityAccessGuard.tagDistrict(district, 10, "TwilightOverpass")
end

local function buildUtopiaPlaza(
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
	base: CFrame
)
	if parent:FindFirstChild("UtopiaPlaza") then
		return parent:FindFirstChild("UtopiaPlaza") :: Folder
	end
	if hasStatic("Static_UtopiaPlaza") then
		print("[Utopia] skip greybox: UtopiaPlaza (static found)")
		return nil
	end
	local district = UtopiaPlazaBuilder.build({
		parent = parent,
		profile = profile,
		budget = budget,
		base = base,
	})
	EternityCityAccessGuard.tagDistrict(district, 22, "UtopiaPlaza")
	local parts = district:GetAttribute("PartCount")
	print(string.format("[UtopiaPlaza] built parts=%s", tostring(parts or "?")))
	return district
end

local function buildEternityTower(
	parent: Instance,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget,
	base: CFrame
)
	if parent:FindFirstChild("EternityTower") then
		return parent:FindFirstChild("EternityTower") :: Folder
	end
	if hasStatic("Static_EternityTower") then
		print("[Utopia] skip greybox: EternityTower (static found)")
		return nil
	end
	local district = EternityTowerBuilder.build({
		parent = parent,
		profile = profile,
		budget = budget,
		base = base,
	})
	EternityCityAccessGuard.tagDistrict(district, 18, "EternityTower")
	local parts = district:GetAttribute("PartCount")
	print(string.format("[EternityTower] built parts=%s", tostring(parts or "?")))
	return district
end

local function applyHeroMeshActive(model: Model, plazaDistrict: Folder?, towerDistrict: Folder?)
	local keys: { string } = {}
	if plazaDistrict then
		table.insert(keys, "UtopiaPlaza")
	end
	if towerDistrict then
		table.insert(keys, "EternityTower")
	end
	if model:FindFirstChild("UtopiaPlaza") and not table.find(keys, "UtopiaPlaza") then
		table.insert(keys, "UtopiaPlaza")
	end
	if model:FindFirstChild("EternityTower") and not table.find(keys, "EternityTower") then
		table.insert(keys, "EternityTower")
	end
	if #keys > 0 then
		model:SetAttribute("HeroMeshActive", table.concat(keys, ","))
	end
end

local function resolveHeroLandmarkBases(): (CFrame, CFrame)
	local utopiaPlazaBase = CFrame.new(EternityTerrainSetup.getLandmarkPosition("UtopiaPlaza", Vector3.new(-134, 72, -68)))
	local eternityTowerBase = CFrame.new(EternityTerrainSetup.getLandmarkPosition("EternityTower", Vector3.new(60, 72, 140)))
	return utopiaPlazaBase, eternityTowerBase
end

local GREYBOX_MARKER = "AuroraMegaMall"

local function findEternityCityModels(): { Model }
	local out: { Model } = {}
	for _, child in workspace:GetChildren() do
		if child:IsA("Model") and child.Name == "UtopiaEternityCity" then
			table.insert(out, child)
		end
	end
	return out
end

local function pickCanonicalCity(models: { Model }): Model
	if #models == 1 then
		return models[1]
	end
	local best = models[1]
	local bestScore = -1
	for _, candidate in models do
		local score = 0
		if candidate:FindFirstChild("UtopiaPlaza") then
			score += 1000
		end
		if candidate:FindFirstChild("EternityTower") then
			score += 1000
		end
		if candidate:FindFirstChild(GREYBOX_MARKER) or candidate:FindFirstChild("MarinaRing") then
			score += 100
		end
		score += #candidate:GetChildren()
		if score > bestScore then
			bestScore = score
			best = candidate
		end
	end
	return best
end

local function removeDuplicateCities(keep: Model)
	for _, model in findEternityCityModels() do
		if model ~= keep then
			warn("[Utopia] removing duplicate UtopiaEternityCity — kept canonical model")
			model:Destroy()
		end
	end
end

-- rbxlx saved workspace may hydrate a frame after GameBootstrap starts
local function waitForEternityCityModel(timeoutSec: number): Model?
	local deadline = os.clock() + timeoutSec
	while os.clock() < deadline do
		local models = findEternityCityModels()
		if #models > 0 then
			return pickCanonicalCity(models)
		end
		task.wait(0.05)
	end
	return nil
end

local function hasGreyboxCore(model: Model): boolean
	return model:FindFirstChild(GREYBOX_MARKER) ~= nil or model:FindFirstChild("MarinaRing") ~= nil
end

local function assertHeroMeshContract(model: Model)
	local missing: { string } = {}
	if model:FindFirstChild("UtopiaPlaza") == nil then
		table.insert(missing, "UtopiaPlaza")
	end
	if model:FindFirstChild("EternityTower") == nil then
		table.insert(missing, "EternityTower")
	end
	if #missing > 0 then
		warn("[Utopia] HERO_MESH_CONTRACT_FAIL: missing " .. table.concat(missing, ", ") .. " under UtopiaEternityCity")
	end
	if model:GetAttribute("HeroMeshActive") == nil then
		warn("[Utopia] HERO_MESH_CONTRACT_FAIL: HeroMeshActive attribute is nil after Build")
	end
end

local function attachHeroMeshSafe(district: Folder, key: string, baseCf: CFrame)
	local ok, err = pcall(function()
		local result = HeroMeshKit.attachExterior(district, key, baseCf)
		if result then
			district:SetAttribute("HeroMeshSource", result.source)
		else
			warn(string.format("[Utopia] hero mesh exterior skipped for %s (procedural district kept)", key))
		end
	end)
	if not ok then
		warn(string.format("[Utopia] hero mesh exterior failed for %s (procedural district kept): %s", key, tostring(err)))
	end
end

local function ensureHeroLandmarks(
	model: Model,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget
): (Folder?, Folder?)
	local utopiaPlazaBase, eternityTowerBase = resolveHeroLandmarkBases()

	-- Step 1: procedural districts (must succeed — never wrapped in mesh pcall)
	local plazaDistrict = buildUtopiaPlaza(model, profile, budget, utopiaPlazaBase)
	local towerDistrict = buildEternityTower(model, profile, budget, eternityTowerBase)
	applyHeroMeshActive(model, plazaDistrict, towerDistrict)

	-- Step 2: hero mesh exterior (optional — pcall per landmark)
	if plazaDistrict then
		attachHeroMeshSafe(plazaDistrict, "UtopiaPlaza", utopiaPlazaBase)
	end
	if towerDistrict then
		attachHeroMeshSafe(towerDistrict, "EternityTower", eternityTowerBase)
	end

	-- Landmark #4: Sky Rail Plaza — procedural district สร้างไว้แล้วใน Build flow
	-- (EternityCitySkyRailPlazaLandmark) แค่ครอบ hero mesh station เพิ่ม
	local skyRailDistrict = model:FindFirstChild("SkyRailPlaza")
	if skyRailDistrict and skyRailDistrict:IsA("Folder") and not skyRailDistrict:FindFirstChild("SkyRailPlazaHeroMesh") then
		local skyRailBase = CFrame.new(EternityTerrainSetup.getLandmarkPosition("SkyRailOrigin", Vector3.new(0, 0, 40)))
		attachHeroMeshSafe(skyRailDistrict, "SkyRailPlaza", skyRailBase)
	end

	-- Landmark #5: Aurora MegaMall — hero mesh station (augment path)
	local auroraDistrict = model:FindFirstChild("AuroraMegaMall")
	if auroraDistrict and auroraDistrict:IsA("Folder") and not auroraDistrict:FindFirstChild("AuroraMegaMallHeroMesh") then
		local auroraBase = CFrame.new(EternityTerrainSetup.getLandmarkPosition("MegaMallBase", Vector3.new(-30, 0, -150)))
		attachHeroMeshSafe(auroraDistrict, "AuroraMegaMall", auroraBase)
	end

	return plazaDistrict, towerDistrict
end

local function ensureHeroLandmarksSafe(
	model: Model,
	profile: WorldBuildConfig.PlaceProfile,
	budget: WorldBuildBudget.Budget
)
	ensureHeroLandmarks(model, profile, budget)
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

	EternityTerrainSetup.prepareForBuild()

	local profile = WorldBuildConfig:GetProfile("EternityCity")
	local budget = WorldBuildBudget:new(profile.MaxParts)

	-- Wait for rbxlx-hydrated city; avoid creating a duplicate while saved workspace loads
	local model = waitForEternityCityModel(3)
	local createdNew = false
	if model then
		model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		removeDuplicateCities(model)
	else
		model = Instance.new("Model")
		model.Name = "UtopiaEternityCity"
		model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		model.Parent = workspace
		createdNew = true
		task.wait(0.15)
		local lateModels = findEternityCityModels()
		if #lateModels > 1 then
			model = pickCanonicalCity(lateModels)
			removeDuplicateCities(model)
			createdNew = false
		end
	end

	local needsPlaza = model:FindFirstChild("UtopiaPlaza") == nil
	local needsTower = model:FindFirstChild("EternityTower") == nil
	local hasGreybox = hasGreyboxCore(model)

	if not createdNew and hasGreybox and not needsPlaza and not needsTower then
		print("[Utopia] Eternity City already built — skipping")
		assertHeroMeshContract(model)
		SkyCityLift.apply(model, profile.SkyAltitude)
		return WorldBuilderTypes.skip("UtopiaEternityCity already built")
	end

	if not createdNew and hasGreybox and (needsPlaza or needsTower) then
		print(
			string.format(
				"[Utopia] Eternity City exists — augmenting hero landmarks (plaza=%s tower=%s)",
				tostring(needsPlaza),
				tostring(needsTower)
			)
		)
		ensureHeroLandmarksSafe(model, profile, budget)
		assertHeroMeshContract(model)
		WorldBuildBudget:report("EternityCity-augment", budget)
		SkyCityLift.apply(model, profile.SkyAltitude)
		pcall(function()
			require(script.Parent.UtopiaUndergroundRaceBuilder).build(model)
		end)
		return WorldBuilderTypes.success(model)
	end

	print("[Utopia] Eternity City build starting… PlaceId=", game.PlaceId)

	local useTerrain = EternityTerrainSetup.hasRealTerrain()

	if not useTerrain then
		WorldBuildShared:makeGround(model, profile.GroundSizeStuds, profile.Palette.Twilight, Enum.Material.Slate)
		WorldBuildBudget:add(budget, 1)
		buildCoastline(profile)
		buildMountainBackdrop(profile)
	else
		model:SetAttribute("TerrainLayout", "imported-" .. GameConfig.TerrainProfile.Version)
	end

	local marinaCenter = EternityTerrainSetup.getLandmarkPosition("MarinaCenter", MARINA_CENTER)
	local auroraOrigin = CFrame.new(EternityTerrainSetup.getLandmarkPosition("AuroraOrigin", Vector3.new(0, 0, -120)))
	local skyRailOrigin = CFrame.new(EternityTerrainSetup.getLandmarkPosition("SkyRailOrigin", Vector3.new(0, 0, 40)))
	local twilightOrigin = CFrame.new(EternityTerrainSetup.getLandmarkPosition("TwilightOrigin", Vector3.new(-100, 0, 80)))
	local megaMallBase = CFrame.new(EternityTerrainSetup.getLandmarkPosition("MegaMallBase", Vector3.new(-30, 0, -150)))
	local loadoutPlaza = EternityTerrainSetup.getLandmarkPosition("LoadoutPlaza", Vector3.new(0, 0, 42))
	local fashionCenter = EternityTerrainSetup.getLandmarkPosition("FashionStage", Vector3.new(-130, 1.2, 115))
	local canalOffset = if useTerrain
		then GameConfig.TerrainProfile.Landmarks.CanalPathOffset
		else Vector3.new(0, 0, 0)

	local function orientSpawnsToMarina(parent: Instance)
		for _, inst in parent:GetDescendants() do
			if inst:IsA("SpawnLocation") and string.find(inst.Name, "SanctuarySpawn") then
				local pos = inst.Position
				inst.CFrame = CFrame.lookAt(pos, Vector3.new(marinaCenter.X, pos.Y, marinaCenter.Z))
			end
		end
	end

	local sanctuaryRadius = WorldBuildShared:getSanctuaryRadius("EternityCity")
	WorldBuildShared:makeSanctuaryZone(model, sanctuaryRadius, budget, profile)
	WorldBuildShared:addSanctuarySpawns(model, GameConfig.Sanctuary.EternityCityMinSpawnPoints, sanctuaryRadius, budget)
	orientSpawnsToMarina(model)

	-- Hero landmarks before heavy MicroVoxel/organic passes (budget/time guard)
	ensureHeroLandmarksSafe(model, profile, budget)

	WorldBuildShared:buildOrganicCanopy(CFrame.new(auroraOrigin.Position), model, profile, budget)

	buildMarinaRing(model, profile, budget, marinaCenter)
	buildAuroraSpireCluster(model, profile, budget, auroraOrigin)
	buildAuroraMegaMall(model, profile, budget, megaMallBase)
	buildCanalPromenade(model, profile, budget, canalOffset)
	buildSkyRailPlaza(model, profile, budget, skyRailOrigin)
	do -- Landmark #4 hero mesh — fresh-build path (augment path อยู่ใน ensureHeroLandmarks)
		local skyRailDistrict = model:FindFirstChild("SkyRailPlaza")
		if skyRailDistrict and skyRailDistrict:IsA("Folder") and not skyRailDistrict:FindFirstChild("SkyRailPlazaHeroMesh") then
			attachHeroMeshSafe(skyRailDistrict, "SkyRailPlaza", skyRailOrigin)
		end
	end
	do -- Landmark #5 Aurora MegaMall hero mesh — fresh-build path
		local auroraDistrict = model:FindFirstChild("AuroraMegaMall")
		if auroraDistrict and auroraDistrict:IsA("Folder") and not auroraDistrict:FindFirstChild("AuroraMegaMallHeroMesh") then
			attachHeroMeshSafe(auroraDistrict, "AuroraMegaMall", megaMallBase)
		end
	end
	buildHoverShowroom(model, profile, budget)
	buildVehicleShop(model, profile, budget)
	buildTwilightOverpass(model, profile, budget, twilightOrigin)
	buildMarinaShowroomStrip(model, profile, budget)
	CommerceDistrictBuilder:BuildAll(model, profile, budget)

	LoadoutPlazaKit.addPlaza(model, {
		origin = loadoutPlaza,
		wardrobeLabel = "Eternity Wardrobe",
		mirrorLabel = "Plaza Mirror",
		autoRotate = true,
	})
	ShopPromoterNpcKit.addPromoter({
		parent = model,
		origin = loadoutPlaza,
		palette = profile.Palette,
		budget = budget,
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
	EternityCityFashionStage.setup(model, profile.Palette, fashionCenter)

	ensureHeroLandmarksSafe(model, profile, budget)
	assertHeroMeshContract(model)

	WorldBuildBudget:report("EternityCity", budget)

	SkyCityLift.apply(model, profile.SkyAltitude)
	pcall(function()
		require(script.Parent.UtopiaUndergroundRaceBuilder).build(model)
	end)
	print("[Utopia] Eternity City built — aurora · marina · canal · gates · Sky Lounge 50 · loadout plaza · underground GP · ลอยฟ้า")
	return WorldBuilderTypes.success(model)
end

return EternityCityWorldBuilder
