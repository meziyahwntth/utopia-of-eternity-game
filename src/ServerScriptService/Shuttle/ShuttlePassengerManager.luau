--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))
local PlaceTeleport = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlaceTeleport"))

local ShuttlePassengerManager = {}

export type PlaceKey = PlaceTeleport.PlaceKey

function ShuttlePassengerManager:GetOccupants(seats: { VehicleSeat }): { Player }
	local out: { Player } = {}
	local seen: { [number]: boolean } = {}
	for _, seat in seats do
		local humanoid = seat.Occupant
		if humanoid then
			local player = game:GetService("Players"):GetPlayerFromCharacter(humanoid.Parent)
			if player and not seen[player.UserId] then
				seen[player.UserId] = true
				table.insert(out, player)
			end
		end
	end
	return out
end

function ShuttlePassengerManager:SetSeatsDisabled(seats: { VehicleSeat }, disabled: boolean)
	for _, seat in seats do
		seat.Disabled = disabled
	end
end

function ShuttlePassengerManager:TeleportPartyToPlace(players: { Player }, placeKey: PlaceKey): (boolean, string?)
	local placeId = PlaceTeleport:GetPlaceId(placeKey)
	if not placeId or placeId == 0 then
		return false, "Place ID not configured for " .. placeKey
	end
	if #players == 0 then
		return true, nil
	end
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(placeId, players)
	end)
	if not ok then
		return false, tostring(err)
	end
	return true, nil
end

function ShuttlePassengerManager:GetNextPlace(current: PlaceKey): PlaceKey?
	local route = GameConfig.PublicTransit.Route
	local idx: number? = nil
	for i, key in route do
		if key == current then
			idx = i
			break
		end
	end
	if not idx then
		return route[1]
	end
	local nextIdx = (idx % #route) + 1
	return route[nextIdx] :: PlaceKey
end

function ShuttlePassengerManager:GetCurrentPlaceKey(): PlaceKey
	local route = GameConfig.PublicTransit.Route :: { PlaceKey }
	for _, key in route do
		local id = PlaceTeleport:GetPlaceId(key)
		if id and id > 0 and id == game.PlaceId then
			return key
		end
	end
	return "Hub"
end

return ShuttlePassengerManager
