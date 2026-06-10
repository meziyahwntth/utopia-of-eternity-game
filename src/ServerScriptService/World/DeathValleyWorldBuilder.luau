--!strict
--[[
	หุบเขามรณะ — ดาวเคราะห์ Hellbound · cave · beacon · Spirit Tunnel
	Travel from Eternity City via Hyperdrive — docs/HELLBOUND-TRAVEL-AND-DEATH-VALLEY.md
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

local DeathValleyWorldBuilder = {}

-- Blueprint §4.1: pure builder — สร้าง part แล้วคืน BuildResult
function DeathValleyWorldBuilder:Build(_ctx: WorldBuilderTypes.BuildContext?): WorldBuilderTypes.BuildResult
	if not WorldPlaceGuard:ShouldBuild("DeathValley") then
		return WorldBuilderTypes.skip("not this place")
	end
	if WorldPlaceGuard:ModelExists("UtopiaDeathValley") then
		return WorldBuilderTypes.skip("UtopiaDeathValley already built")
	end

	local profile = WorldBuildConfig:GetProfile("DeathValley")
	local budget = WorldBuildBudget:new(profile.MaxParts)

	Lighting.ClockTime = 0
	Lighting.Brightness = 0.6
	Lighting.Ambient = Color3.fromRGB(20, 10, 30)

	local model = Instance.new("Model")
	model.Name = "UtopiaDeathValley"
	model.Parent = workspace

	WorldBuildShared:makeGround(model, profile.GroundSizeStuds, Color3.fromRGB(25, 20, 30), Enum.Material.Rock)
	WorldBuildBudget:add(budget, 1)

	local terrain = workspace.Terrain
	if terrain then
		terrain:FillBlock(CFrame.new(0, 30, -80), Vector3.new(200, 80, 40), Enum.Material.Rock)
		terrain:FillBall(Vector3.new(0, 15, -60), 25, Enum.Material.Air)
	end

	local radius = WorldBuildShared:getSanctuaryRadius("DeathValley")
	WorldBuildShared:makeSanctuaryZone(model, radius, budget, profile)
	WorldBuildShared:addSanctuarySpawns(model, 3, 90, budget)

	OrganicCSGBuilder:createDome(Vector3.new(0, 12, -55), 20, {
		color = Color3.fromRGB(40, 35, 50),
		material = Enum.Material.Rock,
		parent = model,
		name = "CaveMouth",
	})

	OrganicCSGBuilder:createSpire(Vector3.new(0, 0, 0), 45, 6, {
		color = profile.Palette.Amber,
		material = Enum.Material.Neon,
		parent = model,
		name = "LifeBeacon",
	})

	MicroCurveBuilder:fillCircle(Vector3.new(0, 1, 0), radius * 0.5, 1.5, {
		voxelStuds = profile.VoxelStuds,
		color = profile.Palette.Amber,
		material = Enum.Material.Neon,
		parent = model,
		filled = false,
		budget = budget,
	})

	local zones = Instance.new("Folder")
	zones.Name = "HellboundZones"
	zones.Parent = model

	local zoneNames = {
		"PeakColony",
		"UndermountainRail",
		"MilitaryResearchBase",
		"SpiritTunnel",
		"SpiritChamber_1",
		"SpiritChamber_2",
		"SpiritChamber_3",
		"DeathValleyCore",
	}
	for _, zoneName in zoneNames do
		local marker = Instance.new("Part")
		marker.Name = zoneName
		marker.Size = Vector3.new(6, 1, 6)
		marker.Anchored = true
		marker.CanCollide = false
		marker.Transparency = 0.85
		marker.Color = profile.Palette.Amber
		marker.Material = Enum.Material.Neon
		marker.Parent = zones
		marker:SetAttribute("Planet", "Hellbound")
		if string.find(zoneName, "SpiritChamber") then
			marker:SetAttribute("WalkOnly", true)
			marker:SetAttribute("VehiclesAllowed", false)
		end
	end

	WorldBuildBudget:report("DeathValley", budget)

	print("[Utopia-DV] Building Zone1...")
	local zone1Builder = require(script.Parent:WaitForChild("DeathValleyZone1Builder"))
	zone1Builder:Build(model, profile, budget)

	print("[Utopia-DV] Building KeyGhost...")
	local ghostBuilder = require(script.Parent:WaitForChild("DeathValleyKeyGhostBuilder"))
	ghostBuilder:Build(model)

	print("[Utopia-DV] Building Survival...")
	local survivalBuilder = require(script.Parent:WaitForChild("DeathValleySurvivalBuilder"))
	survivalBuilder:Build(model, profile, budget)

	print("[Utopia-DV] Building POIs (WhisperingGrove + HollowLake)...")
	local poiBuilder = require(script.Parent:WaitForChild("DeathValleyPOIBuilder"))
	poiBuilder:BuildPOIs(model, profile, budget)
	poiBuilder:BuildHorizonRings(model, profile, budget)
	poiBuilder:BuildHellboundPathStub(model, profile, budget)

	print("[Utopia-DV] Building Hellbound Travel...")
	local travelBuilder = require(script.Parent:WaitForChild("DeathValleyHellboundTravelBuilder"))
	travelBuilder:BuildPlayable(model, profile, budget)

	print("[Utopia-DV] Building PeakColony...")
	local colonyBuilder = require(script.Parent:WaitForChild("DeathValleyPeakColonyBuilder"))
	colonyBuilder:Build(model, profile, budget)

	print("[Utopia-DV] Building MilitaryBase...")
	local militaryBuilder = require(script.Parent:WaitForChild("DeathValleyMilitaryBaseBuilder"))
	militaryBuilder:Build(model, profile, budget)

	print("[Utopia-DV] Building MegaZones...")
	local megaBuilder = require(script.Parent:WaitForChild("DeathValleyMegaZonesBuilder"))
	megaBuilder:Build(model, profile, budget)
	megaBuilder:BuildWeeklyBossArena(model, profile, budget)

	print("[Utopia-DV] Building SpiritChambers...")
	local spiritBuilder = require(script.Parent:WaitForChild("DeathValleySpiritChamberBuilder"))
	spiritBuilder:Build(model, profile, budget)

	print("[Utopia] Death Valley built — Phase A+B+C+D + Zone 1–5 + travel pipeline + Peak Colony + Military Base + 3 Spirit Chambers")
	return WorldBuilderTypes.success(model)
end

return DeathValleyWorldBuilder
