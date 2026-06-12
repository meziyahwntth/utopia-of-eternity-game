--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlaceTeleport = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlaceTeleport"))
local WorldBuildConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WorldBuildConfig"))

local WorldPlaceGuard = {}

function WorldPlaceGuard:GetCurrentPlaceKey(): WorldBuildConfig.PlaceKey
	local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
	if game.PlaceId == 0 and GameConfig.StudioDev and GameConfig.StudioDev.SimulatePlaceKey then
		return GameConfig.StudioDev.SimulatePlaceKey :: WorldBuildConfig.PlaceKey
	end
	local route: { PlaceTeleport.PlaceKey } =
		{ "Hub", "Solhaven", "Nocturne", "EternityCity", "DeathValley", "NeonUtopia" }
	for _, key in route do
		local id = PlaceTeleport:GetPlaceId(key)
		if id and id > 0 and id == game.PlaceId then
			return key :: WorldBuildConfig.PlaceKey
		end
	end
	return "Hub"
end

function WorldPlaceGuard:ShouldBuild(placeKey: WorldBuildConfig.PlaceKey): boolean
	-- Local rbxlx (PlaceId == 0): match SimulatePlaceKey, not cloud Place IDs from PlaceSecrets.
	if game.PlaceId == 0 then
		return self:GetCurrentPlaceKey() == placeKey
	end
	local id = PlaceTeleport:GetPlaceId(placeKey)
	if id and id > 0 then
		return game.PlaceId == id
	end
	return self:GetCurrentPlaceKey() == placeKey
end

function WorldPlaceGuard:ModelExists(modelName: string): boolean
	return workspace:FindFirstChild(modelName) ~= nil
end

return WorldPlaceGuard
