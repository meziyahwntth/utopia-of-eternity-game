--!strict
--[[
	Shared helpers for all place world builders.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local MicroCurveBuilder = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MicroCurveBuilder"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))

local OrganicCSGBuilder = require(script.Parent.OrganicCSGBuilder)
local WorldBuildBudget = require(script.Parent.WorldBuildBudget)

local WorldBuildShared = {}

function WorldBuildShared:makeGround(parent: Instance, size: number, color: Color3, material: Enum.Material): Part
	local ground = Instance.new("Part")
	ground.Name = "WorldGround"
	ground.Size = Vector3.new(size, 1, size)
	ground.CFrame = CFrame.new(0, 0, 0)
	ground.Anchored = true
	ground.Color = color
	ground.Material = material
	ground.Parent = parent
	return ground
end

function WorldBuildShared:makeSanctuaryZone(
	parent: Instance,
	radius: number,
	budget: WorldBuildBudget.Budget,
	profile: WorldBuildConfig.PlaceProfile
)
	local disc = Instance.new("Part")
	disc.Name = "SanctuaryZone"
	disc.Size = Vector3.new(radius * 2, 0.4, radius * 2)
	disc.CFrame = CFrame.new(0, 0.3, 0)
	disc.Anchored = true
	disc.CanCollide = false
	disc.Transparency = 0.88
	disc.Color = profile.Palette.Cyan
	disc.Material = Enum.Material.Neon
	disc.Parent = parent
	WorldBuildBudget:add(budget, 1)

	MicroCurveBuilder:fillCircle(Vector3.new(0, 0.5, 0), radius, 0.55, {
		voxelStuds = profile.VoxelStuds,
		color = profile.Palette.Gold,
		material = Enum.Material.Neon,
		parent = parent,
		filled = false,
		collision = false,
		budget = budget,
	})
end

function WorldBuildShared:addSpawn(parent: Instance, name: string, position: Vector3): SpawnLocation
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = name
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(position)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = parent
	return spawn
end

function WorldBuildShared:addSanctuarySpawns(parent: Instance, count: number, radius: number, budget: WorldBuildBudget.Budget)
	for i = 1, count do
		local angle = (i / count) * math.pi * 2
		local pos = Vector3.new(math.cos(angle) * radius * 0.6, 1, math.sin(angle) * radius * 0.6)
		self:addSpawn(parent, "SanctuarySpawn_" .. i, pos)
		WorldBuildBudget:add(budget, 1)
	end
end

function WorldBuildShared:buildOrganicCanopy(origin: CFrame, parent: Instance, profile: WorldBuildConfig.PlaceProfile, budget: WorldBuildBudget.Budget)
	OrganicCSGBuilder:createDome((origin * CFrame.new(0, 8, 0)).Position, 14, {
		color = profile.Palette.Pearl,
		material = Enum.Material.SmoothPlastic,
		parent = parent,
		name = "SanctuaryCanopy",
	})

	MicroCurveBuilder:fillCircle((origin * CFrame.new(0, 1, 0)).Position, 16, 1.2, {
		voxelStuds = profile.VoxelStuds,
		color = profile.Palette.Gold,
		material = Enum.Material.Neon,
		parent = parent,
		filled = false,
		budget = budget,
	})
end

function WorldBuildShared:getSanctuaryRadius(placeKey: WorldBuildConfig.PlaceKey): number
	if placeKey == "EternityCity" then
		return GameConfig.Sanctuary.EternityCityRadiusStuds
	end
	return GameConfig.Sanctuary.DefaultRadiusStuds
end

function WorldBuildShared:fillTerrainBasin(size: number, depth: number)
	local terrain = workspace.Terrain
	if not terrain then
		return
	end
	terrain:FillBlock(CFrame.new(0, -depth, 0), Vector3.new(size, depth * 2, size), Enum.Material.Grass)
end

return WorldBuildShared
