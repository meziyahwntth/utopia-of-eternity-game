--!strict
--[[
	EternityCity imported terrain helpers — water fill, ground snap, detection.
	Manual heightmap import in Studio; this module never imports PNGs.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local EternityTerrainSetup = {}

local terrainChecked = false
local terrainPresent = false

local function profile()
	return GameConfig.TerrainProfile
end

function EternityTerrainSetup.pixelToStud(pixelX: number, pixelY: number): Vector3
	local tp = profile()
	local x = (pixelX / tp.HeightmapResolution) * tp.MapSize - tp.MapSize / 2
	local z = (pixelY / tp.HeightmapResolution) * tp.MapSize - tp.MapSize / 2
	return Vector3.new(x, tp.PlateauY, z)
end

function EternityTerrainSetup.hasRealTerrain(): boolean
	if terrainChecked then
		return terrainPresent
	end
	terrainChecked = true

	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if not terrain then
		return false
	end

	local tp = profile()
	local center = tp.PlateauCenterStud
	local half = 24
	local region = Region3.new(
		Vector3.new(center.X - half, center.Y - 8, center.Z - half),
		Vector3.new(center.X + half, center.Y + 8, center.Z + half)
	):ExpandToGrid(4)

	local ok, materials = pcall(function()
		return terrain:ReadVoxels(region, 4)
	end)
	if not ok or typeof(materials) ~= "table" then
		return false
	end

	for x = 1, materials.Size.X do
		for y = 1, materials.Size.Y do
			for z = 1, materials.Size.Z do
				if materials[x][y][z] ~= Enum.Material.Air then
					terrainPresent = true
					return true
				end
			end
		end
	end

	return false
end

function EternityTerrainSetup.getGroundY(x: number, z: number, defaultY: number): number
	if not EternityTerrainSetup.hasRealTerrain() then
		return defaultY
	end

	local terrain = workspace.Terrain
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { terrain }

	local origin = Vector3.new(x, 512, z)
	local hit = workspace:Raycast(origin, Vector3.new(0, -1024, 0), params)
	if hit then
		return hit.Position.Y
	end
	return defaultY
end

function EternityTerrainSetup.snapVector3(pos: Vector3): Vector3
	local y = EternityTerrainSetup.getGroundY(pos.X, pos.Z, pos.Y)
	return Vector3.new(pos.X, y, pos.Z)
end

function EternityTerrainSetup.getLandmarkPosition(key: string, greyboxFallback: Vector3): Vector3
	if not EternityTerrainSetup.hasRealTerrain() then
		return greyboxFallback
	end
	local landmarks = profile().Landmarks
	local pos = landmarks[key]
	if pos then
		return EternityTerrainSetup.snapVector3(pos)
	end
	return EternityTerrainSetup.snapVector3(greyboxFallback)
end

function EternityTerrainSetup.fillWater()
	if not EternityTerrainSetup.hasRealTerrain() then
		return
	end

	local terrain = workspace.Terrain
	local tp = profile()
	local inset = tp.MapEdgeInsetStuds
	local half = tp.MapSize / 2 - inset
	local seaY = tp.SeaLevelY

	local region = Region3.new(
		Vector3.new(-half, 0, -half),
		Vector3.new(half, seaY, half)
	):ExpandToGrid(4)

	local ok, err = pcall(function()
		terrain:ReplaceMaterial(region, 4, Enum.Material.Air, Enum.Material.Water)
	end)
	if ok then
		print(string.format("[EternityTerrain] fillWater OK — Y 0..%d, inset %d studs", seaY, inset))
	else
		warn("[EternityTerrain] fillWater failed:", err)
	end
end

function EternityTerrainSetup.prepareForBuild()
	if EternityTerrainSetup.hasRealTerrain() then
		EternityTerrainSetup.fillWater()
		print("[EternityTerrain] Real terrain detected — using plateau layout + getGroundY snap")
	else
		print("[EternityTerrain] No imported terrain — greybox coastline/mountains unchanged")
	end
end

return EternityTerrainSetup
