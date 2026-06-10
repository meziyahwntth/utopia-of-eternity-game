--!strict
--[[
	Nocturne Alley — twilight arches + meet point.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

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

local ArchRibKit = require(ServerStorage:WaitForChild("WorldKits"):WaitForChild("ArchRibKit"))

local NocturneWorldBuilder = {}

-- Blueprint §4.1: pure builder — สร้าง part แล้วคืน BuildResult
function NocturneWorldBuilder:Build(_ctx: WorldBuilderTypes.BuildContext?): WorldBuilderTypes.BuildResult
	if not WorldPlaceGuard:ShouldBuild("Nocturne") then
		return WorldBuilderTypes.skip("not this place")
	end
	if WorldPlaceGuard:ModelExists("UtopiaNocturne") then
		return WorldBuilderTypes.skip("UtopiaNocturne already built")
	end

	local profile = WorldBuildConfig:GetProfile("Nocturne")
	local budget = WorldBuildBudget:new(profile.MaxParts)

	Lighting.ClockTime = 18.5
	Lighting.Brightness = 1.4
	Lighting.Ambient = Color3.fromRGB(40, 30, 60)

	local model = Instance.new("Model")
	model.Name = "UtopiaNocturne"
	model.Parent = workspace

	WorldBuildShared:makeGround(model, profile.GroundSizeStuds, profile.Palette.Twilight, Enum.Material.Slate)
	WorldBuildBudget:add(budget, 1)

	local radius = WorldBuildShared:getSanctuaryRadius("Nocturne")
	WorldBuildShared:makeSanctuaryZone(model, radius, budget, profile)
	WorldBuildShared:addSanctuarySpawns(model, 3, radius, budget)
	WorldBuildShared:buildOrganicCanopy(CFrame.new(0, 0, 0), model, profile, budget)

	for i = 1, 5 do
		local x = -60 + i * 24
		OrganicCSGBuilder:createArch(CFrame.new(x, 0, -30), 18, 16, 2.5, {
			color = profile.Palette.Pearl,
			parent = model,
			name = "AlleyArch_" .. i,
		})
		ArchRibKit:Create(i + 2, CFrame.new(x, 0, -30), { parent = model, budget = budget })
	end

	local meetRing: { Vector3 } = {}
	for i = 0, 24 do
		local a = (i / 24) * math.pi * 2
		table.insert(meetRing, Vector3.new(math.cos(a) * 35, 2, math.sin(a) * 35))
	end
	MicroCurveBuilder:fillArc(meetRing, 1.5, {
		voxelStuds = profile.VoxelStuds,
		color = profile.Palette.Cyan,
		material = Enum.Material.Neon,
		parent = model,
		budget = budget,
	})

	LoadoutPlazaKit.addPlaza(model, {
		origin = Vector3.new(0, 0, 18),
		wardrobeLabel = "Nocturne Wardrobe",
		mirrorLabel = "Alley Mirror",
		autoRotate = true,
	})

	PrismKeyPickupKit.addPickup({
		pickupId = "nocturne_meet_key_3",
		keyNumber = 3,
		position = Vector3.new(0, 4, 35),
		parent = model,
	})

	WorldBuildBudget:report("Nocturne", budget)
	print("[Utopia] Nocturne microcurve world built")
	return WorldBuilderTypes.success(model)
end

return NocturneWorldBuilder
