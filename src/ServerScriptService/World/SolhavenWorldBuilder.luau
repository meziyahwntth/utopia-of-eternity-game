--!strict
--[[
	Solhaven — terraced garden domes + curved canal.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))

local OrganicCSGBuilder = require(script.Parent.OrganicCSGBuilder)
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)
local WorldBuildShared = require(script.Parent.WorldBuildShared)
local WorldPlaceGuard = require(script.Parent.WorldPlaceGuard)
local LoadoutPlazaKit = require(script.Parent.LoadoutPlazaKit)
local PrismKeyPickupKit = require(script.Parent.PrismKeyPickupKit)

local ArchRibKit = require(ServerStorage:WaitForChild("WorldKits"):WaitForChild("ArchRibKit"))

local SolhavenWorldBuilder = {}

function SolhavenWorldBuilder:Build()
	if not WorldPlaceGuard:ShouldBuild("Solhaven") then
		return
	end
	if WorldPlaceGuard:ModelExists("UtopiaSolhaven") then
		return
	end

	local profile = WorldBuildConfig:GetProfile("Solhaven")
	local budget = WorldBuildBudget:new(profile.MaxParts)

	local model = Instance.new("Model")
	model.Name = "UtopiaSolhaven"
	model.Parent = workspace

	WorldBuildShared:makeGround(model, profile.GroundSizeStuds, Color3.fromRGB(60, 90, 50), Enum.Material.Grass)
	WorldBuildBudget:add(budget, 1)

	local radius = WorldBuildShared:getSanctuaryRadius("Solhaven")
	WorldBuildShared:makeSanctuaryZone(model, radius, budget, profile)
	WorldBuildShared:addSanctuarySpawns(model, 3, radius, budget)
	WorldBuildShared:buildOrganicCanopy(CFrame.new(0, 0, 0), model, profile, budget)

	for stage = 1, 3 do
		local y = stage * 6
		local r = 30 - stage * 6
		OrganicCSGBuilder:createDome(Vector3.new(0, y, 40 + stage * 25), r, {
			color = profile.Palette.Pearl,
			parent = model,
			name = "GardenStage_" .. stage,
		})
		MicroCurveBuilder:fillCircle(Vector3.new(0, y + 1, 40 + stage * 25), r, y + 1.5, {
			voxelStuds = profile.VoxelStuds,
			color = profile.Palette.Gold,
			material = Enum.Material.Neon,
			parent = model,
			filled = false,
			budget = budget,
		})
	end

	local canal: { Vector3 } = {}
	for i = 0, 16 do
		local t = i / 16
		table.insert(canal, Vector3.new(-80 + t * 160, 1, math.sin(t * math.pi * 3) * 20))
	end
	MicroCurveBuilder:fillArc(canal, 2.5, {
		voxelStuds = profile.VoxelStuds,
		color = profile.Palette.Cyan,
		material = Enum.Material.Glass,
		parent = model,
		budget = budget,
	})

	ArchRibKit:Create(2, CFrame.new(0, 0, -50), { parent = model, budget = budget })

	LoadoutPlazaKit.addPlaza(model, {
		origin = Vector3.new(0, 0, -18),
		wardrobeLabel = "Solhaven Wardrobe",
		mirrorLabel = "Garden Mirror",
		autoRotate = true,
	})

	PrismKeyPickupKit.addPickup({
		pickupId = "solhaven_garden_key_2",
		keyNumber = 2,
		position = Vector3.new(0, 8, 65),
		parent = model,
	})

	WorldBuildBudget:report("Solhaven", budget)
	print("[Utopia] Solhaven microcurve world built")
end

return SolhavenWorldBuilder
